/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Core memory management components for libmemalloc.
 *
 *  @file       libmemalloc.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Implements memory allocator with advanced features:
 *              - Architecture-specific stack allocation (alloca)
 *              - Garbage collection (mark & sweep)
 *              - Block validation with magic numbers/canaries
 *              - Multiple allocation strategies (First/Best/Next Fit)
 *
 *  @version    v3.0.00.00
 *  @date       16.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

/** ============================================================================
 *                      P R I V A T E  I N C L U D E S                          
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
#include <inttypes.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <unistd.h>
#include <valgrind/memcheck.h>
#include <sys/resource.h>
#include <stdbool.h>

/*< Implemented >*/
#include "libmemalloc.h"
#include "logs.h"

/** ============================================================================
 *               P R I V A T E  D E F I N E S  &  M A C R O S                   
 * ========================================================================== */

/** ============================================================================
 *  @def        DEFAULT_NUM_BINS
 *  @brief      Default number of size classes (bins) for free lists.
 *
 *  @details    Defines how many size categories (bins) the allocator will
 *              maintain for managing free memory blocks. This value affects
 *              allocation speed and fragmentation behavior.
 * ========================================================================== */
#define DEFAULT_NUM_BINS (uint8_t)(10U)

/** ============================================================================
 *  @def        MAGIC_NUMBER
 *  @brief      Magic number to validate memory blocks.
 *
 *  @details    This constant is used to verify the integrity of
 *              allocated memory blocks and detect corruption.
 * ========================================================================== */
#define MAGIC_NUMBER    (uint32_t)(0xBEEFDEADU)

/** ============================================================================
 *  @def        CANARY_VALUE
 *  @brief      Canary value to detect buffer overflows.
 *
 *  @details    This constant is placed at the boundaries of
 *              memory allocations to detect buffer overflows.
 * ========================================================================== */
#define CANARY_VALUE    (uint32_t)(0xDEADBEEFULL)

/** ============================================================================
 *  @def        PREFETCH_MULT
 *  @brief      Prefetch optimization multiplier constant
 *
 *  @details    64-bit repeating byte pattern (0x01 per byte) used
 *              for efficient  memory block operations. Enables
 *              single-byte value replication across full register
 *              width in vectorized operations.
 * ========================================================================== */
#define PREFETCH_MULT   (uint64_t)(0x0101010101010101ULL)

/** ============================================================================
 *  @def        BYTES_PER_CLASS
 *  @brief      Fixed byte allocation per classification unit
 *
 *  @details    Defines the number of bytes assigned to each
 *              classification category. Ensures memory alignment
 *              and efficient block processing in data structures.
 * ========================================================================== */
#define BYTES_PER_CLASS (uint8_t)(128U)

/** ============================================================================
 *  @def        MMAP_THRESHOLD
 *  @brief      Threshold size for using mmap-based allocation
 *
 *  @details    When a requested allocation size meets or exceeds this value
 *              (128 KiB), the allocator will switch from using the heap
 *              (brk/sbrk) to using mmap for more efficient large-block
 *              handling and to reduce heap fragmentation.
 * ========================================================================== */
#define MMAP_THRESHOLD  (size_t)(128U * 1024U)

/** ============================================================================
 *  @def        DEFAULT_GC_INTERVAL_MS
 *  @brief      Default interval in milliseconds between GC cycles.
 *
 *  @details    Defines the time (in milliseconds) the garbage collector
 *              thread sleeps between each mark-and-sweep cycle. Adjusting
 *              this value impacts how frequently memory is reclaimed versus
 *              the CPU overhead of running the GC.
 * ========================================================================== */
#define GC_INTERVAL_MS  (uint16_t)(1000U)

/** ============================================================================
 *  @def        MIN_BLOCK_SIZE
 *  @brief      Defines the minimum memory block size.
 *
 *  @details    Ensures each memory block is large enough to hold
 *              a block header and alignment padding.
 * ========================================================================== */
#define MIN_BLOCK_SIZE  (size_t)(sizeof(block_header_t) + ARCH_ALIGNMENT)

/** ============================================================================
 *  @def        LIKELY(x)
 *  @brief      Compiler hint for likely branch prediction.
 *
 *  @param [in] x   Condition that is likely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be true.
 * ========================================================================== */
#define LIKELY(x)       (__builtin_expect(!!(x), 1))

/** ============================================================================
 *  @def        UNLIKELY(x)
 *  @brief      Compiler hint for unlikely branch prediction.
 *
 *  @param [in] x   Condition that is unlikely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be false.
 * ========================================================================== */
#define UNLIKELY(x)     (__builtin_expect(!!(x), 0))

/** ============================================================================
 *              P R I V A T E  T Y P E S  D E F I N I T I O N                   
 * ========================================================================== */

/** ============================================================================
 *  @typedef    find_fn_t
 *  @brief      Type for functions that locate a suitable free block.
 *
 *  @param [in]  allocator   Memory allocator context in which to search.
 *  @param [in]  size        Total size requested (including header and canary).
 *  @param [out] block       Address of pointer to store the found block header.
 *
 *  @return     EXIT_SUCCESS if a suitable block was found; negative errno code.
 * ========================================================================== */
typedef int (*find_fn_t)(mem_allocator_t *const, size_t, block_header_t **);

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S               
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_sbrk
 *  @brief      Invokes sbrk-like behavior by calling MEM_brk()
 *              to move the program break by a signed offset
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  increment   Signed offset in bytes to move the break
 *
 *  @return     On success, returns the previous program break address.
 *              On failure, returns (void*)(-errno).
 *
 *  @retval     != (void*)-1    Previous break on success
 *  @retval     (void*)-EINVAL  Invalid parameters
 *  @retval     (void*)-ENOMEM  Unable to grow/shrink heap
 * ========================================================================== */
void *MEM_sbrk(const intptr_t increment);

/** ============================================================================
 *  @fn         MEM_validateBlock
 *  @brief      Validates the integrity and boundaries of a
 *              memory block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to validate
 *
 *  @return     Integer status code indicating validation result
 *
 *  @retval     EXIT_SUCCESS:       Block is valid
 *  @retval     -EINVAL:            Invalid NULL parameters
 *  @retval     -EFAULT:            Block outside heap boundaries
 *  @retval     -ENOTRECOVERABLE:   Invalid magic number
 *  @retval     -EPROTO:            Corrupted header canary
 *  @retval     -EOVERFLOW:         Data canary corruption
 *  @retval     -EFBIG:             Block size exceeds heap end
 * ========================================================================== */
static int MEM_validateBlock(mem_allocator_t *const allocator,
                                block_header_t *const block);

/** ============================================================================
 *  @fn         MEM_getSizeClass
 *  @brief      Calculates the size class index for a requested
 *              memory size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested memory size in bytes
 *
 *  @return     Integer representing size class index on success,
 *              negative error code on failure
 *
 *  @retval     ret >= 0:   Valid size class index
 *  @retval     -EINVAL:    Invalid arguments
 * ========================================================================== */
static inline int MEM_getSizeClass(mem_allocator_t *const allocator,
                                    const size_t size);

/** ============================================================================
 *  @fn         MEM_insertFreeBlock
 *  @brief      Inserts a block into the appropriate free list
 *              based on its size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to insert into the free list
 *
 *  @return     Integer status code indicating operation result
 *
 *  @retval     EXIT_SUCCESS:   Block successfully inserted
 *  @retval     -EINVAL:        Invalid arguments or size class
 * ========================================================================== */
static inline int MEM_insertFreeBlock(mem_allocator_t *const allocator,
                                        block_header_t *const block);

