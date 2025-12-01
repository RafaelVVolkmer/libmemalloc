/** ============================================================================
 *  @addtogroup Libmemalloc
 *  @{
 *
 *  @brief      Core memory management components for libmemalloc.
 *
 *  @file       libmemalloc.h
 *
 *  @details    Implements memory allocator with advanced features:
 *              - Garbage collection (mark & sweep)
 *              - Multiple allocation strategies (First/Best/Next Fit)
 *
 *  @version    v2.0.00
 *  @date       28.09.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

#pragma once

/*< C++ Compatibility >*/
#ifdef __cplusplus
extern "C"
{
#endif

/** ============================================================================
 *                      P U B L I C  I N C L U D E S
 * ========================================================================== */

/*< Dependencies >*/
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

/*< Implemented >*/
#include "memalloc_utils.h"

/** ============================================================================
 *              P U B L I C  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        GC_INTERVAL_MS
 *  @brief      Default interval in milliseconds between GC cycles.
 *
 *  @details    Defines the time (in milliseconds) the garbage collector
 *              thread sleeps between each mark-and-sweep cycle. Adjusting
 *              this value impacts how frequently memory is reclaimed versus
 *              the CPU overhead of running the GC.
 * ========================================================================== */
#define GC_INTERVAL_MS (uint16_t)(100U)

/** ============================================================================
 *              P U B L I C  S T R U C T U R E S  &  T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @enum       AllocationStrategy
 *  @typedef    allocation_strategy_t
 *  @brief      Defines allocation strategies for memory management.
 *
 *  @details    This enum specifies the available strategies for
 *              memory block allocation within the heap.
 *
 *  @par Fields:
 *    @li @b FIRST_FIT – First available block allocation
 *    @li @b NEXT_FIT – Continue from last allocation
 *    @li @b BEST_FIT – Smallest block fitting the request
 * ========================================================================== */
typedef enum AllocationStrategy
{
  FIRST_FIT = (uint8_t)(0u), /**< Allocate the first available block */
  NEXT_FIT  = (uint8_t)(1u), /**< Continue searching from the last allocation */
  BEST_FIT  = (uint8_t)(2u) /**< Use the smallest block that fits the request */
} allocation_strategy_t;

/** ============================================================================
 *  @struct  block_header_t
 *
 *  @brief   Represents the header for a memory block.
 *
 *  @details This structure manages metadata for each block
 *           within the heap, including size, status, and
 *           debugging information.
 *
 *  @par Fields:
 *    @li @b magic    – Magic number for integrity check
 *    @li @b size     – Total block size (includes header, data, and canary)
 *    @li @b free     – 1 if block is free, 0 if allocated
 *    @li @b marked   – Garbage collector mark flag
 *    @li @b var_name – Variable name (for debugging)
 *    @li @b file     – Source file of allocation (for debugging)
 *    @li @b line     – Line number of allocation (for debugging)
 *    @li @b canary   – Canary value for buffer-overflow detection
 *    @li @b next     – Pointer to the next block
 *    @li @b prev     – Pointer to the previous block
 *    @li @b fl_next  – Pointer to the next block on free list
 *    @li @b fl_prev  – Pointer to the previous block on free list
 * ========================================================================== */
typedef struct __ALIGN BlockHeader
{
  uintptr_t magic; /**< Magic number for integrity check */
  size_t    size;  /**< Total block size (includes header, data, and canary) */

  uint32_t free;   /**< 1 if block is free, 0 if allocated */
  uint32_t marked; /**< Garbage collector mark flag */

  const char *var_name;     /**< Variable name (for debugging) */
  const char *file;         /**< Source file of allocation (for debugging) */
  uint64_t    line;         /**< Line number of allocation (for debugging) */

  uintptr_t canary;         /**< Canary value for buffer-overflow detection */

  struct BlockHeader *next; /**< Pointer to the next block */
  struct BlockHeader *prev; /**< Pointer to the previous block */

  struct BlockHeader *fl_next; /**< Pointer to the next block on free list */
  struct BlockHeader
    *fl_prev; /**< Pointer to the previous block on free list */
} block_header_t;

/** ============================================================================
 *  @struct     mem_arena_t
 *  @brief      Represents a memory arena with its own free lists.
 *
 *  @details    This structure manages a group of free lists (bins)
 *              and tracks the top chunk in the heap for allocation
 *              strategies like top chunk extension. Each arena can
 *              hold multiple size classes to optimize allocation
 *              and minimize fragmentation.
 *
 *  @par Fields:
 *    @li @b bins      – Array of free lists (one per size class)
 *    @li @b top_chunk – Top free block in the heap (for fast extension)
 *    @li @b num_bins  – Number of size classes (bins) managed by this arena
 * ========================================================================== */
typedef struct __ALIGN MemArena
{
  size_t num_bins;            /**< Number of bins in this arena */

  block_header_t **bins;      /**< Array of pointers to bin heads */
  block_header_t  *top_chunk; /**< Pointer to the top (wilderness) chunk */
} mem_arena_t;

/** ============================================================================
 *  @struct     mmap_t
 *  @brief      Tracks memory-mapped regions for large allocations.
 *
 *  @details    Each node records the base address and size of
 *              an mmap() allocation, forming a linked list
 *              maintained by the allocator.
 *
 *  @par Fields:
 *    @li @b addr – Base address returned by mmap()
 *    @li @b size – Total mapped region size (rounded to pages)
 *    @li @b next – Next region in allocator’s mmap list
 * ========================================================================== */
typedef struct __ALIGN MmapBlock
{
  void  *addr;            /**< Base address returned by mmap() */
  size_t size;            /**< Total mapped region size (rounded to pages) */

  struct MmapBlock *next; /**< Next region in the allocator’s mmap list */
} mmap_t;

/** ============================================================================
 *  @struct     gc_thread_t
 *  @brief      Orchestrates the background mark-and-sweep garbage collector.
 *
 *  @details    The structure encapsulates all state and
 *              synchronization needed to run the garbage collector in its own
 *              thread. Once started, the GC thread will periodically wake up,
 *              scan the heap and any mapped regions for unreachable objects,
 *              reclaim them, and then sleep again. The structure holds the
 *              timing parameters, the thread handle, and the primitives used
 *              to signal the collector to start or stop its work.
 *
 *  @par Fields:
 *    @li @b gc_thread        – Handle to the GC pthread
 *    @li @b main_thread      – Handle to the application’s main pthread
 *    @li @b gc_running       – Whether the GC thread is active and should run
 *    @li @b gc_exit          – Signal for the GC thread to exit
 *    @li @b gc_interval_ms   – Interval between GC cycles, in milliseconds
 *    @li @b gc_thread_started – Flag indicating the GC thread has been created
 *    @li @b gc_cond          – Condition variable to signal GC thread
 *    @li @b gc_lock          – Mutex for synchronizing GC start/stop
 * ========================================================================== */
typedef struct __ALIGN GcThread
{
  pthread_t gc_thread;        /**< GC thread handle */
  pthread_t main_thread;      /**< Main thread handle */

  bool gc_running;            /**< Flag indicating GC is running */
  bool gc_exit;               /**< Flag to signal GC shutdown */

  uint16_t gc_thread_started; /**< Indicates whether GC thread has started */

  uint32_t gc_interval_ms;    /**< Interval between GC cycles (ms) */

  pthread_cond_t  gc_cond;    /**< Condition variable for GC signaling */
  pthread_mutex_t gc_lock;    /**< Mutex protecting the condition */
} gc_thread_t;

/** ============================================================================
 *  @struct     mem_allocator_t
 *  @brief      Manages dynamic memory allocation.
 *
 *  @details    This structure manages the heap, including free
 *              lists for memory blocks, garbage collection, and
 *              allocation strategies.
 *
 *  @par Fields:
 *    @li @b heap_start       – Base of the user heap region
 *    @li @b heap_end         – Current end of the heap
 *    @li @b metadata_size    – Bytes reserved for bins and arenas
 *    @li @b stack_top        – Upper bound of application stack
 *    @li @b stack_bottom     – Lower bound of application stack
 *    @li @b last_allocated   – Last block returned (NEXT_FIT)
 *    @li @b num_size_classes – Total size classes available
 *    @li @b num_arenas       – Number of arena partitions
 *    @li @b arenas           – Array of arena metadata
 *    @li @b mmap_list        – Linked list of mmap’d regions
 *    @li @b free_lists       – Segregated free lists by size class
 *    @li @b last_brk_start   – Start address of the last sbrk(+) lease
 *    @li @b last_brk_end     – End (exclusive) of the last sbrk(+) lease
 *    @li @b gc_thread        – Garbage collector controller
 * ========================================================================== */
typedef struct __ALIGN MemoryAllocator
{
  uint8_t *heap_start;             /**< Base of the user heap region */
  uint8_t *heap_end;               /**< Current end of the heap */

  size_t metadata_size;            /**< Bytes reserved for bins and arenas */

  uintptr_t *stack_top;            /**< Upper bound of application stack */
  uintptr_t *stack_bottom;         /**< Lower bound of application stack */

  size_t num_size_classes;         /**< Total size classes available */
  size_t num_arenas;               /**< Number of arena partitions */

  block_header_t  *last_allocated; /**< Last block returned (NEXT_FIT) */
  block_header_t **free_lists;     /**< Segregated free lists by size class */

  mem_arena_t *arenas;             /**< Array of arena metadata */
  mmap_t      *mmap_list;          /**< Linked list of mmap’d regions */

  uint8_t *last_brk_start; /**< Start address of the last sbrk(+) lease */
  uint8_t *last_brk_end;   /**< End (exclusive) of the last sbrk(+) lease */

  gc_thread_t gc_thread;   /**< Garbage collector controller */
} mem_allocator_t;

/** ============================================================================
 *          P U B L I C  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Fills a memory block with a specified byte value
 *          using optimized operations.
 *
 *  This function sets each byte in the given memory region to the specified
 *  value. It first advances the pointer to meet the architecture’s alignment
 *  requirements, then writes data in ARCH_ALIGNMENT-sized chunks using 64-bit
 *  stores multiplied by PREFETCH_MULT, with prefetch hints for cache lines.
 *  Any remaining bytes at the end are filled one by one.
 *
 *  @param[in]  source  Pointer to the memory block to fill.
 *  @param[in]  value   Byte value to set (0–255).
 *  @param[in]  size    Number of bytes to set.
 *
 *  @return Original source pointer on success,
 *          an error‐encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval dest:     Original Pointer on successful operation.
 *  @retval -EINVAL:  Invalid @p src or @p size.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_memset(void *const  source,
                                   const int    value,
                                   const size_t size);

/** ============================================================================
 *  @brief  Copies a memory block between buffers using optimized operations.
 *
 *  This function copies `size` bytes from the source buffer to the destination
 *  buffer. It first advances the destination pointer to meet the architecture’s
 *  alignment requirements, then copies data in ARCH_ALIGNMENT-sized chunks
 *  using 64-bit loads and stores, with prefetch hints for both source and
 *  destination cache lines. Any remaining bytes at the end are copied.
 *
 *  @param[in]  dest  Destination buffer pointer.
 *  @param[in]  src   Source buffer pointer.
 *  @param[in]  size  Number of bytes to copy.
 *
 *  @return Original dest pointer on success,
 *          an error-encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval dest:     Original Pointer on successful operation.
 *  @retval -EINVAL:  Invalid @p src or @p size.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_memcpy(void *const  dest,
                                   const void  *src,
                                   const size_t size);

/** ============================================================================
 *  @brief  Initializes the memory allocator and its internal structures.
 *
 *  This function prepares the allocator’s heap by:
 *    - Reading and aligning the initial program break to ARCH_ALIGNMENT.
 *    - Allocating the arena array and free‐list bins via MEM_growUserHeap().
 *    - Zeroing out the free‐list bins.
 *    - Initializing the allocator fields (heap_start, heap_end, free_lists).
 *    - Setting up the garbage‐collector thread state and its mutex/cond.
 *    - Capturing the current thread’s stack bounds via MEM_stackBounds().
 *    - (If under Valgrind) creating a mempool for the allocator.
 *
 *  @param[in]  allocator Pointer to a mem_allocator_t instance to initialize.
 *
 *  @return Integer status code indicating initialization result.
 *
 *  @retval EXIT_SUCCESS: Allocator initialized successfully.
 *  @retval -EINVAL:      Invalid @p allocator pointer.
 *  @retval -ENOMEM:      Heap alignment or arena/bin allocation failed.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_allocatorInit(mem_allocator_t *const allocator);

/** ============================================================================
 *              P U B L I C  F U N C T I O N  C A L L S  A P I
 * ========================================================================== */

/** ============================================================================
 *  @brief  Allocates memory using the FIRST_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  FIRST_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  var       Variable name for debugging.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocMallocFirstFit(mem_allocator_t
                                                  *const          allocator,
                                                const size_t      size,
                                                const char *const var)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the BEST_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  BEST_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  var       Variable name for debugging.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocMallocBestFit(mem_allocator_t *const allocator,
                                               const size_t           size,
                                               const char *const      var)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the NEXT_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  NEXT_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  var       Variable name for debugging.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocMallocNextFit(mem_allocator_t *const allocator,
                                               const size_t           size,
                                               const char *const      var)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested
 *  @param[in]  var       Variable name for debugging.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocMalloc(mem_allocator_t *const      allocator,
                                        const size_t                size,
                                        const char *const           var,
                                        const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates and zero‐initializes memory using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorCalloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  var       Variable name for debugging.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the allocated zeroed memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocCalloc(mem_allocator_t *const      allocator,
                                        const size_t                size,
                                        const char *const           var,
                                        const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Reallocates memory with safety checks using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorRealloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to existing memory.
 *  @param[in]  new_size  New requested size.
 *  @param[in]  var       Variable name for debugging.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the reallocated memory on success (may be same as @p
 * ptr), or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocRealloc(mem_allocator_t *const      allocator,
                                         void *const                 ptr,
                                         const size_t                new_size,
                                         const char *const           var,
                                         const allocation_strategy_t strategy)
  __LIBMEMALLOC_REALLOC;

/** ============================================================================
 *  @brief  Releases allocated memory back to the heap.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorFree() with
 *  automatically supplied __FILE__, __LINE__, and variable name for debugging,
 *  then unlocks the mutex.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to memory to free.
 *  @param[in]  var       Variable name for debugging.
 *
 *  @return EXIT_SUCCESS on success,
 *          negative error code on failure.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_allocFree(mem_allocator_t *const allocator,
                                    void *const            ptr,
                                    const char *const      var);

/** ============================================================================
 *          G A R B A G E  C O L L E C T O R  F U N C T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Start or signal the garbage collector thread.
 *
 *  This function simply wraps MEM_runGc(), starting the GC thread if needed
 *  or signaling it to perform a collection cycle.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return EXIT_SUCCESS on success,
 *          negative error code on failure.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_enableGc(mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Stop the garbage collector thread and perform a final collection.
 *
 *  This function simply wraps MEM_stopGc(), signaling the GC thread to exit,
 *  joining it, and running a final mark-and-sweep cycle on the caller thread.
 *
 *  @param[in]  allocator Memory allocator context
 *
 *  @return EXIT_SUCCESS on success,
 *          negative error code on failure.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_disableGc(mem_allocator_t *const allocator);

/*< C++ Compatibility >*/
#ifdef __cplusplus
}
#endif

/** @} */

/*< end of header file >*/
