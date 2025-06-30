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
 *  @version    v4.0.00
 *  @date       26.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

/** ============================================================================
 *          P R I V A T E  P R E - I N C L U D E  D E F I N E S
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

/** ============================================================================
 *  @def        LOG_LEVEL
 *  @brief      Logging verbosity threshold for this module
 *
 *  @details    Sets the minimum severity of log messages that will be
 *              compiled into this translation unit. Only log calls at or
 *              below the specified level are enabled:
 *                - LOG_LEVEL_NONE    (0): disable all logging
 *                - LOG_LEVEL_ERROR   (1): errors only
 *                - LOG_LEVEL_WARNING (2): warnings and errors
 *                - LOG_LEVEL_INFO    (3): info, warnings, and errors
 *                - LOG_LEVEL_DEBUG   (4): debug, info, warnings, and errors
 * ========================================================================== */
#ifndef LOG_LEVEL
  #define LOG_LEVEL LOG_LEVEL_NONE
#endif

/** ============================================================================
 *                      P R I V A T E  I N C L U D E S
 * ========================================================================== */

/*< Dependencies >*/
#include <errno.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <unistd.h>
#include <valgrind/memcheck.h>

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
  #define __GC_HOT __attribute__((hot))
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
  #define __GC_COLD __attribute__((cold))
#else
  #define __GC_COLD
#endif

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
#define MAGIC_NUMBER     (uint32_t)(0xBE'EF'DE'ADU)

/** ============================================================================
 *  @def        CANARY_VALUE
 *  @brief      Canary value to detect buffer overflows.
 *
 *  @details    This constant is placed at the boundaries of
 *              memory allocations to detect buffer overflows.
 * ========================================================================== */
#define CANARY_VALUE     (uint32_t)(0xDE'AD'BE'EFULL)

/** ============================================================================
 *  @def        PREFETCH_MULT
 *  @brief      Prefetch optimization multiplier constant
 *
 *  @details    64-bit repeating byte pattern (0x01 per byte) used
 *              for efficient  memory block operations. Enables
 *              single-byte value replication across full register
 *              width in vectorized operations.
 * ========================================================================== */
#define PREFETCH_MULT    (uint64_t)(0x01'01'01'01'01'01'01'01ULL)

/** ============================================================================
 *  @def        BYTES_PER_CLASS
 *  @brief      Fixed byte allocation per classification unit
 *
 *  @details    Defines the number of bytes assigned to each
 *              classification category. Ensures memory alignment
 *              and efficient block processing in data structures.
 * ========================================================================== */
#define BYTES_PER_CLASS  (uint8_t)(128U)

/** ============================================================================
 *  @def        MMAP_THRESHOLD
 *  @brief      Threshold size for using mmap-based allocation
 *
 *  @details    When a requested allocation size meets or exceeds this value
 *              (128 KiB), the allocator will switch from using the heap
 *              (brk/sbrk) to using mmap for more efficient large-block
 *              handling and to reduce heap fragmentation.
 * ========================================================================== */
#define MMAP_THRESHOLD   (size_t)(128U * 1'024U)

/** ============================================================================
 *  @def        MIN_BLOCK_SIZE
 *  @brief      Defines the minimum memory block size.
 *
 *  @details    Ensures each memory block is large enough to hold
 *              a block header and alignment padding.
 * ========================================================================== */
#define MIN_BLOCK_SIZE   (size_t)(sizeof(block_header_t) + ARCH_ALIGNMENT)

/** ============================================================================
 *  @def        NR_OBJS
 *  @brief      Number of iterations used to scale GC sleep duration
 *
 *  @details    Specifies the multiplier applied to the base GC interval
 *              (in milliseconds) to compute the actual sleep time between
 *              successive garbage-collection cycles:
 *                  sleep_time = gc_interval_ms * NR_OBJS
 * ========================================================================== */
#define NR_OBJS          (uint16_t)(1'000U)

/** ============================================================================
 *  @def        LIKELY(x)
 *  @brief      Compiler hint for likely branch prediction.
 *
 *  @param [in] x   Condition that is likely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be true.
 * ========================================================================== */
#define LIKELY(x)        (__builtin_expect(!!(x), 1))

/** ============================================================================
 *  @def        UNLIKELY(x)
 *  @brief      Compiler hint for unlikely branch prediction.
 *
 *  @param [in] x   Condition that is unlikely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be false.
 * ========================================================================== */
#define UNLIKELY(x)      (__builtin_expect(!!(x), 0))

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
typedef int (*find_fn_t)(mem_allocator_t *const,
                         const size_t,
                         block_header_t **);

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
static int MEM_getSizeClass(mem_allocator_t *const allocator,
                            const size_t           size);
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
                             block_header_t *const  block);

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
static int MEM_insertFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block);

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
static int MEM_removeFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block);

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
static int MEM_findFirstFit(mem_allocator_t *const allocator,
                            const size_t           size,
                            block_header_t       **fit_block);

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
static int MEM_findNextFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **fit_block);

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
static int MEM_findBestFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **best_fit);

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
                           block_header_t        *block);

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
                          block_header_t *const  block,
                          const size_t           req_size);

/** ============================================================================
 *  @fn         MEM_growUserHeap
 *  @brief      Expands the user heap by a specified increment.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  inc         Heap size increment (in bytes).
 *
 *  @return     Previous end address of the heap, or error code.
 *
 *  @retval     Valid address: Heap successfully expanded.
 *  @retval     (void*)(-EINVAL): Invalid allocator context.
 *  @retval     (void*)(-ENOMEM): Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *const allocator,
                              const intptr_t         inc);

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
static int *MEM_mapAlloc(mem_allocator_t *allocator, const size_t total_size);

/** ============================================================================
 *  @fn         MEM_mapFree
 *  @brief      Unmaps a previously mapped memory region and removes its
 * metadata entry from the allocator’s mmap list.
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
static int MEM_mapFree(mem_allocator_t *const allocator, void *const addr);

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
static void *MEM_allocatorMalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @fn         MEM_allocatorCalloc
 *  @brief      Allocates and zero-initializes memory
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Element size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorCalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

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
static void *MEM_allocatorRealloc(mem_allocator_t *const      allocator,
                                  void *const                 ptr,
                                  const size_t                new_size,
                                  const char *const           file,
                                  const int                   line,
                                  const char *const           var_name,
                                  const allocation_strategy_t strategy)
  __LIBMEMALLOC_REALLOC;

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
                             void *const            ptr,
                             const char *const      file,
                             const int              line,
                             const char *const      var_name);

/** ============================================================================
 *  @fn         MEM_stackGrowsDown
 *  @brief      Determine at runtime whether the stack grows downward
 *
 *  @return     true if stack grows down (higher addresses → lower),
 *              false if it grows up
 * ========================================================================== */
static bool MEM_stackGrowsDown(void);

/** ============================================================================
 *  @fn         MEM_stackBounds
 *  @brief      Retrieve and record the stack limits for a given thread
 *
 *  @param[in]  tid        pthread_t of the thread whose stack is to be measured
 *  @param[in]  allocator  Pointer to mem_allocator_t where stack_top and
 *                         stack_bottom will be stored (must not be NULL)
 *
 *  @return     EXIT_SUCCESS on success, or -EINVAL if attribute query fails
 * ========================================================================== */
static int MEM_stackBounds(const pthread_t        id,
                           mem_allocator_t *const allocator);

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
 *  @fn         MEM_setInitialMarks
 *  @brief      Initialize the mark bits for all heap and memory-mapped blocks
 *
 *  @param[in]  allocator   Pointer to the mem_allocator_t context
 *
 *  @return     EXIT_SUCCESS on success, or -EINVAL if the allocator pointer
 * ========================================================================== */