/** ============================================================================
 *  @fn         MEM_removeFreeBlock
 *  @brief      Removes a block from its free list
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to remove
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Block removed successfully
 *  @retval     -EINVAL:        Invalid arguments or size class
 * ========================================================================== */
static inline int MEM_removeFreeBlock(mem_allocator_t *const allocator,
                                        block_header_t *const block);

/** ============================================================================
 *  @fn         MEM_findFirstFit
 *  @brief      Searches for the first suitable free memory
 *              block in size-class free lists
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] fit_block   Pointer to store found suitable
 *                          block address
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:        No suitable block found in free lists
 * ========================================================================== */
static int MEM_findFirstFit(mem_allocator_t *const allocator, const size_t size,
                            block_header_t **fit_block);

/** ============================================================================
 *  @fn         MEM_findNextFit
 *  @brief      Searches for next suitable free memory block using
 *              NEXT_FIT strategy from last allocated position
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] fit_block   Pointer to store found suitable block address
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters
 *  @retval     -ENOMEM:        No suitable block found in heap
 * ========================================================================== */
static int MEM_findNextFit(mem_allocator_t *const allocator, const size_t size,
                            block_header_t **fit_block);

/** ============================================================================
 *  @fn         MEM_findBestFit
 *  @brief      Searches for smallest suitable free block
 *              in size-class free lists (BEST_FIT)
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] best_fit    Pointer to store found optimal block address
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:        No suitable block found in free lists
 * ========================================================================== */
static int MEM_findBestFit(mem_allocator_t *const allocator, const size_t size,
                            block_header_t **best_fit);

/** ============================================================================
 *  @fn         MEM_mergeBlocks
 *  @brief      Merges adjacent free memory blocks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to merge with neighbors
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Blocks merged successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted blocks
 *
 *  @note       Merges with both previous and next blocks if possible
 * ========================================================================== */
static int MEM_mergeBlocks(mem_allocator_t *const allocator,
                            block_header_t *block);

/** ============================================================================
 *  @fn         MEM_splitBlock
 *  @brief      Splits a memory block into allocated and free portions
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to split
 *  @param[in]  req_size    Requested allocation size
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Block split successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted block
 *
 *  @note       If remaining space < MIN_BLOCK_SIZE, uses entire block
 * ========================================================================== */
static int MEM_splitBlock(mem_allocator_t *const allocator,
                            block_header_t *const block,
                            const size_t req_size);

/** ============================================================================
 *  @fn         MEM_growUserHeap
 *  @brief      Expands the user heap by a specified increment.
 *
 *  @param[in]  alloc   Memory allocator context.
 *  @param[in]  inc     Heap size increment (in bytes).
 *
 *  @return     Previous end address of the heap, or error code.
 *
 *  @retval     Valid address: Heap successfully expanded.
 *  @retval     (void*)(-EINVAL): Invalid allocator context.
 *  @retval     (void*)(-ENOMEM): Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *alloc, const intptr_t inc);

/** ============================================================================
 *  @fn         MEM_mapAlloc
 *  @brief      Allocates a page‐aligned memory region via mmap and registers it
 *              in the allocator’s mmap list for later freeing.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *                          Must not be NULL.
 *  @param[in]  total_size  Number of bytes requested (will be rounded up to a
 *                          multiple of the system page size).
 *
 *  @return     On success, returns the address of the mapped region.
 *
 *  @retval     (void*)(intptr_t)(-EINVAL)
 *                          allocator is NULL.
 *  @retval     (void*)(intptr_t)(-EIO)
 *                          mmap() failed.
 *  @retval     (void*)(intptr_t)(-ENOMEM)
 *                          Allocation of metadata node failed.
 * ========================================================================== */
static int *MEM_mapAlloc(mem_allocator_t *allocator, size_t total_size);

/** ============================================================================
 *  @fn         MEM_mapFree
 *  @brief      Unmaps a previously mapped memory region and removes its metadata
 *              entry from the allocator’s mmap list.
 *
 *  @param[in]  allocator   Memory allocator context. Must not be NULL.
 *  @param[in]  addr        Address of the memory region to unmap.
 *
 *  @return     Integer status code.
 *
 *  @retval     EXIT_SUCCESS
 *                          Region was successfully unmapped and its metadata
 *                          entry freed. (If freeing metadata fails, an error
 *                          is logged but success is still returned.)
 *  @retval     -EINVAL
 *                          allocator is NULL, or addr was not found in the
 *                          allocator’s mmap list.
 *  @retval     -ENOMEM
 *                          munmap() failed to unmap the region.
 * ========================================================================== */
static int MEM_mapFree(mem_allocator_t *allocator, void *addr);

/** ============================================================================
 *  @fn         MEM_allocatorMalloc
 *  @brief      Allocates memory using specified strategy
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorMalloc(
    mem_allocator_t *const allocator,
    const size_t size,
    const char *const file,
    const int line,
    const char *const var_name,
    const allocation_strategy_t strategy) __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @fn         MEM_allocatorCalloc
 *  @brief      Allocates and zero-initializes memory
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  num         Number of elements
 *  @param[in]  size        Element size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorCalloc(
    mem_allocator_t *const allocator,
    const size_t num,
    const size_t size,
    const char *const file,
    const int line,
    const char *const var_name,
    const allocation_strategy_t strategy) __LIBMEMALLOC_CALLOC;

/** ============================================================================
 *  @fn         MEM_allocatorRealloc
 *  @brief      Reallocates memory with safety checks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to reallocate
 *  @param[in]  new_size    New allocation size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to reallocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorRealloc(
    mem_allocator_t *const allocator,
    void *const ptr,
    const size_t new_size,
    const char *const file,
    const int line,
    const char *const var_name,
    const allocation_strategy_t strategy) __LIBMEMALLOC_REALLOC;

/** ============================================================================
 *  @fn         MEM_allocatorFree
 *  @brief      Releases allocated memory back to the heap
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to memory to free
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Memory freed successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted block
 * ========================================================================== */
static int MEM_allocatorFree(mem_allocator_t *const allocator,
                                void *const ptr,
                                const char *const file,
                                const int line,
                                const char *const var_name);

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S                    
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_memset
 *  @brief      Fills a memory block with a specified byte value
 *              using optimized operations
 *
 *  @param[in]  source  Pointer to the memory block to fill
 *  @param[in]  value   Byte value to set
 *  @param[in]  size    Number of bytes to set
 *
 *  @return     Original source pointer on success
 *              error code cast to void* on failure
 *
 *  @retval     source:     (input pointer) on successful operation
 *  @retval     -EINVAL:    (cast to void*) invalid parameters
 * ========================================================================== */
void *MEM_memset(void *const source, const int value, const size_t size)
{
    void *ret = NULL;

    unsigned char *ptr = NULL;
    unsigned char *ptr_aux = NULL;

    size_t iterator = 0u;

    if (UNLIKELY((source == NULL) || (size <= 0)))
    {
        ret = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid memset arguments: source=%p, size=%zu. "
                  "Error code: %d.",
                  source, size, (int)(intptr_t)ret);
        goto function_output;
    }

    ptr = (unsigned char *)source;

    if ((uintptr_t)ptr % ARCH_ALIGNMENT != 0)
    {
        while ((iterator < size) &&
                ((uintptr_t)(ptr + iterator) % ARCH_ALIGNMENT != 0))
        {
            ptr[iterator] = (unsigned char)value;
            iterator++;
        }
    }

    for ( ;
        (size_t)(iterator + ARCH_ALIGNMENT) <= size;
        iterator += (size_t)ARCH_ALIGNMENT)
    {
        *(uint64_t *)(ptr + iterator)
            = ((uint64_t)(unsigned char)value) * PREFETCH_MULT;
        __builtin_prefetch(((ptr + iterator) + 64u), 1u, 1u);
    }

    ptr_aux = (unsigned char *)(ptr + iterator);
    while (iterator < size)
    {
        *ptr_aux++ = (unsigned char)value;
        iterator++;
    }

    ret = source;
    LOG_INFO("Memory set: source=%p, value=0x%X, size=%zu.",
                source, (unsigned int)value, size);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_memcpy
 *  @brief      Copies memory block between buffers using
 *              optimized operations
 *
 *  @param[in]  dest    Destination buffer
 *  @param[in]  src     Source buffer
 *  @param[in]  size    Number of bytes to copy
 *
 *  @return     Original dest pointer on success,
 *              error code cast to void* on failure
 *
 *  @retval     dest:       (input pointer) on successful operation
 *  @retval     -EINVAL:    (cast to void*) invalid parameters
 * ========================================================================== */
