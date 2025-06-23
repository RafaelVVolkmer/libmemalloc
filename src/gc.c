/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Public include directives and core GC macro definitions
 *
 *  @file       gc.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Implements a background mark-and-sweep garbage collector:
 *              - A dedicated thread periodically scans the allocator’s heap
 *                and memory-mapped regions for live objects by walking the
 *                application stack and root pointers.
 *              - In the “mark” phase, all reachable blocks are flagged.
 *              - In the “sweep” phase, any unflagged blocks are freed or
 *                unmapped, returning memory to the system.
 *              - Configurable sleep interval and performance tuning macros
 *                control collection frequency and optimize hot GC paths.
 *
 *  @version    v3.0.00.00
 *  @date       23.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

/** ============================================================================
 *                      P U B L I C  I N C L U D E S                            
 * ========================================================================== */

/** ============================================================================
 *  @def        _GNU_SOURCE
 *  @brief      Enable GNU extensions on POSIX systems
 *
 *  @details    Defining _GNU_SOURCE before including any headers
 *              activates GNU-specific library features and extensions
 *              in glibc and other GNU-compatible C libraries. This
 *              enables additional APIs beyond the standard C/POSIX
 *              specifications, such as nonstandard functions, constants,
 *              and structures.
 * ========================================================================== */
#define _GNU_SOURCE

/*< Dependencies >*/
#include <errno.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <valgrind/memcheck.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>

/*< Implemented >*/
#include "libmemalloc.h"
#include "logs.h"

/** ============================================================================
 *               P R I V A T E  D E F I N E S  &  M A C R O S                   
 * ========================================================================== */

/** ============================================================================
 *  @def        __GC_HOT
 *  @brief      Marks garbage-collector functions as “hot” (performance critical).
 *
 *  @details    When supported by the compiler (GCC/Clang), expands to
 *              __attribute__((hot)), informing the optimizer that the
 *              annotated function is on a performance-critical path and
 *              should be optimized accordingly. Otherwise, expands to nothing.
 * ========================================================================== */
#if defined(__GNUC__)
  #define __GC_HOT \
    __attribute__((hot))
#else
  #define __GC_HOT
#endif

/** ============================================================================
 *  @def        __GC_COLD
 *  @brief      Marks garbage-collector functions as “cold” (infrequently used).
 *
 *  @details    When supported by the compiler (GCC/Clang), expands to
 *              __attribute__((cold)), informing the optimizer that the
 *              annotated function is unlikely to execute frequently and
 *              may be placed out-of-line to reduce code size in hot paths.
 *              Otherwise, expands to nothing.
 * ========================================================================== */
#if defined(__GNUC__)
  #define __GC_COLD \
    __attribute__((cold))
#else
  #define __GC_COLD
#endif

/** ============================================================================
 *  @def        NR_OBJS
 *  @brief      Number of iterations used to scale GC sleep duration
 *
 *  @details    Specifies the multiplier applied to the base GC interval
 *              (in milliseconds) to compute the actual sleep time between
 *              successive garbage-collection cycles:
 *                  sleep_time = gc_interval_ms * NR_OBJS
 * ========================================================================== */
#define NR_OBJS     (uint16_t)(1000U)

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S               
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_gcThreadFunc
 *  @brief      Thread function that runs the mark-and-sweep garbage collector
 *
 *  @param[in]  arg     Pointer to mem_allocator_t context (must not be NULL)
 *
 *  @return     PTR_ERR code on failure, or NULL on success
 * ========================================================================== */
__GC_HOT static void *MEM_gcThreadFunc(void *arg);

/** ============================================================================
 *  @fn         MEM_gcMark
 *  @brief      Mark all allocated blocks that are still reachable on the heap
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_HOT static int MEM_gcMark(mem_allocator_t *allocator);

/** ============================================================================
 *  @fn         MEM_gcSweep
 *  @brief      Sweep the heap, free unmarked blocks, and unmap memory-mapped
 *              regions
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_HOT static int MEM_gcSweep(mem_allocator_t *allocator);

/** ============================================================================
 *  @fn         MEM_runGc
 *  @brief      Initialize or signal the garbage collector thread to run
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_COLD int MEM_runGc(mem_allocator_t *allocator);

/** ============================================================================
 *  @fn         MEM_stopGc
 *  @brief      Stop the garbage collector thread and perform a final collection
 *              cycle
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_COLD int MEM_stopGc(mem_allocator_t *allocator);

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S                    
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_gcThreadFunc
 *  @brief      Thread function that runs the mark-and-sweep garbage collector
 *
 *  @param[in]  arg     Pointer to mem_allocator_t context (must not be NULL)
 *
 *  @return     PTR_ERR code on failure, or NULL on success
 * ========================================================================== */