__GC_HOT static int MEM_setInitialMarks(mem_allocator_t *const allocator);

/** ============================================================================
 *  @fn         MEM_gcMark
 *  @brief      Mark all allocated blocks that are still reachable on the heap
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_HOT static int MEM_gcMark(mem_allocator_t *const allocator);

/** ============================================================================
 *  @fn         MEM_gcSweep
 *  @brief      Sweep the heap, free unmarked blocks, and unmap memory-mapped
 *              regions
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_HOT static int MEM_gcSweep(mem_allocator_t *const allocator);

/** ============================================================================
 *  @fn         MEM_runGc
 *  @brief      Initialize or signal the garbage collector thread to run
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_COLD static int MEM_runGc(mem_allocator_t *const allocator);

/** ============================================================================
 *  @fn         MEM_stopGc
 *  @brief      Stop the garbage collector thread and perform a final collection
 *              cycle
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__GC_COLD static int MEM_stopGc(mem_allocator_t *const allocator);

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_stackGrowsDown
 *  @brief      Determine at runtime whether the stack grows downward
 *
 *  @return     true if stack grows down (higher addresses → lower),
 *              false if it grows up
 * ========================================================================== */
static bool MEM_stackGrowsDown(void)
{
  bool ret = false;

  volatile int addr_0 = 0u;
  volatile int addr_1 = 0u;

  ret = (&addr_1 < &addr_0) ? true : false;

  return ret;
}

/** ============================================================================
 *  @fn         MEM_stackBounds
 *  @brief      Retrieve and record the stack limits for a given thread
 *
 *  @param[in]  tid        pthread_t of the thread whose stack is to be measured
 *  @param[in]  allocator  Pointer to mem_allocator_t where stack_top and
 *                         stack_bottom will be stored (must not be NULL)
 *
 *  @return     EXIT_SUCCESS on success, or -EINVAL if attribute query fails
 * ========================================================================== */