void *MEM_memcpy(void *const dest, const void *src, const size_t size)
{
    void *ret = NULL;

    unsigned char *destine = NULL;
    unsigned char *destine_aux = NULL;

    const unsigned char *source = NULL;

    size_t iterator = 0u;

    if (UNLIKELY((dest == NULL) || (src == NULL) || (size <= 0)))
    {
        ret = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid memcpy arguments: dest=%p, src=%p, size=%zu. "
                  "Error code: %d.",
                  dest, src, size, (int)(intptr_t)ret);
        goto function_output;
    }

    destine = (unsigned char *)dest;
    source = (const unsigned char *)src;

    if ((uintptr_t)destine % ARCH_ALIGNMENT != 0)
    {
        while ((iterator < size) &&
                ((uintptr_t)(destine + iterator) % ARCH_ALIGNMENT != 0)) 
        {
            destine[iterator] = source[iterator];
            iterator++;
        }
    }

    for ( ;
        (size_t)(iterator + ARCH_ALIGNMENT) <= size;
        iterator += (size_t)ARCH_ALIGNMENT)
    {
        *(uint64_t *)(destine + iterator)
            = *(const uint64_t *)(source + iterator);
        __builtin_prefetch((source + iterator) + 64u, 0u, 1u);
        __builtin_prefetch((destine + iterator) + 64u, 1u, 1u);
    }

    destine_aux = (unsigned char *)(destine + iterator);
    while (iterator < size)
    {
        *destine_aux++ = source[iterator];
        iterator++;
    }

    ret = dest;
    LOG_INFO("Memory copied: dest=%p, src=%p, size=%zu.", dest, src, size);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_sbrk
 *  @brief      Invokes sbrk-like behavior by calling MEM_brk()
 *              to move the program break by a signed offset
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  increment   Signed offset in bytes to move the break
 *
 *  @return     On success, returns the previous program break address.
 *              On failure, returns (void*)(-errno).
 *
 *  @retval     != (void*)-1    Previous break on success
 *  @retval     (void*)-EINVAL  Invalid parameters
 *  @retval     (void*)-ENOMEM  Unable to grow/shrink heap
 * ========================================================================== */
void *MEM_sbrk(const intptr_t increment)
{
    void *old_break = NULL;
    void *new_break = NULL;

    old_break = sbrk(0);
    if (old_break == (void *)-1) 
    {
        LOG_ERROR("Failed to read current break");
        old_break = PTR_ERR(-ENOMEM);
        goto function_output;
    }

    if (sbrk(increment) == (void *)-1) 
    {
        LOG_ERROR("Failed to adjust break (increment=%" PRIdPTR "",
                  increment);
        old_break = PTR_ERR(-ENOMEM);
        goto function_output;
    }

    new_break = sbrk(0);
    if (new_break == (void *)-1)
    {
        LOG_ERROR("Failed to read new break");
        old_break = PTR_ERR(-ENOMEM);
        goto function_output;
    }

    LOG_INFO("Program break moved from %p to %p (increment: %" PRIdPTR ")",
             old_break, new_break, increment);

function_output:
    return old_break;
}

/** ============================================================================
 *  @fn         MEM_validateBlock
 *  @brief      Validates the integrity and boundaries of a
 *              memory block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to validate
 *
 *  @return     Integer status code indicating validation result
 *
 *  @retval     EXIT_SUCCESS:       Block is valid
 *  @retval     -EINVAL:            Invalid NULL parameters
 *  @retval     -EFAULT:            Block outside heap boundaries
 *  @retval     -ENOTRECOVERABLE:   Invalid magic number
 *  @retval     -EPROTO:            Corrupted header canary
 *  @retval     -EOVERFLOW:         Data canary corruption
 *  @retval     -EFBIG:             Block size exceeds heap end
 * ========================================================================== */