static void *MEM_gcThreadFunc(void *arg)
{
    void *ret = NULL;

    mem_allocator_t *allocator = NULL;

    if (arg == NULL)
    {
        ret = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid argument: ARG=%p", (void*)arg);
        goto function_output;
    }

    allocator = (mem_allocator_t *)arg;

    pthread_mutex_lock(&allocator->gc_lock);

    for (;;) 
    {
        while (!atomic_load(&allocator->gc_running))
            pthread_cond_wait(&allocator->gc_cond, &allocator->gc_lock);

        pthread_mutex_unlock(&allocator->gc_lock);

        ret = PTR_ERR(MEM_gcMark(allocator));
        if (ret != PTR_ERR(EXIT_SUCCESS))
        {
            LOG_ERROR("MEM_gcMark failed, ret=%p", ret);
            goto function_output;
        }

        ret = PTR_ERR(MEM_gcSweep(allocator));
        if (ret != PTR_ERR(EXIT_SUCCESS))
        {
            LOG_ERROR("MEM_gcSweep failed, ret=%p", ret);
            goto function_output;
        }

        usleep(allocator->gc_interval_ms * NR_OBJS);

        pthread_mutex_lock(&allocator->gc_lock);
    }

    pthread_mutex_unlock(&allocator->gc_lock);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_gcMark
 *  @brief      Mark all allocated blocks that are still reachable on the heap
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
static int MEM_gcMark(mem_allocator_t *allocator)
{
    int ret = EXIT_SUCCESS;

    block_header_t *block = NULL;
    mmap_t *map = NULL;

    uintptr_t *stack_bottom = NULL;
    uintptr_t *stack_top = NULL;

    uintptr_t *ptr = NULL;
    void *ptr_aux = NULL;

    uint8_t *base_addr = NULL;
    uint8_t *data_start = NULL;
    uint8_t *data_end = NULL;

    if (allocator == NULL)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid argument: allocator=%p", (void*)allocator);
        goto function_output;
    }

    block = (block_header_t *)allocator->heap_start;

    while ((uint8_t *)block < allocator->heap_end)
    {
        block->marked = 0u;
        block = (block_header_t *)((uint8_t *)block + block->size);
    }

    stack_bottom  = allocator->stack_bottom;
    stack_top = allocator->stack_top;

#ifdef RUNNING_ON_VALGRIND
    VALGRIND_MAKE_MEM_DEFINED(
        (void*)stack_bottom,
        (size_t)((char*)stack_top - (char*)stack_bottom)
    );
#endif

    if (stack_bottom > stack_top) 
        stack_bottom = stack_top;

    for (ptr = stack_bottom; ptr < stack_top; ++ptr) 
    {
        ptr_aux = (void *)*ptr;

        if ((uint8_t *)ptr_aux >= allocator->heap_start &&
            (uint8_t *)ptr_aux < allocator->heap_end)
        {

            block = (block_header_t *)allocator->heap_start;
            while ((uint8_t *)block < allocator->heap_end) 
            {
                data_start = (uint8_t *)block + sizeof(block_header_t);
                data_end = (uint8_t *)block + block->size - sizeof(uint32_t);

                if (!block->free &&
                    (uint8_t *)ptr_aux >= data_start &&
                    (uint8_t *)ptr_aux < data_end)
                {
                    block->marked = 10U;
                    break;
                }

                block = (block_header_t *)((uint8_t *)block + block->size);
            }
        }

        for (map = allocator->mmap_list; map; map = map->next)
        {
            block = (block_header_t*)map->addr;
            base_addr = (uint8_t*)map->addr;
            data_start = base_addr + sizeof(block_header_t);
            data_end = base_addr + map->size - sizeof(uint32_t);

            if (!block->free &&
                ptr_aux >= (void*)data_start &&
                ptr_aux < (void*)data_end)
            {
                block->marked = 1u;
                break;
            }
        }
    }

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_gcSweep
 *  @brief      Sweep the heap, free unmarked blocks, and unmap memory-mapped
 *              regions
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
static int MEM_gcSweep(mem_allocator_t *allocator)
{
    int ret = EXIT_SUCCESS;

    block_header_t *block = NULL;

    mmap_t **map_ref = NULL;
    mmap_t *map = NULL;
    mmap_t *next = NULL;
    mmap_t *to_free = NULL;

    uint8_t *scan = NULL;
    uint8_t *next_scan = NULL;

    uint8_t *heap_end = NULL;
    void *user_ptr = NULL;
    
    size_t payload = 0u;

    if (allocator == NULL)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid argument: allocator=%p", (void*)allocator);
        goto function_output;
    }

    heap_end = allocator->heap_end;
    scan = allocator->heap_start;

    while (scan < heap_end)
    {
        block = (block_header_t*)scan;
        payload = block->size;
        user_ptr = (void *)(scan + sizeof(block_header_t));
        next_scan = (uint8_t *)(scan + sizeof(block_header_t) + payload);

        if (!block->free && block->marked == 0)
            MEM_allocFree(allocator, user_ptr, "gc");
        else
            block->marked = 0;

        scan = next_scan;
    }

    map_ref = &allocator->mmap_list;
    while (*map_ref)
    {
        map = *map_ref;
        next = map->next;
        block = (block_header_t*)map->addr;

        if (!block->marked)
        {
            ret = munmap(map->addr, map->size);
            if (ret < EXIT_SUCCESS)
            {
                LOG_ERROR("munmap failed: addr=%p, size=%zu",
                            map->addr, map->size);
                goto function_output;
            }

            *map_ref = next;

            map->next = to_free;
            to_free = map;
        }
        else
        {
            block->marked = 0u;
            map_ref = &map->next;
        }
    }

    for (map = to_free; map; )
    {
        next = map->next;
        MEM_allocFree(allocator, map, "mmap_meta");
        map = next;
    }

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_runGc
 *  @brief      Initialize or signal the garbage collector thread to run
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
int MEM_runGc(mem_allocator_t *allocator)
{
    int ret = EXIT_SUCCESS;

    if (allocator == NULL)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid argument: allocator=%p", (void*)allocator);
        goto function_output;
    }

    allocator->stack_bottom = (uintptr_t*)__builtin_frame_address(0);
    if (!allocator->gc_thread_started)
    {
        pthread_mutex_init(&allocator->gc_lock, NULL);
        pthread_cond_init(&allocator->gc_cond, NULL);

        allocator->gc_thread_started = 1u;

        atomic_store(&allocator->gc_running, true);

        ret = pthread_create(&allocator->gc_thread, NULL, MEM_gcThreadFunc,
                                allocator);
        if (ret != EXIT_SUCCESS)
        {
            LOG_ERROR("pthread_create failed, ret=%d", ret);
            goto function_output;
        }
    }
    else
    {
        atomic_store(&allocator->gc_running, true);
        pthread_cond_signal(&allocator->gc_cond);
    }

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_stopGc
 *  @brief      Stop the garbage collector thread and perform a final collection
 *              cycle
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
int MEM_stopGc(mem_allocator_t *allocator)
{
    int ret = EXIT_SUCCESS;

    if (allocator == NULL)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid argument: allocator=%p", (void*)allocator);
        goto function_output;
    }

    atomic_store(&allocator->gc_running, false);

    if (allocator->gc_thread_started)
    {
        pthread_cond_signal(&allocator->gc_cond);
        pthread_cancel(allocator->gc_thread);
        pthread_join(allocator->gc_thread, NULL);
    
        ret = MEM_gcMark(allocator);
        if (ret != EXIT_SUCCESS)
        {
            LOG_ERROR("MEM_gcMark failed, ret=%d", ret);
            goto function_output;
        }

        ret = MEM_gcSweep(allocator);
        if (ret != EXIT_SUCCESS)
        {
            LOG_ERROR("MEM_gcSweep failed, ret=%d", ret);
            goto function_output;
        }

        pthread_mutex_destroy(&allocator->gc_lock);
        pthread_cond_destroy (&allocator->gc_cond);

        allocator->gc_thread_started = 0u;
    }

function_output:
    return ret;
}

/** ============================================================================
 *              P U B L I C  F U N C T I O N  C A L L S  A P I                  
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_enableGc
 *  @brief      Wrapper to start or signal the garbage collector thread
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 *
 *  @note       This is simply a thin wrapper around MEM_runGc().
 * ========================================================================== */
int MEM_enableGc(mem_allocator_t *allocator)
{
    return MEM_runGc(allocator);
}

/** ============================================================================
 *  @fn         MEM_disableGc
 *  @brief      Wrapper to stop the garbage collector thread and perform a final
 *              collection
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 *
 *  @note       This is simply a thin wrapper around MEM_stopGc().
 * ========================================================================== */
int MEM_disableGc(mem_allocator_t *allocator)
{
    return MEM_stopGc(allocator);
}
 
/*< end of file >*/