static int MEM_stackBounds(const pthread_t id, mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  pthread_attr_t attr;

  void *base_addr = NULL;

  size_t stack_size = 0u;
  size_t guard_size = 0u;

  size_t page = 0u;

  bool grows_down = false;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid allocator pointer: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  page = (size_t)sysconf(_SC_PAGESIZE);

  ret = pthread_getattr_np(id, &attr);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = pthread_attr_getstack(&attr, &base_addr, &stack_size);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = pthread_attr_getguardsize(&attr, &guard_size);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = pthread_attr_destroy(&attr);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  if (guard_size < page)
    guard_size = page;

  grows_down = MEM_stackGrowsDown( );
  if (grows_down == true)
  {
    allocator->stack_bottom = (uintptr_t *)((char *)base_addr + guard_size);
    allocator->stack_top    = (uintptr_t *)((char *)base_addr + stack_size);
  }
  else
  {
    allocator->stack_bottom = (uintptr_t *)base_addr;
    allocator->stack_top
      = (uintptr_t *)((char *)base_addr + stack_size - guard_size);
  }

  LOG_INFO("Stack: grows %s | guard size=%zu | Bounds=[%p .. %p].\n",
           grows_down ? "down" : "up",
           guard_size,
           (void *)allocator->stack_bottom,
           (void *)allocator->stack_top);

function_output:
  return ret;
}

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

  unsigned char *ptr     = NULL;
  unsigned char *ptr_aux = NULL;

  size_t iterator = 0u;

  if (UNLIKELY((source == NULL) || (size <= 0)))
  {
    ret = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: source=%p, size=%zu. "
              "Error code: %d.\n",
              source,
              size,
              (int)(intptr_t)ret);
    goto function_output;
  }

  ptr = (unsigned char *)source;

  if ((uintptr_t)ptr % ARCH_ALIGNMENT != 0)
  {
    while ((iterator < size)
           && ((uintptr_t)(ptr + iterator) % ARCH_ALIGNMENT != 0))
    {
      ptr[iterator] = (unsigned char)value;
      iterator++;
    }
  }

  for (; (size_t)(iterator + ARCH_ALIGNMENT) <= size;
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
  LOG_INFO("Memory set: source=%p, value=0x%X, size=%zu.\n",
           source,
           (unsigned int)value,
           size);

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

  unsigned char *destine     = NULL;
  unsigned char *destine_aux = NULL;

  const unsigned char *source = NULL;

  size_t iterator = 0u;

  if (UNLIKELY((dest == NULL) || (src == NULL) || (size <= 0)))
  {
    ret = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: dest=%p, src=%p, size=%zu. "
              "Error code: %d.\n",
              dest,
              src,
              size,
              (int)(intptr_t)ret);
    goto function_output;
  }

  destine = (unsigned char *)dest;
  source  = (const unsigned char *)src;

  if ((uintptr_t)destine % ARCH_ALIGNMENT != 0)
  {
    while ((iterator < size)
           && ((uintptr_t)(destine + iterator) % ARCH_ALIGNMENT != 0))
    {
      destine[iterator] = source[iterator];
      iterator++;
    }
  }

  for (; (size_t)(iterator + ARCH_ALIGNMENT) <= size;
       iterator += (size_t)ARCH_ALIGNMENT)
  {
    *(uint64_t *)(destine + iterator) = *(const uint64_t *)(source + iterator);
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
  LOG_INFO("Memory copied: dest=%p, src=%p, size=%zu.\n", dest, src, size);

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
    old_break = PTR_ERR(-ENOMEM);
    LOG_ERROR("Failed to read current break. "
              "Error code: %d.\n",
              (int)(intptr_t)old_break);
    goto function_output;
  }

  if (sbrk(increment) == (void *)-1)
  {
    old_break = PTR_ERR(-ENOMEM);
    LOG_ERROR("Failed to adjust break (increment=%" PRIdPTR ""
              "Error code: %d.\n",
              increment,
              (int)(intptr_t)old_break);
    goto function_output;
  }

  new_break = sbrk(0);
  if (new_break == (void *)-1)
  {
    old_break = PTR_ERR(-ENOMEM);
    LOG_ERROR("Failed to read new break. "
              "Error code: %d.\n",
              (int)(intptr_t)old_break);
    goto function_output;
  }

  LOG_INFO("Program break moved from %p to %p (increment: %" PRIdPTR ").\n",
           old_break,
           new_break,
           increment);

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
                             block_header_t *const  block)
{
  int ret = EXIT_SUCCESS;

  uint32_t *data_canary = NULL;

  mmap_t *map = NULL;

  uint8_t *region_start = NULL;
  uint8_t *region_end   = NULL;

  bool in_heap = false;

  if (UNLIKELY((allocator == NULL) || (block == NULL)))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters. Allocator: %p, Block: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  region_start = allocator->heap_start;
  region_end   = allocator->heap_end;

  if ((uint8_t *)block < region_start || (uint8_t *)block >= region_end)
  {
    for (map = allocator->mmap_list; map; map = map->next)
    {
      region_start = (uint8_t *)map->addr;
      region_end   = region_start + map->size;

      if ((uint8_t *)block >= region_start && (uint8_t *)block < region_end)
        break;
    }
    if (map == NULL)
    {
      ret = -EFAULT;
      LOG_ERROR("Block %p outside heap and mmap regions. "
                "Error code: %d.\n",
                (void *)block,
                ret);
      return ret;
    }
  }
  else
  {
    in_heap      = true;
    region_start = allocator->heap_start + allocator->metadata_size;
    region_end   = allocator->heap_end;
  }

  if (block->magic != MAGIC_NUMBER && in_heap)
  {
    ret = -ENOTRECOVERABLE;
    LOG_ERROR("Invalid magic at %p: 0x%X (expected 0x%X). "
              "Error code: %d.\n",
              (void *)block,
              block->magic,
              MAGIC_NUMBER,
              ret);
    goto function_output;
  }

  if (block->canary != CANARY_VALUE && in_heap)
  {
    ret = -EPROTO;
    LOG_ERROR("Corrupted header at %p: 0x%X vs 0x%X. "
              "Error code: %d.\n",
              (void *)block,
              block->canary,
              CANARY_VALUE,
              ret);
    goto function_output;
  }

  data_canary = (uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t));
  if (*data_canary != CANARY_VALUE && in_heap)
  {
    ret = -EOVERFLOW;
    LOG_ERROR("Data overflow detected at %p (canary: 0x%X). "
              "Error code: %d.\n",
              (void *)block,
              *data_canary,
              ret);
    goto function_output;
  }

  if (((uint8_t *)block + block->size) > allocator->heap_end && in_heap)
  {
    ret = -EFBIG;
    LOG_ERROR("Structural overflow at %p (size: %zu). Heap range [%p - %p]. "
              "Error code: %d.\n",
              (void *)block,
              block->size,
              (void *)allocator->heap_start,
              (void *)allocator->heap_end,
              ret);
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
static int MEM_getSizeClass(mem_allocator_t *const allocator, const size_t size)
{
  int ret = EXIT_SUCCESS;

  size_t index     = 0u;
  size_t max_class = 0u;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid allocator pointer: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  if (UNLIKELY(size <= 0))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid size requested: %zu"
              "Error code: %d.\n",
              size,
              ret);
    goto function_output;
  }

  max_class = (size_t)((allocator->num_size_classes - 1u) * BYTES_PER_CLASS);
  index     = (size_t)((size + BYTES_PER_CLASS - 1u) / BYTES_PER_CLASS);

  if (UNLIKELY(index >= allocator->num_size_classes))
  {
    LOG_WARNING("Size overflow - "
                "Requested: %zu bytes | Max class: %zu bytes | "
                "Clamped to class %zu.\n",
                size,
                max_class,
                (allocator->num_size_classes - 1u));
    index = (size_t)(allocator->num_size_classes - 1);
  }
  else
  {
    LOG_INFO("Size class calculated - "
             "Requested: %zu bytes | Class: %zu (%zu-%zu bytes).\n",
             size,
             index,
             index * BYTES_PER_CLASS,
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
static int MEM_insertFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block)
{
  int ret = EXIT_SUCCESS;

  int index = 0u;

  if (UNLIKELY(allocator == NULL || block == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters - Allocator: %p, Block: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  index = MEM_getSizeClass(allocator, block->size);
  if (index < 0)
  {
    ret = -ENOMEM;
    goto function_output;
  }

  block->fl_next = allocator->free_lists[index];

  block->fl_prev = NULL;
  if (allocator->free_lists[index])
    allocator->free_lists[index]->fl_prev = block;

  allocator->free_lists[index] = block;
  LOG_INFO("Block %p inserted into free list %d (size: %zu)\n",
           (void *)block,
           index,
           block->size);

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
static int MEM_removeFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block)
{
  int ret = EXIT_SUCCESS;

  int index = 0u;

  if (UNLIKELY(allocator == NULL || block == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p, block: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  index = MEM_getSizeClass(allocator, block->size);
  if (index < 0)
  {
    ret = -EINVAL;
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
           (void *)block,
           index,
           block->size);

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

  mem_arena_t *arena     = NULL;
  gc_thread_t *gc_thread = NULL;

  void *base = NULL;
  void *old  = NULL;

  uintptr_t addr = 0;

  size_t pad        = 0u;
  size_t bins_bytes = 0u;

  base = MEM_sbrk(0);
  if (base == PTR_ERR(-ENOMEM))
  {
    ret = -ENOMEM;
    LOG_ERROR("unable to get heap base address %p. "
              "Error code: %d.\n",
              (void *)base,
              ret);
    goto function_output;
  }

  addr = (uintptr_t)base;
  pad  = (size_t)((ARCH_ALIGNMENT - (addr % ARCH_ALIGNMENT)) % ARCH_ALIGNMENT);

  if (pad)
  {
    old = MEM_sbrk((intptr_t)pad);
    if (old == PTR_ERR(-ENOMEM) || old == PTR_ERR(-EINVAL))
    {
      ret = -ENOMEM;
      LOG_ERROR("Unable to align heap (requested pad=%zu bytes). "
                "Error code: %d.\n",
                pad,
                ret);
      goto function_output;
    }
  }

  allocator->heap_start     = (uint8_t *)base;
  allocator->heap_end       = (uint8_t *)base;
  allocator->last_allocated = NULL;

  allocator->num_arenas = 1u;

  allocator->arenas = MEM_growUserHeap(allocator, sizeof(mem_arena_t));
  if (allocator->arenas == PTR_ERR(-ENOMEM))
  {
    ret = -ENOMEM;
    LOG_ERROR("Unable to allocate memory for arenas. "
              "Error code: %d.\n",
              ret);
    goto function_output;
  }

  arena           = &allocator->arenas[0];
  arena->num_bins = DEFAULT_NUM_BINS;
  bins_bytes      = (size_t)(arena->num_bins * sizeof(block_header_t *));

  arena->bins = MEM_growUserHeap(allocator, (intptr_t)bins_bytes);
  if (arena->bins == (void *)(-ENOMEM))
  {
    ret = -ENOMEM;
    LOG_ERROR("Unable to allocate memory for free lists (bins). "
              "Error code: %d.\n",
              ret);
    goto function_output;
  }

  MEM_memset(arena->bins, 0, bins_bytes);

  allocator->free_lists       = arena->bins;
  allocator->num_size_classes = arena->num_bins;

  allocator->mmap_list = NULL;

  allocator->metadata_size
    = ((uintptr_t)arena->bins + bins_bytes) - (uintptr_t)allocator->heap_start;

  gc_thread = &allocator->gc_thread;

  gc_thread->gc_interval_ms    = GC_INTERVAL_MS;
  gc_thread->gc_thread_started = 0u;

  atomic_init(&gc_thread->gc_running, false);
  atomic_init(&gc_thread->gc_exit, false);

  ret = pthread_mutex_init(&gc_thread->gc_lock, NULL);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = pthread_cond_init(&gc_thread->gc_cond, NULL);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = MEM_stackBounds(pthread_self( ), allocator);
  if (ret != EXIT_SUCCESS)
  {
    LOG_ERROR("Unable to capture stack bounds. "
              "Error code: %d.\n",
              ret);
    goto function_output;
  }

#ifdef RUNNING_ON_VALGRIND
  if (mempool_created == true)
    VALGRIND_DESTROY_MEMPOOL(allocator);

  VALGRIND_CREATE_MEMPOOL(allocator, 0, false);
  mempool_created = true;
#endif

  LOG_INFO("Allocator initialized: initial_heap=[%p...%p], bins=%zu.\n",
           allocator->heap_start,
           allocator->heap_end,
           arena->num_bins);

function_output:
  return ret;
}

/** ============================================================================
 *  @fn         MEM_growUserHeap
 *  @brief      Expands the user heap by a specified increment.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  inc         Heap size increment (in bytes).
 *
 *  @return     Previous end address of the heap, or error code.
 *
 *  @retval     Valid address: Heap successfully expanded.
 *  @retval     (void*)(-EINVAL): Invalid allocator context.
 *  @retval     (void*)(-ENOMEM): Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *const allocator,
                              const intptr_t         inc)
{
  void *old = NULL;

  block_header_t *header = NULL;

  if (UNLIKELY(allocator == NULL))
  {
    old = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: allocator=%p. "
              "Error code: %d.\n",
              (void *)allocator,
              (int)(intptr_t)old);
    goto function_output;
  }

  old = MEM_sbrk(inc);

  if ((intptr_t)old < 0)
    goto function_output;

  MEM_memset(old, 0, (size_t)inc);

  allocator->heap_end = (uint8_t *)((uint8_t *)old + inc);

  header         = (block_header_t *)old;
  header->size   = (size_t)inc;
  header->free   = 0u;
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
static int *MEM_mapAlloc(mem_allocator_t *allocator, const size_t total_size)
{
  void *ptr = NULL;

  mmap_t *map_block = NULL;

  block_header_t *header = NULL;

  size_t page     = 0u;
  size_t map_size = 0u;

  if (UNLIKELY(allocator == NULL))
  {
    ptr = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: allocator=%p. "
              "Error code: %d.\n",
              (void *)allocator,
              (int)(intptr_t)ptr);
    goto function_output;
  }

  page     = (size_t)sysconf(_SC_PAGESIZE);
  map_size = (size_t)(((total_size + page - 1u) / page) * page);

  ptr = mmap(NULL,
             map_size,
             PROT_READ | PROT_WRITE,
             MAP_PRIVATE | MAP_ANONYMOUS,
             -1,
             0);
  if (ptr == MAP_FAILED)
  {
    ptr = PTR_ERR(-EIO);
    LOG_ERROR("Mmap failed: %zu bytes. "
              "Error code: %d.\n",
              map_size,
              (int)(intptr_t)ptr);
    goto function_output;
  }

  map_block = MEM_allocatorMalloc(allocator,
                                  sizeof(mmap_t),
                                  __FILE__,
                                  __LINE__,
                                  "mmap_meta",
                                  FIRST_FIT);
  if (map_block == NULL)
  {
    munmap(ptr, map_size);
    ptr = PTR_ERR(-ENOMEM);
    LOG_ERROR("Mmap metadata allocation failed: %zu bytes. "
              "Error code: %d.\n",
              sizeof(mmap_t),
              (int)(intptr_t)ptr);
    goto function_output;
  }

  map_block->addr      = ptr;
  map_block->size      = map_size;
  map_block->next      = allocator->mmap_list;
  allocator->mmap_list = map_block;

  header           = (block_header_t *)ptr;
  header->magic    = MAGIC_NUMBER;
  header->size     = map_size;
  header->free     = 0u;
  header->marked   = 1u;
  header->prev     = NULL;
  header->next     = NULL;
  header->file     = NULL;
  header->line     = 0u;
  header->var_name = NULL;

  *(uint32_t *)((uint8_t *)ptr + map_size - sizeof(uint32_t)) = CANARY_VALUE;

  LOG_INFO("Mmap allocated: %zu bytes at %p.\n", map_size, ptr);

function_output:
  return ptr;
}

/** ============================================================================
 *  @fn         MEM_mapFree
 *  @brief      Unmaps a previously mapped memory region and removes its
 * metadata entry from the allocator’s mmap list.
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
static int MEM_mapFree(mem_allocator_t *const allocator, void *const addr)
{
  int ret = EXIT_SUCCESS;

  mmap_t **map_ref = NULL;
  mmap_t  *to_free = NULL;

  size_t map_size = 0u;

  if (UNLIKELY(allocator == NULL || addr == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid arguments: allocator=%p addr=%p. "
              "Error code: %d.\n",
              (void *)allocator,
              addr,
              ret);
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
        ret = -ENOMEM;
        LOG_ERROR("Mmap failed: %zu bytes. "
                  "Error code: %d.\n",
                  map_size,
                  ret);
        goto function_output;
      }

      to_free  = *map_ref;
      *map_ref = to_free->next;

      ret
        = MEM_allocatorFree(allocator, to_free, __FILE__, __LINE__, "mmap_meta");
      if (ret != EXIT_SUCCESS)
      {
        LOG_ERROR("Mmap metadata free failed: %zu bytes. "
                  "Error code: %d.\n",
                  sizeof(mmap_t),
                  (int)(intptr_t)ret);
        goto function_output;
      }

      LOG_INFO("Munmap freed: %zu bytes at %p.\n", map_size, addr);
    }
    else
    {
      map_ref = &(*map_ref)->next;
    }
  }

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
                            const size_t           size,
                            block_header_t       **fit_block)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = NULL;

  int    start_class = 0;
  size_t class_idx   = 0u;

  start_class = MEM_getSizeClass(allocator, size);
  if (start_class < 0)
  {
    ret = -ENOMEM;
    goto function_output;
  }

  for (class_idx = (size_t)start_class; class_idx < allocator->num_size_classes;
       class_idx++)
  {
    current = allocator->free_lists[class_idx];
    while (current)
    {
      ret = MEM_validateBlock(allocator, current);
      if ((ret == EXIT_SUCCESS) && (current->free && current->size >= size))
      {
        *fit_block = current;
        goto function_output;
      }

      current = current->fl_next;
    }
  }

  ret = -ENOMEM;
  LOG_WARNING("First-fit allocation failed: "
              "Req size: %zu | Max checked class: %zu. "
              "Error code: %d.\n",
              size,
              (size_t)(allocator->num_size_classes - 1u),
              ret);

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
static int MEM_findNextFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **fit_block)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = NULL;
  block_header_t *start   = NULL;

  if (UNLIKELY(allocator == NULL || fit_block == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator %p | fit_block %p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)fit_block,
              ret);
    goto function_output;
  }

  if (allocator->last_allocated == NULL || allocator->last_allocated->free == 0
      || allocator->last_allocated->magic != MAGIC_NUMBER)
  {
    LOG_INFO("Fallback to First-Fit (no valid last_allocated).\n");
    ret = MEM_findFirstFit(allocator, size, fit_block);
    if (ret == EXIT_SUCCESS)
      allocator->last_allocated = *fit_block;

    goto function_output;
  }

  current = allocator->last_allocated;
  start   = current;

  do
  {
    ret = MEM_validateBlock(allocator, current);
    if ((ret == EXIT_SUCCESS) && (current->free && current->size >= size))
    {
      *fit_block                = current;
      allocator->last_allocated = current;
      goto function_output;
    }

    current = (current->next) ? current->next
                              : (block_header_t *)allocator->heap_start;
  } while (current != start);

  ret = -ENOMEM;
  LOG_WARNING("Next-fit allocation failed: "
              "Req size: %zu | Start block: %p. "
              "Error code: %d.\n",
              size,
              (void *)start,
              ret);

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
static int MEM_findBestFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **best_fit)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = NULL;

  size_t iterator = 0u;

  int start_class = 0;

  if (UNLIKELY(allocator == NULL || best_fit == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator %p | best_fit %p"
              "Error code: %d.\n",
              (void *)allocator,
              (void *)best_fit,
              ret);
    goto function_output;
  }

  *best_fit = NULL;

  start_class = MEM_getSizeClass(allocator, size);
  if (start_class < 0)
  {
    ret = -ENOMEM;
    goto function_output;
  }

  for (iterator = (size_t)start_class;
       iterator < (size_t)allocator->num_size_classes;
       iterator++)
  {
    current = allocator->free_lists[iterator];

    while (current)
    {
      ret = MEM_validateBlock(allocator, current);
      if ((ret == EXIT_SUCCESS) && (current->free && current->size >= size))
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
  LOG_WARNING("Best-fit allocation failed: "
              "Req size: %zu | Max checked class: %zu. "
              "Error code: %d.\n",
              size,
              (allocator->num_size_classes - 1),
              ret);

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
                          block_header_t *const  block,
                          const size_t           req_size)
{
  int ret = EXIT_SUCCESS;

  block_header_t *new_block = NULL;

  size_t aligned_size   = 0u;
  size_t total_size     = 0u;
  size_t remaining_size = 0u;

  if (UNLIKELY(allocator == NULL || block == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator %p | block %p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  ret = MEM_validateBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  aligned_size = ALIGN(req_size);
  total_size
    = (size_t)(aligned_size + sizeof(block_header_t) + sizeof(uint32_t));

  if (block->size < total_size + MIN_BLOCK_SIZE)
  {
    block->free = 0u;

    ret = MEM_removeFreeBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
      goto function_output;

    LOG_DEBUG("Using full block %p | Req size: %zu | Block size: %zu.\n",
              (void *)block,
              req_size,
              block->size);

    goto function_output;
  }

  remaining_size = (size_t)(block->size - total_size);

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  block->size   = total_size;
  block->free   = 0u;
  block->magic  = MAGIC_NUMBER;
  block->canary = CANARY_VALUE;

  *(uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t))
    = CANARY_VALUE;

  new_block = (block_header_t *)((uint8_t *)block + total_size);

  new_block->magic    = MAGIC_NUMBER;
  new_block->size     = remaining_size;
  new_block->free     = 1u;
  new_block->marked   = 0u;
  new_block->file     = NULL;
  new_block->line     = 0ull;
  new_block->var_name = NULL;
  new_block->prev     = block;
  new_block->next     = block->next;

  if (block->next)
    block->next->prev = new_block;

  block->next = new_block;

  new_block->canary = CANARY_VALUE;

  *(uint32_t *)((uint8_t *)new_block + new_block->size - sizeof(uint32_t))
    = CANARY_VALUE;

  new_block->fl_next = NULL;
  new_block->fl_prev = NULL;

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = MEM_insertFreeBlock(allocator, new_block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  LOG_DEBUG("Block split | Original: %p (%zu bytes) | New: %p (%zu bytes).\n",
            (void *)block,
            block->size,
            (void *)new_block,
            new_block->size);

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
                           block_header_t        *block)
{
  int ret = EXIT_SUCCESS;

  uint8_t *next_addr = NULL;

  block_header_t *next_block = NULL;
  block_header_t *prev_block = NULL;

  uint32_t *canary_ptr = NULL;

  if (UNLIKELY(allocator == NULL || block == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator=%p, block=%p. "
              "Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = MEM_validateBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  next_addr = (uint8_t *)((uint8_t *)block + block->size);
  if (next_addr + sizeof(block_header_t) <= allocator->heap_end)
  {
    next_block = (block_header_t *)next_addr;

    ret = MEM_validateBlock(allocator, next_block);
    if (ret == EXIT_SUCCESS && next_block->free)
    {
      LOG_DEBUG("Merging blocks: current payload=%p (%zu bytes) |"
                "next payload=%p (%zu bytes).\n",
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size,
                (void *)((uint8_t *)next_block + sizeof(block_header_t)),
                next_block->size);

      ret = MEM_removeFreeBlock(allocator, next_block);
      if (ret != EXIT_SUCCESS)
        goto function_output;

      block->size += next_block->size;
      block->next  = next_block->next;

      if (next_block->next)
        next_block->next->prev = block;

      canary_ptr
        = (uint32_t *)(((uint8_t *)block + block->size - sizeof(uint32_t)));
      *canary_ptr = CANARY_VALUE;
      LOG_DEBUG("New merged: payload=%p (%zu bytes.\n",
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size);
    }
  }

  prev_block = block->prev;
  if (prev_block)
  {
    ret = MEM_validateBlock(allocator, prev_block);
    if (ret == EXIT_SUCCESS && prev_block->free)
    {
      LOG_DEBUG("Merging blocks: current payload=%p (%zu bytes) |"
                "current ext payload=%p (%zu bytes).\n",
                (void *)((uint8_t *)prev_block + sizeof(block_header_t)),
                prev_block->size,
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size);

      MEM_removeFreeBlock(allocator, prev_block);
      if (ret != EXIT_SUCCESS)
        goto function_output;

      prev_block->size += block->size;
      prev_block->next  = block->next;

      if (block->next)
        block->next->prev = prev_block;

      canary_ptr  = (uint32_t *)(((uint8_t *)prev_block + prev_block->size
                                 - sizeof(uint32_t)));
      *canary_ptr = CANARY_VALUE;

      block = prev_block;
      LOG_DEBUG("New merged: payload=%p (%zu bytes.\n",
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size);
    }
  }

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = MEM_insertFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

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
static void *MEM_allocatorMalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
{
  void *user_ptr = NULL;

  mem_arena_t    *arena = NULL;
  block_header_t *block = NULL;

  void *old_brk  = NULL;
  void *raw_mmap = NULL;

  size_t total_size = 0u;

  uint32_t *data = NULL;

  int ret = EXIT_SUCCESS;

  const find_fn_t find_fns[] = {
    [FIRST_FIT] = MEM_findFirstFit,
    [NEXT_FIT]  = MEM_findNextFit,
    [BEST_FIT]  = MEM_findBestFit,
  };

  if (UNLIKELY(allocator == NULL || size <= 0))
  {
    user_ptr = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: allocator=%p | size=%zu. "
              "Error code: %d.\n",
              (void *)allocator,
              size,
              (int)(intptr_t)user_ptr);
    goto null_pointer;
  }

  total_size = ALIGN(size) + sizeof(block_header_t) + sizeof(uint32_t);
  arena      = &allocator->arenas[0];

  if (size > MMAP_THRESHOLD)
  {
    raw_mmap = MEM_mapAlloc(allocator, total_size);
    if (raw_mmap == NULL)
    {
      user_ptr = PTR_ERR(-ENOMEM);
      LOG_ERROR("Mmap failed: grow heap by %zu bytes. "
                "Error code: %d.\n",
                total_size,
                (int)(intptr_t)user_ptr);
      goto function_output;
    }

    block         = (block_header_t *)raw_mmap;
    block->magic  = MAGIC_NUMBER;
    block->size   = total_size;
    block->free   = 0;
    block->marked = 0;
    block->next   = NULL;
    block->prev   = NULL;
    block->canary = CANARY_VALUE;

    data  = (uint32_t *)((uint8_t *)raw_mmap + total_size - sizeof(uint32_t));
    *data = CANARY_VALUE;

    block->file     = file;
    block->line     = (uint64_t)line;
    block->var_name = var_name;

    LOG_INFO("Mmap used for alloc: %p (%zu bytes).\n", raw_mmap, size);
    user_ptr = (uint8_t *)raw_mmap + sizeof(block_header_t);

    goto function_output;
  }

  ret = find_fns[strategy](allocator, total_size, &block);
  if (ret == -ENOMEM)
  {
    old_brk = MEM_growUserHeap(allocator, (intptr_t)total_size);
    if ((intptr_t)old_brk < 0)
    {
      user_ptr = PTR_ERR(-ENOMEM);
      LOG_ERROR("Heap grow failed: requested %zu bytes, old_brk=%ld. "
                "Error code: %d.\n",
                total_size,
                (long)old_brk,
                (int)(intptr_t)user_ptr);
      goto function_output;
    }

    block         = (block_header_t *)old_brk;
    block->magic  = MAGIC_NUMBER;
    block->size   = total_size;
    block->free   = 1;
    block->marked = 0;
    block->next   = NULL;
    block->prev   = NULL;
    block->canary = CANARY_VALUE;

    data  = (uint32_t *)((uint8_t *)block + total_size - sizeof(uint32_t));
    *data = CANARY_VALUE;

    block->fl_prev = block->fl_next = NULL;
    ret                             = MEM_removeFreeBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
      goto function_output;

    ret = MEM_insertFreeBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
      goto function_output;

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

  ret = MEM_splitBlock(allocator, block, size);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  block->file     = file;
  block->line     = (uint64_t)line;
  block->var_name = var_name;

  user_ptr = (void *)((uint8_t *)block + sizeof(block_header_t));

function_output:

#ifdef RUNNING_ON_VALGRIND
  VALGRIND_MEMPOOL_ALLOC(allocator,
                         user_ptr,
                         block ? (block->size - sizeof(block_header_t)
                                  - sizeof(uint32_t))
                               : 0);
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
static void *MEM_allocatorRealloc(mem_allocator_t *const      allocator,
                                  void *const                 ptr,
                                  const size_t                new_size,
                                  const char *const           file,
                                  const int                   line,
                                  const char *const           var_name,
                                  const allocation_strategy_t strategy)
{
  int ret = EXIT_SUCCESS;

  void *new_ptr = NULL;

  block_header_t *old_block = NULL;

  size_t old_size = 0u;

  if (UNLIKELY(allocator == NULL || new_size <= 0))
  {
    new_ptr = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: allocator=%p | size=%zu. "
              "Error code: %d.\n",
              (void *)allocator,
              new_size,
              (int)(intptr_t)new_ptr);
    goto function_output;
  }

  if (ptr == NULL)
  {
    new_ptr
      = MEM_allocatorMalloc(allocator, new_size, file, line, var_name, strategy);
    goto function_output;
  }

  old_block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
  ret       = MEM_validateBlock(allocator, old_block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  old_size
    = (size_t)(old_block->size - sizeof(block_header_t) - sizeof(uint32_t));
  if (old_size >= new_size)
  {
    LOG_DEBUG("Reallocation not needed: "
              "Addr: %p | Current size: %zu | New size: %zu.\n",
              ptr,
              old_size,
              new_size);
    new_ptr = ptr;
    goto function_output;
  }

  new_ptr
    = MEM_allocatorMalloc(allocator, new_size, file, line, var_name, strategy);
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

    LOG_INFO("Reallocated: Old: %p (%zu bytes) | New: %p (%zu bytes).\n",
             ptr,
             old_size,
             new_ptr,
             new_size);
  }

function_output:
  return new_ptr;
}

/** ============================================================================
 *  @fn         MEM_allocatorCalloc
 *  @brief      Allocates and zero-initializes memory
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  size        Element size
 *  @param[in]  file        Source file name
 *  @param[in]  line        Source line number
 *  @param[in]  var_name    Variable name for tracking
 *  @param[in]  strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 * ========================================================================== */
static void *MEM_allocatorCalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
{
  void *ptr = NULL;

  block_header_t *block = NULL;

  size_t data_size = 0u;

  if (UNLIKELY(allocator == NULL || size == 0))
  {
    ptr = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid arguments: allocator=%p | size=%zu. "
              "Error code: %d.\n",
              (void *)allocator,
              size,
              (int)(intptr_t)ptr);
    goto function_output;
  }

  ptr = MEM_allocatorMalloc(allocator, size, file, line, var_name, strategy);
  if (ptr == NULL)
    goto function_output;

  block     = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
  data_size = (size_t)(block->size - sizeof(block_header_t) - sizeof(uint32_t));

  MEM_memset(ptr, 0, data_size);

  LOG_DEBUG("Zero-initialized memory: addr: %p (%zu bytes).\n", ptr, size);

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
                             void *const            ptr,
                             const char *const      file,
                             const int              line,
                             const char *const      var_name)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = NULL;
  mmap_t         *map   = NULL;

  void *old = NULL;

  uint8_t *block_end = NULL;

  intptr_t delta = 0;

  size_t shrink_size = 0u;
  size_t freed_size  = 0u;

  if (UNLIKELY(allocator == NULL || ptr == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p | ptr: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ptr,
              ret);
    goto function_output;
  }

  block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
  for (map = allocator->mmap_list; map; map = map->next)
  {
    if ((void *)block == map->addr)
    {
      ret = MEM_mapFree(allocator, map->addr);
      goto function_output;
    }
  }

  block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
  ret   = MEM_validateBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  if (block->free)
  {
    ret = -EINVAL;
    LOG_ERROR("Double free on a freed block (%p). "
              "Error code: %d.\n",
              ptr,
              ret);
    goto function_output;
  }

#ifdef RUNNING_ON_VALGRIND
  VALGRIND_MEMPOOL_FREE(allocator, ptr);
#endif

  block->free     = 1u;
  block->marked   = 0u;
  block->file     = file;
  block->line     = (uint64_t)line;
  block->var_name = var_name;

  ret = MEM_mergeBlocks(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  block_end = (uint8_t *)block + block->size;
  if (block_end == allocator->heap_end)
  {
    shrink_size = block->size;

    ret = MEM_removeFreeBlock(allocator, block);
    if (ret != EXIT_SUCCESS)
      goto function_output;

    delta = -(intptr_t)shrink_size;
    LOG_INFO("Shrinking heap by %zu bytes.\n", shrink_size);

    old = MEM_sbrk(delta);
    if ((intptr_t)old >= 0)
    {
      allocator->heap_end       = (uint8_t *)allocator->heap_end + delta;
      allocator->last_allocated = (block_header_t *)allocator->heap_start;

      LOG_INFO("Heap shrunk by %zu bytes. New heap_end=%p.\n",
               shrink_size,
               allocator->heap_end);

      goto function_output;
    }
  }

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret = MEM_insertFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  freed_size = (size_t)(block->size - sizeof(*block) - sizeof(uint32_t));
  LOG_INFO("Memory freed: addr: %p (%zu bytes).\n", ptr, freed_size);

function_output:
  return ret;
}

/** ============================================================================
 *      P R I V A T E  G A R B A G E  C O L L E C T O R  F U N C T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_setInitialMarks
 *  @brief      Reset mark flags across all allocated regions
 *
 *  @details    This routine walks through every block in the heap area,
 *              clearing its “marked” flag to prepare for a fresh GC cycle.
 *              It then iterates the list of memory-mapped regions (mmap_list),
 *              also clearing each payload block’s mark, but explicitly
 *              setting the metadata header for those mmap regions to “marked”
 *              so that the allocator’s own bookkeeping blocks are never freed.
 *
 *  @param[in]  allocator   Pointer to the allocator context
 *  @return     EXIT_SUCCESS on success, or -EINVAL if the allocator is NULL
 * ========================================================================== */
static int MEM_setInitialMarks(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = NULL;

  block_header_t *meta_data = NULL;
  mmap_t         *map       = NULL;

  uintptr_t heap_ptr   = 0u;
  uintptr_t heap_start = 0u;
  uintptr_t heap_end   = 0u;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  heap_start = (uintptr_t)allocator->heap_start + allocator->metadata_size;
  heap_end   = (uintptr_t)allocator->heap_end;

  heap_ptr = heap_start;
  while (heap_ptr < heap_end)
  {
    block = (block_header_t *)heap_ptr;
    if (block->size >= sizeof(block_header_t)
        && (heap_ptr + block->size) <= heap_end)
    {
      block->marked  = 0u;
      heap_ptr      += block->size;
    }
    else
    {
      heap_ptr += sizeof(block_header_t);
    }
  }

  for (map = allocator->mmap_list; map; map = map->next)
  {
    block         = (block_header_t *)map->addr;
    block->marked = 0u;

    meta_data = (block_header_t *)((uint8_t *)map - sizeof(block_header_t));
    meta_data->marked = 1u;
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @fn         MEM_gcMark
 *  @brief      Mark all live blocks reachable from the stack
 *
 *  @details    1. Calls MEM_setInitialMarks to clear previous marks.
 *              2. Optionally informs Valgrind to treat the stack region as defined.
 *              3. Ensures stack_bottom ≤ stack_top by swapping if needed.
 *              4. Scans each word on the application stack:
 *                   – If the word’s value falls within the heap bounds,
 *                     locates the corresponding block header.
 *                   – Verifies that the reference points inside the payload area
 *                     (between header end and footer).
 *                   – If valid and the block is not free, sets its mark bit.
 *                   – Logs each block that becomes marked.
 *              5. Repeats the same check against each mmap’d region,
 *                 marking those blocks whose payload contains the reference.
 *
 *  @param[in]  allocator   Pointer to the allocator context
 *  @return     EXIT_SUCCESS on success, or negative error code on failure
 * ========================================================================== */
static int MEM_gcMark(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = NULL;

  block_header_t *block = NULL;

  mmap_t *map = NULL;

  volatile uintptr_t *stack_ptr   = NULL;
  void               *stack_frame = NULL;

  uintptr_t *stack_tmp    = NULL;
  uintptr_t *stack_bottom = NULL;
  uintptr_t *stack_top    = NULL;

  uintptr_t heap_start = 0u;
  uintptr_t heap_end   = 0u;

  uintptr_t block_addr    = 0u;
  uintptr_t payload_start = 0u;
  uintptr_t payload_end   = 0u;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  gc_thread = &allocator->gc_thread;
  ret       = MEM_stackBounds(gc_thread->main_thread, allocator);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  heap_start = (uintptr_t)allocator->heap_start + allocator->metadata_size;
  heap_end   = (uintptr_t)allocator->heap_end;

  stack_bottom = allocator->stack_bottom;
  stack_top    = allocator->stack_top;

#ifdef RUNNING_ON_VALGRIND
  VALGRIND_MAKE_MEM_DEFINED((void *)stack_bottom,
                            (size_t)((char *)stack_top - (char *)stack_bottom));
#endif

  MEM_setInitialMarks(allocator);

  if (stack_bottom > stack_top)
  {
    stack_tmp    = stack_bottom;
    stack_bottom = stack_top;
    stack_top    = stack_tmp;
  }

  for (stack_ptr = stack_bottom; stack_ptr < stack_top; ++stack_ptr)
  {
    stack_frame = (void *)(*stack_ptr);
    if (stack_frame != NULL)
    {
      block_addr = (uintptr_t)stack_frame;
      heap_end   = (uintptr_t)allocator->heap_end;

      if (block_addr >= heap_start && block_addr < heap_end)
      {
        block = (block_header_t *)(block_addr - sizeof(block_header_t));

        payload_start = (uintptr_t)block + sizeof(*block);
        payload_end   = (uintptr_t)block + block->size - sizeof(uint32_t);

        ret = MEM_validateBlock(allocator, block);
        if (block_addr >= payload_start && block_addr < payload_end
            && ret == EXIT_SUCCESS && !block->free)
        {
          block->marked = 1u;
          LOG_INFO("Block Marked(sbrk): %p (%zu bytes). "
                   "stack = %lu.\n",
                   (void *)((uint8_t *)block + sizeof(block_header_t)),
                   block->size,
                   (unsigned long)stack_ptr);
        }
        else
        {
          block->marked = 0u;
          ret           = EXIT_SUCCESS;
        }
      }

      for (map = allocator->mmap_list; map; map = map->next)
      {
        block = (block_header_t *)map->addr;

        payload_start = (uintptr_t)map->addr + sizeof(*block);
        payload_end   = (uintptr_t)map->addr + map->size - sizeof(uint32_t);

        if (block_addr >= payload_start && block_addr < payload_end
            && !block->free)
        {
          block->marked = 1;
          LOG_INFO("Block Marked(sbrk): %p (%zu bytes).\n",
                   (void *)((uint8_t *)block + sizeof(block_header_t)),
                   block->size);
          break;
        }
        else
        {
          ret = EXIT_SUCCESS;
        }
      }
    }
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @fn         MEM_gcSweep
 *  @brief      Reclaim any unmarked blocks from heap and mmap regions
 *
 *  @details    1. Iterates the heap sequentially:
 *                   – Reads each block’s size and flags.
 *                   – Logs its current free/marked status.
 *                   – If the block is allocated (free==0) but unmarked,
 *                     invokes MEM_allocatorFree on its payload pointer,
 *                     marks it free, and logs the action.
 *                   – In all cases, clears the block’s mark flag.
 *                   – Advances by the block’s size (or header size on corruption).
 *              2. Traverses the mmap_list via a pointer-to-pointer scan:
 *                   – Logs each region’s status.
 *                   – If unmarked and not already free, unlinks the node,
 *                     calls munmap on the mapped area, and frees the
 *                     metadata header via MEM_allocatorFree.
 *                   – Otherwise, clears its mark and moves to the next node.
 *
 *  @param[in]  allocator   Pointer to the allocator context
 *  @return     EXIT_SUCCESS on success, or -EINVAL if allocator is NULL
 * ========================================================================== */
static int MEM_gcSweep(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = NULL;

  mmap_t  *map  = NULL;
  mmap_t **scan = NULL;

  void *user_ptr = NULL;

  uint8_t *heap_end   = NULL;
  uint8_t *heap_start = NULL;
  uint8_t *heap_ptr   = NULL;

  size_t min_size    = 0u;
  size_t remain_size = 0u;
  size_t step        = 0u;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  heap_start
    = (uint8_t *)((uintptr_t)allocator->heap_start + allocator->metadata_size);
  heap_end = (uint8_t *)allocator->heap_end;

  min_size = sizeof(block_header_t);

  heap_ptr = heap_start;

  while (heap_ptr < heap_end)
  {
    block = (block_header_t *)heap_ptr;

    remain_size = (size_t)(heap_end - heap_ptr);

    if (block->size >= min_size && block->size <= remain_size)
    {
      LOG_INFO("Block Sweep(sbrk): block %p (%zu bytes). "
               "free=%u | marked=%u.\n",
               (void *)((uint8_t *)block + sizeof(block_header_t)),
               block->size,
               block->free,
               block->marked);

      if (!block->free && !block->marked)
      {
        LOG_INFO("Sweep Free(sbrk): block %p (%zu bytes).\n",
                 (void *)((uint8_t *)block + sizeof(block_header_t)),
                 block->size);
        user_ptr = (uint8_t *)block + sizeof(*block);
        MEM_allocatorFree(allocator, user_ptr, __FILE__, __LINE__, "g");
        block->free = 1;
      }

      block->marked = 0U;

      step = block->size;
    }
    else
    {
      step = min_size;
    }

    heap_ptr += step;
    heap_end  = (uint8_t *)allocator->heap_end;
  }

  scan = &allocator->mmap_list;
  while (*scan)
  {
    map   = *scan;
    block = (block_header_t *)map->addr;

    LOG_INFO("Block Sweep(mmap): block %p (%zu bytes). "
             "free=%u | marked=%u.\n",
             (void *)((uint8_t *)block + sizeof(block_header_t)),
             map->size,
             block->free,
             block->marked);

    if (!block->marked && !block->free)
    {
      *scan = map->next;

      LOG_INFO("Sweep Free(mmap): block %p (%zu bytes).\n",
               (void *)((uint8_t *)block + sizeof(block_header_t)),
               map->size);

      munmap(map->addr, map->size);
      MEM_allocatorFree(allocator, map, __FILE__, __LINE__, "mmap_meta");
    }
    else
    {
      block->marked = 0;
      scan          = &map->next;
    }
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @fn         MEM_gcThreadFunc
 *  @brief      Dedicated thread loop driving mark-and-sweep iterations
 *
 *  @details    This thread waits on a condition variable until signaled to run:
 *              1. Locks its gc_lock and blocks on gc_cond while neither
 *                 “gc_running” nor “gc_exit” is true.
 *              2. On wakeup, if gc_exit is set, breaks the loop and exits.
 *              3. Releases the lock and performs one pass of:
 *                   – MEM_gcMark to mark live blocks.
 *                   – MEM_gcSweep to free unreachable blocks.
 *                 Errors in either are logged and abort the thread.
 *              4. Sleeps for the configured gc_interval before repeating.
 *              5. On exit, ensures the lock is released and returns its status.
 *
 *  @param[in]  arg     Pointer to mem_allocator_t (must not be NULL)
 *  @return     NULL on clean exit, or PTR_ERR on failure
 * ========================================================================== */
static void *MEM_gcThreadFunc(void *arg)
{
  void *ret = NULL;

  mem_allocator_t *allocator = NULL;
  gc_thread_t     *gc_thread = NULL;

  if (UNLIKELY(arg == NULL))
  {
    ret = PTR_ERR(-EINVAL);
    LOG_ERROR("Invalid parameters: arg: %p. "
              "Error code: %d.\n",
              (void *)arg,
              (int)(intptr_t)ret);
    goto function_output;
  }

  allocator = (mem_allocator_t *)arg;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);

  while (!atomic_load(&gc_thread->gc_exit))
  {
    while (!atomic_load(&gc_thread->gc_running)
           && !atomic_load(&gc_thread->gc_exit))
      pthread_cond_wait(&gc_thread->gc_cond, &gc_thread->gc_lock);

    if (atomic_load(&gc_thread->gc_exit))
      break;

    pthread_mutex_unlock(&gc_thread->gc_lock);

    ret = PTR_ERR(MEM_gcMark(allocator));
    if (ret != PTR_ERR(EXIT_SUCCESS))
      goto function_output;

    ret = PTR_ERR(MEM_gcSweep(allocator));
    if (ret != PTR_ERR(EXIT_SUCCESS))
      goto function_output;

    usleep(gc_thread->gc_interval_ms * NR_OBJS);

    pthread_mutex_lock(&gc_thread->gc_lock);
  }

function_output:
  pthread_mutex_unlock(&gc_thread->gc_lock);
  return ret;
}

/** ============================================================================
 *  @fn         MEM_runGc
 *  @brief      Start or signal the GC thread to perform a collection cycle
 *
 *  @details    - Captures the main thread’s stack bounds for later marking.
 *              - If the GC thread has not been started:
 *                   * Marks gc_thread_started, sets gc_running and gc_exit flags.
 *                   * Creates the GC thread running MEM_gcThreadFunc.
 *                Otherwise:
 *                   * Sets gc_running and signals gc_cond to wake the thread.
 *
 *  @param[in]  allocator   Pointer to the allocator context
 *  @return     EXIT_SUCCESS, or negative error code on failure
 * ========================================================================== */
static int MEM_runGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = NULL;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  gc_thread              = &allocator->gc_thread;
  gc_thread->main_thread = pthread_self( );

  pthread_mutex_lock(&gc_thread->gc_lock);
  if (!gc_thread->gc_thread_started)
  {
    gc_thread->gc_thread_started = 1u;
    atomic_store(&gc_thread->gc_running, true);
    atomic_store(&gc_thread->gc_exit, false);

    ret
      = pthread_create(&gc_thread->gc_thread, NULL, MEM_gcThreadFunc, allocator);
    if (ret != EXIT_SUCCESS)
    {
      LOG_ERROR("Failed to create gc thread: %p. "
                "Error code: %d.\n",
                (void *)gc_thread->gc_thread,
                ret);
      goto function_output;
    }
  }
  else
  {
    atomic_store(&gc_thread->gc_running, true);
    pthread_cond_signal(&gc_thread->gc_cond);
  }
  pthread_mutex_unlock(&gc_thread->gc_lock);

function_output:
  return ret;
}

/** ============================================================================
 *  @fn         MEM_stopGc
 *  @brief      Stop the GC thread and perform a final collection
 *
 *  @details    - Sets gc_running to false and gc_exit to true.
 *              - If the thread is active:
 *                   * Signals gc_cond to wake it up.
 *                   * Joins the thread (waits for its termination).
 *                   * Runs one last MEM_gcMark + MEM_gcSweep cycle on the
 *                     calling thread to clean up any remaining garbage.
 *                   * Resets gc_thread_started flag.
 *
 *  @param[in]  allocator   Pointer to the allocator context
 *  @return     EXIT_SUCCESS, or negative error code on failure
 * ========================================================================== */
static int MEM_stopGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = NULL;

  if (UNLIKELY(allocator == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: allocator: %p. "
              "Error code: %d.\n",
              (void *)allocator,
              ret);
    goto function_output;
  }

  gc_thread = &allocator->gc_thread;

  atomic_store(&gc_thread->gc_running, false);
  atomic_store(&gc_thread->gc_exit, true);

  if (gc_thread->gc_thread_started)
  {
    pthread_cond_signal(&gc_thread->gc_cond);
    pthread_join(gc_thread->gc_thread, NULL);

    ret = MEM_gcMark(allocator);
    if (ret != EXIT_SUCCESS)
      goto function_output;

    ret = MEM_gcSweep(allocator);
    if (ret != EXIT_SUCCESS)
      goto function_output;

    gc_thread->gc_thread_started = 0u;
  }

function_output:
  return ret;
}

/** ============================================================================
 *          P U B L I C  F U N C T I O N S  D E F I N I T I O N S
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
void *MEM_allocMallocFirstFit(mem_allocator_t *const allocator,
                              const size_t           size,
                              const char *const      var)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret
    = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, FIRST_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
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
void *MEM_allocMallocBestFit(mem_allocator_t *const allocator,
                             const size_t           size,
                             const char *const      var)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, BEST_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
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
void *MEM_allocMallocNextFit(mem_allocator_t *const allocator,
                             const size_t           size,
                             const char *const      var)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, NEXT_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
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
void *MEM_allocMalloc(mem_allocator_t *const      allocator,
                      const size_t                size,
                      const char *const           var,
                      const allocation_strategy_t strategy)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, strategy);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

/** ============================================================================
 *  @fn         MEM_allocCalloc
 *  @brief      Allocates and zero-initializes memory using a specified strategy.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  size        Size of each element.
 *  @param[in]  var         Variable name (for debugging).
 *  @param[in]  strategy    Allocation strategy to use.
 *
 *  @return     Pointer to allocated and zero-initialized memory or NULL on failure.
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
void *MEM_allocCalloc(mem_allocator_t *const      allocator,
                      const size_t                size,
                      const char *const           var,
                      const allocation_strategy_t strategy)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorCalloc(allocator, size, __FILE__, __LINE__, var, strategy);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
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
void *MEM_allocRealloc(mem_allocator_t *const      allocator,
                       void *const                 ptr,
                       const size_t                new_size,
                       const char *const           var,
                       const allocation_strategy_t strategy)
{
  void *ret = NULL;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorRealloc(allocator,
                             ptr,
                             new_size,
                             __FILE__,
                             __LINE__,
                             var,
                             strategy);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
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
int MEM_allocFree(mem_allocator_t *const allocator,
                  void *const            ptr,
                  const char *const      var)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorFree(allocator, ptr, __FILE__, __LINE__, var);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
int MEM_enableGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  ret = MEM_runGc(allocator);

  return ret;
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
int MEM_disableGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  ret = MEM_stopGc(allocator);

  return ret;
}

/*< end of file >*/