static int MEM_validateBlock(mem_allocator_t *const allocator,
                                block_header_t *const block)
{
    int ret = EXIT_SUCCESS;

    uint32_t *data_canary = NULL;

    if (UNLIKELY((allocator == NULL) || (block == NULL)))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid NULL parameter. Allocator: %p, Block: %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    if (((uint8_t *)block < allocator->heap_start) || 
        ((uint8_t *)block >= allocator->heap_end))
    {
        ret = -EFAULT;
        LOG_ERROR("Block %p outside heap boundaries [%p - %p]. "
                  "Error code: %d.\n",
                  (void *)block, (void *)allocator->heap_start,
                  (void *)allocator->heap_end, ret);
        goto function_output;
    }

    if (block->magic != MAGIC_NUMBER)
    {
        ret = -ENOTRECOVERABLE;
        LOG_ERROR("Invalid magic at %p: 0x%X (expected 0x%X). "
                  "Error code: %d.\n",
                  (void *)block, block->magic, MAGIC_NUMBER, ret);
        goto function_output;
    }

    if (block->canary != CANARY_VALUE)
    {
        ret = -EPROTO;
        LOG_ERROR("Corrupted header at %p: 0x%X vs 0x%X. "
                  "Error code: %d.\n",
                  (void *)block, block->canary, CANARY_VALUE, ret);
        goto function_output;
    }

    data_canary = (uint32_t *)((uint8_t *)block + block->size -
                                            sizeof(uint32_t));
    if (*data_canary != CANARY_VALUE)
    {
        ret = -EOVERFLOW;
        LOG_ERROR("Data overflow detected at %p (canary: 0x%X). "
                  "Error code: %d.\n", (void *)block, *data_canary, ret);
        goto function_output;
    }

    if (((uint8_t *)block + block->size) > allocator->heap_end)
    {
        ret = -EFBIG;
        LOG_ERROR("Structural overflow at %p (size: %zu). Heap range [%p - %p]."
                  "Error code: %d.\n",
                  (void *)block, block->size, (void *)allocator->heap_start,
                  (void *)allocator->heap_end, ret);
        goto function_output;
    }

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_getSizeClass
 *  @brief      Calculates the size class index for a requested
 *              memory size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested memory size in bytes
 *
 *  @return     Integer representing size class index on success,
 *              negative error code on failure
 *
 *  @retval     ret >= 0:   Valid size class index
 *  @retval     -EINVAL:    Invalid arguments
 * ========================================================================== */
static inline int MEM_getSizeClass(mem_allocator_t *const allocator,
                                    const size_t size)
{
    int ret = EXIT_SUCCESS;

    size_t index = 0u;
    size_t max_class_size = 0u;

    if (UNLIKELY(allocator == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid allocator - NULL pointer "
                  "Error code: %d.\n", ret);
        goto function_output;
    }

    if (UNLIKELY(size <= 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid size requested "
                  "Error code: %d.\n", ret);
        goto function_output;
    }

    max_class_size = (allocator->num_size_classes - 1u) * BYTES_PER_CLASS;
    index = (size + BYTES_PER_CLASS - 1u) / BYTES_PER_CLASS;

    if (UNLIKELY(index >= allocator->num_size_classes))
    {
        LOG_WARNING("Size overflow - "
                    "Requested: %zu bytes | Max class: %zu bytes |"
                    "Clamped to class %zu",
                    size, max_class_size, (allocator->num_size_classes - 1u));
        index = (size_t)(allocator->num_size_classes - 1);
    }
    else
    {
        LOG_INFO("Size class calculated - "
                 "Requested: %zu bytes | Class: %zu (%zu-%zu bytes)",
                 size, index, index * BYTES_PER_CLASS,
                 ((index + 1u) * BYTES_PER_CLASS - 1u));
    }

    ret = (int)index;

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_insertFreeBlock
 *  @brief      Inserts a block into the appropriate free list
 *              based on its size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to insert into the free list
 *
 *  @return     Integer status code indicating operation result
 *
 *  @retval     EXIT_SUCCESS:   Block successfully inserted
 *  @retval     -EINVAL:        Invalid arguments or size class
 * ========================================================================== */
static inline int MEM_insertFreeBlock(mem_allocator_t *const allocator,
                                        block_header_t *const block)
{
    int ret = EXIT_SUCCESS;

    int index = 0u;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters - Allocator: %p, Block: %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    index = MEM_getSizeClass(allocator, block->size);
    if (UNLIKELY(index < 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid size class index: %d for block size %zu. "
                  "Error code: %d.\n", index, block->size, ret);
        goto function_output;
    }

    block->fl_next = allocator->free_lists[index];

    block->fl_prev = NULL;
    if (allocator->free_lists[index])
        allocator->free_lists[index]->fl_prev = block;

    allocator->free_lists[index] = block;
    LOG_INFO("Block %p inserted into free list %d (size: %zu)\n",
            (void *)block, index, block->size);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_removeFreeBlock
 *  @brief      Removes a block from its free list
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to remove
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Block removed successfully
 *  @retval     -EINVAL:        Invalid arguments or size class
 * ========================================================================== */
static inline int MEM_removeFreeBlock(mem_allocator_t *const allocator,
                                        block_header_t *const block)
{
    int ret = EXIT_SUCCESS;

    int index = 0u;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters - Allocator: %p, Block: %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    index = MEM_getSizeClass(allocator, block->size);
    if (UNLIKELY(index < 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid size class index: %d for block size %zu. "
                  "Error code: %d.\n", index, block->size, ret);
        goto function_output;
    }

    if (block->fl_prev)
        block->fl_prev->fl_next = block->fl_next;
    else
        allocator->free_lists[index] = block->fl_next;

    if (block->fl_next)
        block->fl_next->fl_prev = block->fl_prev;

    block->fl_next = NULL;
    block->fl_prev = NULL;

    LOG_INFO("Block %p removed from free list %d (size: %zu)\n",
                (void *)block, index, block->size);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_allocatorInit
 *  @brief      Initializes the memory allocator and its
 *              internal structures
 *
 *  @param[in]  allocator   Pointer to the allocator
 *
 *  @return     Integer status code
 *
 *  @retval     -EINVAL:    Invalid allocator pointer provided
 *  @retval     -EINVAL:    Invalid allocator pointer provided
 * ========================================================================== */
int MEM_allocatorInit(mem_allocator_t *const allocator)
{
    int ret = EXIT_SUCCESS;

    static bool mempool_created = false;
    pthread_attr_t attr;

    mem_arena_t *arena = NULL;

    void *base = NULL;
    void *old = NULL;
    void *stack_addr = NULL;

    uintptr_t addr = 0;

    size_t pad = 0u;
    size_t bins_bytes = 0u;
    size_t stack_size = 0u;

    base = MEM_sbrk(0);
    if (base == (void*)(-ENOMEM))
    {
        LOG_ERROR("Failed: unable to get heap base address (ENOMEM).");
        ret = -ENOMEM;
        goto function_output;
    }

    addr = (uintptr_t)base;
    pad = (size_t)((ARCH_ALIGNMENT - (addr % ARCH_ALIGNMENT)) % ARCH_ALIGNMENT);

    if (pad)
    {
        old = MEM_sbrk((intptr_t)pad);
        if (old == (void*)(-ENOMEM) || old == (void*)(-EINVAL))
        {
            LOG_ERROR("Failed: unable to align heap (requested pad=%zu bytes).",
                        pad);
            ret = -ENOMEM;
            goto function_output;
        }
    }

    allocator->heap_start = (uint8_t*)base;
    allocator->heap_end = (uint8_t*)base;
    allocator->last_allocated = NULL;

    allocator->num_arenas = 1u;

    allocator->arenas = MEM_growUserHeap(allocator, sizeof(mem_arena_t));
    if (allocator->arenas == (void*)(-ENOMEM))
    {
        LOG_ERROR("Failed: unable to allocate memory for arenas.");
        ret = -ENOMEM;
        goto function_output;
    }

    arena = &allocator->arenas[0];
    arena->num_bins = DEFAULT_NUM_BINS;
    bins_bytes = arena->num_bins * sizeof(block_header_t*);

    arena->bins = MEM_growUserHeap(allocator, (intptr_t)bins_bytes);
    if (arena->bins == (void*)(-ENOMEM))
    {
        LOG_ERROR("Failed: unable to allocate memory for free lists (bins).");
        ret = -ENOMEM;
        goto function_output;
    }

    MEM_memset(arena->bins, 0, bins_bytes);

    allocator->free_lists = arena->bins;
    allocator->num_size_classes = arena->num_bins;

    allocator->mmap_list = NULL;

    pthread_getattr_np(pthread_self(), &attr);
    pthread_attr_getstack(&attr, &stack_addr, &stack_size);
    pthread_attr_destroy(&attr);

    atomic_init(&allocator->gc_running, false);

    allocator->gc_interval_ms = GC_INTERVAL_MS;
    allocator->gc_thread_started = 0u;

    pthread_mutex_init(&allocator->gc_lock, NULL);
    pthread_cond_init(&allocator->gc_cond, NULL);

    allocator->stack_top = (uintptr_t*)((uintptr_t)stack_addr + stack_size);
    allocator->stack_bottom = (uintptr_t*)__builtin_frame_address(0);

#ifdef RUNNING_ON_VALGRIND
    if(mempool_created == true)
        VALGRIND_DESTROY_MEMPOOL(allocator);

    VALGRIND_CREATE_MEMPOOL(allocator, 0, false);
    mempool_created = true;
#endif

    LOG_INFO("Allocator initialized: heap=%p..%p, bins=%u",
             allocator->heap_start, allocator->heap_end, (unsigned)arena->num_bins);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_growUserHeap
 *  @brief      Expands the user heap by a specified increment.
 *
 *  @param[in]  alloc   Memory allocator context.
 *  @param[in]  inc     Heap size increment (in bytes).
 *
 *  @return     Previous end address of the heap, or error code.
 *
 *  @retval     Valid address: Heap successfully expanded.
 *  @retval     (void*)(-EINVAL): Invalid allocator context.
 *  @retval     (void*)(-ENOMEM): Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *alloc, const intptr_t inc)
{
    void *old = NULL;

    block_header_t *header = NULL;

    if (alloc == NULL)
    {
        old =  PTR_ERR(-EINVAL);
        goto function_output;
    }

    old = MEM_sbrk(inc);

    if ((intptr_t)old < 0)
        goto function_output;

    MEM_memset(old, 0, (size_t)inc);

    alloc->heap_end = (uint8_t *)old + inc;

    header = (block_header_t *)old;
    header->size = (size_t)inc;
    header->free = 0u;
    header->marked = 1u;

function_output:
    return old;
}

/** ============================================================================
 *  @fn         MEM_mapAlloc
 *  @brief      Allocates a page‐aligned memory region via mmap and registers it
 *              in the allocator’s mmap list for later freeing.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *                          Must not be NULL.
 *  @param[in]  total_size  Number of bytes requested (will be rounded up to a
 *                          multiple of the system page size).
 *
 *  @return     On success, returns the address of the mapped region.
 *
 *  @retval     (void*)(intptr_t)(-EINVAL)
 *                          allocator is NULL.
 *  @retval     (void*)(intptr_t)(-EIO)
 *                          mmap() failed.
 *  @retval     (void*)(intptr_t)(-ENOMEM)
 *                          Allocation of metadata node failed.
 * ========================================================================== */
static int *MEM_mapAlloc(mem_allocator_t *allocator, size_t total_size)
{
    void *ptr = NULL;

    mmap_t *map_block = NULL;

    block_header_t *header = NULL;

    size_t pagesz = 0u;
    size_t map_size = 0u;

    if (allocator == NULL)
    {
        LOG_ERROR("Allocator is NULL");
        ptr = PTR_ERR(-EINVAL);
        goto function_output;
    }

    pagesz = (size_t)sysconf(_SC_PAGESIZE);
    map_size = (size_t)(((total_size + pagesz - 1u) / pagesz) * pagesz);

    ptr = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_PRIVATE |
                MAP_ANONYMOUS, -1, 0);
    if (ptr == MAP_FAILED)
    {
        LOG_ERROR("mmap failed (%zu bytes): %s", map_size, strerror(errno));
        ptr = PTR_ERR(-EIO);
        goto function_output;
    }

    map_block = MEM_allocMalloc(allocator, sizeof(mmap_t), 
                                "mmap_meta", FIRST_FIT);
    if (map_block == NULL)
    {
        munmap(ptr, map_size);
        ptr = PTR_ERR(-ENOMEM);
        goto function_output;
    }

    map_block->addr = ptr;
    map_block->size = map_size;
    map_block->next = allocator->mmap_list;
    allocator->mmap_list = map_block;

    header = (block_header_t *)ptr;
    header->magic = MAGIC_NUMBER;
    header->size = map_size;
    header->free = 0u;
    header->marked = 1u;
    header->prev = NULL;
    header->next = NULL;
    header->file = NULL;
    header->line = 0u;
    header->var_name = NULL;

    *(uint32_t *)((uint8_t *)ptr + map_size - sizeof(uint32_t)) = CANARY_VALUE; 

    LOG_INFO("mmap allocated %zu at %p", map_size, ptr);

function_output:
    return ptr;
}

/** ============================================================================
 *  @fn         MEM_mapFree
 *  @brief      Unmaps a previously mapped memory region and removes its metadata
 *              entry from the allocator’s mmap list.
 *
 *  @param[in]  allocator   Memory allocator context. Must not be NULL.
 *  @param[in]  addr        Address of the memory region to unmap.
 *
 *  @return     Integer status code.
 *
 *  @retval     EXIT_SUCCESS
 *                          Region was successfully unmapped and its metadata
 *                          entry freed. (If freeing metadata fails, an error
 *                          is logged but success is still returned.)
 *  @retval     -EINVAL
 *                          allocator is NULL, or addr was not found in the
 *                          allocator’s mmap list.
 *  @retval     -ENOMEM
 *                          munmap() failed to unmap the region.
 * ========================================================================== */
static int MEM_mapFree(mem_allocator_t *allocator, void *addr)
{
    int ret = EXIT_SUCCESS;

    mmap_t **map_ref = NULL;
    mmap_t *to_free = NULL;

    size_t map_size = 0u;

    if (allocator == NULL)
    {
        LOG_ERROR("Allocator is NULL");
        ret = -EINVAL;
        goto function_output;
    }

    map_ref = &allocator->mmap_list;

    while (*map_ref)
    {
        if ((*map_ref)->addr == addr)
        {
            map_size = (*map_ref)->size;

            if (munmap(addr, map_size) != 0)
            {
                LOG_ERROR("munmap failed: %s", strerror(errno));
                ret = -ENOMEM;
                goto function_output;
            }

            to_free = *map_ref;
            *map_ref = to_free->next;

            ret = MEM_allocFree(
                allocator,
                to_free,
                "mmap_meta"
            );

            if (ret != EXIT_SUCCESS)
                LOG_ERROR("Failed to free mmap_meta metadata: %d", ret);

            LOG_INFO("munmap freed %p size %zu", addr, map_size);
            ret = EXIT_SUCCESS;
            goto function_output;
        }

        map_ref = &(*map_ref)->next;
    }

    ret = -EINVAL;

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_findFirstFit
 *  @brief      Searches for the first suitable free memory
 *              block in size-class free lists
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] fit_block   Pointer to store found suitable block address
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:        No suitable block found in free lists
 * ========================================================================== */
static int MEM_findFirstFit(mem_allocator_t *const allocator,
                            const size_t size,
                            block_header_t **fit_block)
{
    int ret = EXIT_SUCCESS;

    block_header_t *current = NULL;

    int start_class = 0;
    size_t iterator = 0u;

    start_class = MEM_getSizeClass(allocator, size);
    if (UNLIKELY(start_class < 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid size class start_class : %d for block size %zu "
                "Error code: %d.\n", start_class, (*fit_block)->size, ret);
        goto function_output;
    }

    for (iterator = (size_t)start_class;
        iterator < allocator->num_size_classes;
        iterator++)
    {
        current = allocator->free_lists[iterator];
        while (current)
        {
            if ((MEM_validateBlock(allocator, current) == EXIT_SUCCESS)
                && (current->free && current->size >= size))
            {
                *fit_block = current;
                ret = EXIT_SUCCESS;
                goto function_output;
            }
            current = current->fl_next;
        }
    }

    ret = -ENOMEM;
    LOG_WARNING("First-fit allocation failed:"
                "Req size: %zu | Max checked class: %zu "
                "Error code: %d.\n",
                size, (allocator->num_size_classes - 1u), ret);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_findNextFit
 *  @brief      Searches for next suitable free memory block using
 *              NEXT_FIT strategy from last allocated position
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] fit_block   Pointer to store found suitable block address
 *
 *  @return     Integer status code
 *
 *  @retval      EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters
 *  @retval     -ENOMEM:        No suitable block found in heap
 * ========================================================================== */
static int MEM_findNextFit(mem_allocator_t *const allocator,const size_t size,
                            block_header_t **fit_block)
{
    int ret = EXIT_SUCCESS;

    block_header_t *current = NULL;
    block_header_t *start = NULL;

    if (UNLIKELY(allocator == NULL || fit_block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | fit_block %p. "
                  "Error code: %d.\n", (void *)allocator,
                                        (void *)fit_block, ret);
        goto function_output;
    }

    if (allocator->last_allocated == NULL ||
        allocator->last_allocated->free == 0 ||
        allocator->last_allocated->magic != MAGIC_NUMBER)
    {
        LOG_INFO("Fallback to First-Fit (no valid last_allocated)");
        ret = MEM_findFirstFit(allocator, size, fit_block);
        if (ret == EXIT_SUCCESS)
            allocator->last_allocated = *fit_block;
         goto function_output;
    }

    current = allocator->last_allocated;
    start = current;

    do
    {
        if ((MEM_validateBlock(allocator, current) == EXIT_SUCCESS) &&
            (current->free && current->size >= size))
        {
            *fit_block = current;
            allocator->last_allocated = current;
            goto function_output;
        }

        current = (current->next) ? current->next :
                                    (block_header_t *)allocator->heap_start;
    } while (current != start);

    ret = -ENOMEM;
    LOG_WARNING("Next-fit allocation failed: Req size: %zu | Start block: %p. "
                "Error code: %d.\n", size, (void *)start, ret);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_findBestFit
 *  @brief      Searches for smallest suitable free block
 *              in size-class free lists (BEST_FIT)
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[out] best_fit    Pointer to store found optimal block address
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Suitable block found successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:        No suitable block found in free lists
 * ========================================================================== */
static int MEM_findBestFit(mem_allocator_t *const allocator, const size_t size,
                            block_header_t **best_fit)
{
    int ret = EXIT_SUCCESS;

    block_header_t *current = NULL;

    size_t iterator = 0u;

    int start_class = 0;

    if (UNLIKELY(allocator == NULL || best_fit == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | best_fit %p"
                "Error code: %d.\n", (void *)allocator, (void *)best_fit, ret);
        goto function_output;
    }

    *best_fit = NULL;
    start_class = MEM_getSizeClass(allocator, size);

    if (UNLIKELY(start_class < 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid size class index: %d for block size %zu"
                "Error code: %d.\n", start_class, size, ret);
        goto function_output;
    }

    for (iterator = (size_t)start_class; 
        iterator < (size_t)allocator->num_size_classes;
        iterator++)
    {
        current = allocator->free_lists[iterator];

        while (current)
        {
            if ((MEM_validateBlock(allocator, current) == EXIT_SUCCESS) &&
                (current->free && current->size >= size))
            {
                if (!(*best_fit) || current->size < (*best_fit)->size)
                    *best_fit = current;
            }

            current = current->fl_next;
        }

        if (*best_fit)
            goto function_output;
    }

    ret = -ENOMEM;
    LOG_WARNING("Best-fit allocation failed:"
                "Req size: %zu | Max checked class: %zu."
                "Error code: %d.\n", 
                size, (allocator->num_size_classes - 1), ret);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_splitBlock
 *  @brief      Splits a memory block into allocated and free portions
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to split
 *  @param[in]  req_size    Requested allocation size
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Block split successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted block
 *
 *  @note       If remaining space < MIN_BLOCK_SIZE, uses entire block
 * ========================================================================== */
static int MEM_splitBlock(mem_allocator_t *const allocator,
                            block_header_t *const block, const size_t req_size)
{
    int ret = EXIT_SUCCESS;

    block_header_t *new_block = NULL;

    uint32_t *data_canary = NULL;

    size_t aligned_size = 0u;
    size_t total_size = 0u;
    size_t remaining_size = 0u;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | block %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    ret = MEM_validateBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
    {
        LOG_ERROR("Block validation failed: %p. "
                  "Error code: %d.\n", (void *)block, ret);
        goto function_output;
    }

    aligned_size = ALIGN(req_size);
    total_size = (size_t)(aligned_size + sizeof(block_header_t)
                            + sizeof(uint32_t));

    if (block->size < total_size + MIN_BLOCK_SIZE)
    {
        block->free = 0u;

        MEM_removeFreeBlock(allocator, block);

        LOG_DEBUG("Using full block %p | Req size: %zu | Block size: %zu",
                  (void *)block, req_size, block->size);

        goto function_output;
    }

    remaining_size = (size_t)(block->size - total_size);

    MEM_removeFreeBlock(allocator, block);

    block->size = total_size;
    block->free = 0u;
    block->magic = MAGIC_NUMBER;
    block->canary = CANARY_VALUE;

    data_canary = (uint32_t *)((uint8_t *)block + block->size
                                            - sizeof(uint32_t));
    *data_canary = CANARY_VALUE;
    new_block = (block_header_t *)((uint8_t *)block + total_size);

    new_block->magic = MAGIC_NUMBER;
    new_block->size = remaining_size;
    new_block->free = 1u;
    new_block->marked = 0u;
    new_block->file = NULL;
    new_block->line = 0ull;
    new_block->var_name = NULL;
    new_block->prev = block;
    new_block->next = block->next;

    if (block->next)
        block->next->prev = new_block;

    block->next = new_block;

    new_block->canary = CANARY_VALUE;

    data_canary = (uint32_t *)((uint8_t *)new_block + new_block->size
                                            - sizeof(uint32_t));
    *data_canary = CANARY_VALUE;

    new_block->fl_next = NULL;
    new_block->fl_prev = NULL;

    MEM_insertFreeBlock(allocator, new_block);

    LOG_DEBUG("Block split | Original: %p (%zuB) | New: %p (%zuB)",
              (void *)block, block->size, (void *)new_block, new_block->size);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_mergeBlocks
 *  @brief      Merges adjacent free memory blocks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to merge with neighbors
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Blocks merged successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted blocks
 * ========================================================================== */
static int MEM_mergeBlocks(mem_allocator_t *const allocator,
                           block_header_t *block)
{
    int ret = EXIT_SUCCESS;

    uint8_t *next_addr = NULL;

    block_header_t *next_block = NULL;
    block_header_t *prev_block = NULL;

    uint32_t *canary_ptr = NULL;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator=%p, block=%p."
                    "Error code: %d\n",
                  (void*)allocator, (void*)block, ret);
        goto function_output;
    }

    MEM_removeFreeBlock(allocator, block);

    ret = MEM_validateBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
    {
        LOG_ERROR("Block validation failed for %p. Error code: %d\n",
                  (void*)block, ret);
        goto function_output;
    }

    next_addr = (uint8_t*)block + block->size;
    if (next_addr + sizeof(block_header_t) <= allocator->heap_end)
    {
        next_block = (block_header_t*)next_addr;

        ret = MEM_validateBlock(allocator, next_block);
        if (ret == EXIT_SUCCESS && next_block->free)
        {
            MEM_removeFreeBlock(allocator, next_block);
            block->size += next_block->size;
            block->next = next_block->next;
            if (next_block->next)
                next_block->next->prev = block;

            canary_ptr = (uint32_t*)(((uint8_t*)block
                                        + block->size - sizeof(uint32_t)));
            *canary_ptr = CANARY_VALUE;
            LOG_DEBUG("Merged with next block: new size = %zu bytes\n",
                        block->size);
        }
    }

    prev_block = block->prev;
    if (prev_block)
    {
        ret = MEM_validateBlock(allocator, prev_block);
        if (ret == EXIT_SUCCESS && prev_block->free)
        {
            MEM_removeFreeBlock(allocator, prev_block);
            prev_block->size += block->size;
            prev_block->next = block->next;
            if (block->next)
                block->next->prev = prev_block;

            canary_ptr = (uint32_t*)(((uint8_t*)prev_block
                            + prev_block->size - sizeof(uint32_t)));
            *canary_ptr = CANARY_VALUE;

            block = prev_block;
            LOG_DEBUG("Merged with previous block: new size = %zu bytes\n",
                        block->size);
        }
    }

    MEM_insertFreeBlock(allocator, block);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_allocatorMalloc
 *  @brief      Allocates memory using specified strategy
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Requested allocation size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorMalloc(mem_allocator_t *const allocator,
                                 const size_t size,
                                 const char *const file,
                                 const int   line,
                                 const char *const var_name,
                                 const allocation_strategy_t strategy)
{
    
    void *user_ptr = NULL;

    mem_arena_t *arena = NULL;
    block_header_t *block = NULL;

    void *old_brk = NULL;
    void *raw_mmap = NULL;

    size_t total_size = 0u;

    uint32_t *data = NULL;

    int ret = EXIT_SUCCESS;

    const find_fn_t find_fns[] =
    {
        [FIRST_FIT] = MEM_findFirstFit,
        [NEXT_FIT ] = MEM_findNextFit,
        [BEST_FIT ] = MEM_findBestFit,
    };

    if (!allocator || size == 0)
    {
        user_ptr = PTR_ERR(-EINVAL);
        goto null_pointer;
    }

    total_size = ALIGN(size) + sizeof(block_header_t) + sizeof(uint32_t);
    arena = &allocator->arenas[0];

    if (size > MMAP_THRESHOLD)
    {
        raw_mmap = MEM_mapAlloc(allocator, total_size);
        if (raw_mmap == NULL)
        {
            LOG_ERROR("Failed (MMAP): grow heap by %zu bytes.", total_size);
            user_ptr = PTR_ERR(-ENOMEM);
            goto function_output;
        }

        block = (block_header_t *)raw_mmap;
        block->magic = MAGIC_NUMBER;
        block->size = total_size;
        block->free = 0;
        block->marked = 0;
        block->next = NULL;
        block->prev = NULL;
        block->canary = CANARY_VALUE;

        data = (uint32_t*)((uint8_t*)raw_mmap + total_size - sizeof(uint32_t));
        *data = CANARY_VALUE;

        block->file = file;
        block->line = (unsigned long long)line;
        block->var_name = var_name;

        LOG_INFO("mmap used for alloc %zu bytes at %p", size, raw_mmap);
        user_ptr = (uint8_t *)raw_mmap + sizeof(block_header_t);

        goto function_output;
    }

    ret = find_fns[strategy](allocator, total_size, &block);
    if (ret == -ENOMEM)
    {
        old_brk = MEM_growUserHeap(allocator, (intptr_t)total_size);
        if ((intptr_t)old_brk < 0) {
            user_ptr = PTR_ERR(-ENOMEM);
            goto function_output;
        }
    
        block = (block_header_t*)old_brk;
        block->magic = MAGIC_NUMBER;
        block->size = total_size;
        block->free = 1;
        block->marked = 0;
        block->next = NULL;
        block->prev = NULL;
        block->canary = CANARY_VALUE;
    
        data = (uint32_t*)((uint8_t*)block + total_size - sizeof(uint32_t));
        *data = CANARY_VALUE;

        block->fl_prev = block->fl_next = NULL;

        MEM_insertFreeBlock(allocator, block);
    
        ret = find_fns[strategy](allocator, total_size, &block);
    }

    if (ret != EXIT_SUCCESS)
    {
        user_ptr = PTR_ERR((ret == -ENOMEM) ? -ENOMEM : -EIO);
        goto function_output;
    }

    if (strategy == NEXT_FIT)
        allocator->last_allocated = block;

    arena->top_chunk = block;

    MEM_splitBlock(allocator, block, size);

    block->file = file;
    block->line = (unsigned long long)line;
    block->var_name = var_name;

    user_ptr = (uint8_t*)block + sizeof(block_header_t);

function_output:

#ifdef RUNNING_ON_VALGRIND
    VALGRIND_MEMPOOL_ALLOC(
        allocator,
        user_ptr,
        block ? (block->size - sizeof(block_header_t) - sizeof(uint32_t)) : 0
    );
#endif

null_pointer:
    return user_ptr;
}

/** ============================================================================
 *  @fn         MEM_allocatorRealloc
 *  @brief      Reallocates memory with safety checks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to reallocate
 *  @param[in]  new_size    New allocation size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to reallocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorRealloc(mem_allocator_t *const allocator,
                                    void *const ptr,
                                    const size_t new_size,
                                    const char *const file,
                                    const int line,
                                    const char *const var_name,
                                    const allocation_strategy_t strategy)
{
    int ret = EXIT_SUCCESS;

    void *new_ptr = NULL;

    block_header_t *old_block = NULL;

    size_t old_size = 0u;

    if (UNLIKELY(allocator == NULL))
    {
        new_ptr = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid allocator: %p. "
                  "Error code: %d.\n", (void *)allocator, ret);
        goto function_output;
    }

    if (ptr == NULL)
    {
        new_ptr = MEM_allocatorMalloc(allocator, new_size, file,
                                        line, var_name, strategy);
        goto function_output;
    }

    old_block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    ret = MEM_validateBlock(allocator, old_block);
    if (ret != EXIT_SUCCESS)
    {
        new_ptr = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid block | Addr: %p. "
                  "Error code: %d.\n", ptr, ret);
        goto function_output;
    }

    old_size = (size_t)(old_block->size - sizeof(block_header_t)
                        - sizeof(uint32_t));
    if (old_size >= new_size)
    {
        LOG_DEBUG("Reallocation not needed:" 
                    "Addr: %p | Current size: %zu | New size: %zu",
                    ptr, old_size, new_size);

        new_ptr = ptr;
        goto function_output;
    }

    new_ptr = MEM_allocatorMalloc(allocator, new_size, file,
                                    line, var_name, strategy);
    if (new_ptr != NULL)
    {
        if (MEM_memcpy(new_ptr, ptr, old_size) != new_ptr)
        {
            new_ptr = PTR_ERR(-EINVAL);
            goto function_output;
        }

        ret = MEM_allocatorFree(allocator, ptr, file, line, var_name);
        if (ret != EXIT_SUCCESS)
            goto function_output;

        LOG_INFO("Memory reallocated | Old: %p | New: %p | Size: %zu",
                 ptr, new_ptr, new_size);
    }

function_output:
    return new_ptr;
}

/** ============================================================================
 *  @fn         MEM_allocatorCalloc
 *  @brief      Allocates and zero-initializes memory
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  num         Number of elements
 *  @param[in]  size        Element size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorCalloc(mem_allocator_t *const allocator,
                                    const size_t num,
                                    const size_t size,
                                    const char *const file,
                                    const int line,
                                    const char *const var_name,
                                    const allocation_strategy_t strategy)
{
    void *ptr = NULL;

    block_header_t *block = NULL;

    size_t total = 0u;
    size_t data_size = 0u;

    if (UNLIKELY(allocator == NULL || num == 0 || size == 0))
    {
        ptr = PTR_ERR(-EINVAL);
        LOG_ERROR("Invalid parameters | Allocator: %p | Num: %zu | Size: %zu.",
                    (void *)allocator, num, size);
        goto function_output;
    }

    total = (size_t)(num * size);
    ptr = MEM_allocatorMalloc(allocator, total, file, line, var_name, strategy);
    if (ptr == NULL)
        goto function_output;

    block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    data_size = block->size - sizeof(block_header_t) - sizeof(uint32_t);

    MEM_memset(ptr, 0, data_size);

    LOG_DEBUG("Zero-initialized memory | Addr: %p | Size: %zu", ptr, total);

function_output:
    return ptr;
}

/** ============================================================================
 *  @fn         MEM_allocatorFree
 *  @brief      Releases allocated memory back to the heap
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to memory to free
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Memory freed successfully
 *  @retval     -EINVAL:        Invalid parameters or corrupted block
 * ========================================================================== */
static int MEM_allocatorFree(mem_allocator_t *const allocator,
                                void *const ptr,
                                const char *const file,
                                const int line,
                                const char *const var_name)
{
    int ret = EXIT_SUCCESS;

    block_header_t *block = NULL;
    mmap_t *map = NULL;

    void *old = NULL;

    uint8_t *block_end = NULL;

    intptr_t delta = 0;
    
    if (UNLIKELY(allocator == NULL || ptr == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters | Allocator: %p | Ptr: %p. "
                  "Error code: %d.\n", (void *)allocator, ptr, ret);
        goto function_output;
    }

    if (allocator && ptr)
    {
        block = (block_header_t *)((uint8_t*)ptr - sizeof(block_header_t));
        for (map = allocator->mmap_list; map; map = map->next)
        {
            if ((void*)block == map->addr)
            {
                ret = MEM_mapFree(allocator, map->addr);
                goto function_output;
            }
        }
    }

    block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    ret = MEM_validateBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
    {
        LOG_ERROR("Invalid block | Addr: %p | Source: %s:%d. "
                  "Error code: %d.\n", ptr, file, line, ret);
        goto function_output;
    }

    if (block->free)
    {
        ret = -EINVAL;
        LOG_ERROR("Realloc on freed block %p. err=%d", ptr, -EINVAL);
        goto function_output;
    }

#ifdef RUNNING_ON_VALGRIND
    VALGRIND_MEMPOOL_FREE(allocator, ptr);
#endif

    block->free = 1u;
    block->marked = 0u;
    block->file = file;
    block->line = (unsigned long long)line;
    block->var_name = var_name;

    if (block->size >= 
            (MMAP_THRESHOLD + sizeof(block_header_t) + sizeof(uint32_t))
        )
    {
        ret = MEM_mapFree(allocator, (void*)block);
        if (ret == EXIT_SUCCESS)
            goto function_output;
    }

    ret = MEM_mergeBlocks(allocator, block);
    if (ret != EXIT_SUCCESS)
    {
        LOG_ERROR("Failed to merge blocks:: err=%d\n", ret);
        goto function_output;
    }

    block_end = (uint8_t*)block + block->size;
    if (block_end == allocator->heap_end)
    {
        size_t shrink_size = block->size;
        MEM_removeFreeBlock(allocator, block);

        delta = -(intptr_t)shrink_size;
        LOG_INFO("Shrinking heap by %zu bytes", shrink_size);

        old = MEM_sbrk(delta);
        if ((intptr_t)old >= 0)
        {
            allocator->heap_end = (uint8_t*)allocator->heap_end + delta;
            allocator->last_allocated = (block_header_t*)allocator->heap_start;
            LOG_INFO("Heap shrunk by %zu bytes; new heap_end=%p",
                         shrink_size, allocator->heap_end);
            goto function_output;
        }
    }

    MEM_insertFreeBlock(allocator, block);

    LOG_INFO("Memory freed | Addr: %p | Source: %s:%d", ptr, file, line);

function_output:
    return ret;
}

/** ============================================================================
 *  @fn         MEM_allocatorPrintAll
 *  @brief      Prints detailed heap status information
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     EXIT_SUCCESS:   Heap information printed
 *  @retval     -EINVAL:        Invalid allocator parameter
 * ========================================================================== */
int MEM_allocatorPrintAll(mem_allocator_t *const allocator)
{
    int ret = EXIT_SUCCESS;
    block_header_t *current = NULL;

    if (UNLIKELY(allocator == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid allocator parameter. Error code: %d.", ret);
        goto function_output;
    }

    LOG_INFO("Heap Status Report:");
    LOG_INFO("Address\t\tSize\tFree\tOrigin");
    LOG_INFO("------------------------------------------------");

    current = (block_header_t *)allocator->heap_start;
    while ((uint8_t *)current < allocator->heap_end)
    {
        LOG_INFO("%p\t%zu\t%s\t%s:%llu",
                 (void *)((uint8_t *)current + sizeof(block_header_t)),
                 current->size - sizeof(block_header_t) - sizeof(uint32_t),
                 current->free ? "Yes" : "No",
                 current->file ? current->file : "N/A",
                 (unsigned long long)current->line);

        current = (block_header_t *)((uint8_t *)current + current->size);
    }

    LOG_DEBUG("Heap status printed successfully");

function_output:
    return ret;
}

/** ============================================================================
 *              P U B L I C  F U N C T I O N  C A L L S  A P I                  
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_allocMallocFirstFit
 *  @brief      Allocates memory using the FIRST_FIT strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  size        Requested allocation size.
 *  @param[in]  var         Variable name (for debugging).
 *
 *  @return     Pointer to allocated memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void *MEM_allocMallocFirstFit(mem_allocator_t *allocator,
                                size_t size, const char *var)
{
    return MEM_allocatorMalloc(allocator, size, __FILE__,
                                __LINE__,var, FIRST_FIT);
}

/** ============================================================================
 *  @fn         MEM_allocMallocBestFit
 *  @brief      Allocates memory using the BEST_FIT strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  size        Requested allocation size.
 *  @param[in]  var         Variable name (for debugging).
 *
 *  @return     Pointer to allocated memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void* MEM_allocMallocBestFit(mem_allocator_t *allocator,
                                size_t size, const char *var)
{
    return MEM_allocatorMalloc(allocator, size, __FILE__,
                                __LINE__, var, BEST_FIT);
}

/** ============================================================================
 *  @fn         MEM_allocMallocNextFit
 *  @brief      Allocates memory using the NEXT_FIT strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  size        Requested allocation size.
 *  @param[in]  var         Variable name (for debugging).
 *
 *  @return     Pointer to allocated memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void* MEM_allocMallocNextFit(mem_allocator_t *allocator,
                                size_t size, const char *var)
{
    return MEM_allocatorMalloc(allocator, size, __FILE__,
                                __LINE__, var, NEXT_FIT);
}

/** ============================================================================
 *  @fn         MEM_allocMalloc
 *  @brief      Allocates memory using a specified strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  size        Requested allocation size.
 *  @param[in]  var         Variable name (for debugging).
 *  @param[in]  strategy    Allocation strategy to use.
 *
 *  @return     Pointer to allocated memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void* MEM_allocMalloc(mem_allocator_t *allocator,
                        size_t size, const char *var,
                        allocation_strategy_t strategy)
{
    return MEM_allocatorMalloc(allocator, size, __FILE__,
                                __LINE__, var, strategy);
}

/** ============================================================================
 *  @fn         MEM_allocCalloc
 *  @brief      Allocates and zero-initializes memory using a specified strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  num         Number of elements.
 *  @param[in]  size        Size of each element.
 *  @param[in]  var         Variable name (for debugging).
 *  @param[in]  strategy    Allocation strategy to use.
 *
 *  @return     Pointer to allocated and zero-initialized memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void* MEM_allocCalloc(mem_allocator_t *allocator,
                        size_t num, size_t size,
                        const char *var,
                        allocation_strategy_t strategy)
{
    return MEM_allocatorCalloc(allocator, num, size, __FILE__,
                                __LINE__, var, strategy);
}

/** ============================================================================
 *  @fn         MEM_allocRealloc
 *  @brief      Reallocates memory with safety checks using a specified strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  ptr         Pointer to memory to reallocate.
 *  @param[in]  new_size    New requested allocation size.
 *  @param[in]  var         Variable name (for debugging).
 *  @param[in]  strategy    Allocation strategy to use.
 *
 *  @return     Pointer to reallocated memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void* MEM_allocRealloc(mem_allocator_t *allocator,
                        void *ptr, size_t new_size,
                        const char *var,
                        allocation_strategy_t strategy)
{
    return MEM_allocatorRealloc(allocator, ptr, new_size, __FILE__,
                                __LINE__, var, strategy);
}

/** ============================================================================
 *  @fn         MEM_allocFree
 *  @brief      Releases allocated memory back to the heap.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  ptr         Pointer to memory to free.
 *  @param[in]  var         Variable name (for debugging).
 *
 *  @return     Integer status code (EXIT_SUCCESS if successful).
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
int MEM_allocFree(mem_allocator_t *allocator, void *ptr,
                    const char *var)
{
    return MEM_allocatorFree(allocator, ptr, __FILE__, __LINE__, var);
}

/*< end of file >*/
