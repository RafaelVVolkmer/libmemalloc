/** ============================================================================
 *  @addtogroup Libmemalloc
 *  @{
 *
 *  @brief      Core memory management components for libmemalloc.
 *
 *  @file       libmemalloc.h
 *
 *  @details    Implements memory allocator with advanced features:
 *              - Architecture-specific stack allocation (alloca)
 *              - Garbage collection (mark & sweep)
 *              - Multiple allocation strategies (First/Best/Next Fit)
 *
 *  @version    v4.0.00
 *  @date       26.06.2025
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
#include <stdint.h>
#include <string.h>

/** ============================================================================
 *              P U B L I C  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        ARCH_ALIGNMENT
 *  @brief      Defines architecture-specific memory alignment.
 *
 *  @details    Determines the appropriate memory alignment based
 *              on the current target architecture.
 * ========================================================================== */
#if defined(__x86_64__) || defined(_M_X64)
  #define ARCH_ALIGNMENT ((uint8_t)8U) /**< x86_64 (CISC 64 bits) */
#elif defined(__i386__) || defined(_M_IX86)
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< x86 (CISC 32 bits) */
#elif defined(__aarch64__) || defined(_M_ARM64)
  #define ARCH_ALIGNMENT ((uint8_t)8U) /**< ARM (64 bits) */
#elif defined(__arm__) || defined(_M_ARM)
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< ARM (32 bits) */
#elif defined(__riscv) && (__riscv_xlen == 64)
  #define ARCH_ALIGNMENT ((uint8_t)8U) /**< RISC-V (64 bits) */
#elif defined(__riscv) && (__riscv_xlen == 32)
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< RISC-V (32 bits) */
#elif defined(__powerpc64__)
  #define ARCH_ALIGNMENT ((uint8_t)8U) /**< PowerPC (64 bits) */
#elif defined(__powerpc__)
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< PowerPC (32 bits) */
#elif defined(__TI_PRU__) || defined(__PRU__)
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< TI PRU (32 bits) */
#elif defined(__AVR__)
  #define ARCH_ALIGNMENT ((uint8_t)2U) /**< AVR (8 bits) */
#else
  #define ARCH_ALIGNMENT ((uint8_t)4U) /**< Fallback */
#endif

/** ============================================================================
 *  @def        LIBMEMALLOC_API
 *  @brief      Defines the default visibility attribute
 *              for exported symbols.
 *
 *  @details    When using GCC or compatible compilers, this macro
 *              expands to __attribute__((visibility("default")))
 *              to ensure that symbols are exported (visible)
 *              in the resulting shared library (.so).
 *              For compilers that do not support this attribute,
 *              it expands to nothing.
 * ========================================================================== */
#if defined(_WIN32)
  #ifdef BUILDING_LIBMEMALLOC
    #define __LIBMEMALLOC_API __declspec(dllexport)
  #else
    #define __LIBMEMALLOC_API __declspec(dllimport)
  #endif
#elif defined(__GNUC__)
  #define __LIBMEMALLOC_API __attribute__((visibility("default")))
#else
  #define __LIBMEMALLOC_API
#endif

/** ============================================================================
 *  @def        LIBMEMALLOC_MALLOC
 *  @brief      Annotates allocator functions that return
 *              newly allocated memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((malloc, alloc_size(2),
 *              warn_unused_result)) which tells the compiler
 *              the function behaves like malloc, that the 2nd
 *              parameter is the allocation size, and that the
 *              return value should not be ignored. Otherwise,
 *              expands to nothing.
 * ========================================================================== */
#if defined(__GNUC__)
  #define __LIBMEMALLOC_MALLOC \
    __attribute__((malloc, alloc_size(2), warn_unused_result))
#else
  #define __LIBMEMALLOC_MALLOC
#endif

/** ============================================================================
 *  @def        LIBMEMALLOC_REALLOC
 *  @brief      Annotates reallocator functions that may return
 *              a pointer to resized memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((alloc_size(3),
 *              warn_unused_result)) which tells the compiler
 *              that the 3rd parameter specifies the new size
 *              of the allocation and that the return value
 *              should not be ignored. Otherwise, expands to nothing.
 * ========================================================================== */
#if defined(__GNUC__)
  #define __LIBMEMALLOC_REALLOC \
    __attribute__((malloc, alloc_size(3), warn_unused_result))
#else
  #define __LIBMEMALLOC_REALLOC
#endif

/** ============================================================================
 *  @def        __PACKED
 *  @brief      Defines packed structure attribute with alignment.
 *
 *  @details    When using GCC or Clang, expands to
 *              __attribute__((packed, aligned(ARCH_ALIGNMENT))) to ensure
 *              minimal padding in structures while enforcing the architecture-
 *              specific alignment. On compilers that do not support this
 *              attribute, expands to nothing.
 * ========================================================================== */
#ifndef __PACKED
  #if defined(__GNUC__)
    #define __PACKED __attribute__((packed, aligned(ARCH_ALIGNMENT)))
  #else
    #define __PACKED
  #endif
#endif

/** ============================================================================
 *  @def        __PACKED
 *  @brief      Defines packed structure attribute with alignment.
 *
 *  @details    When using GCC or Clang, expands to
 *              __attribute__((packed, aligned(ARCH_ALIGNMENT))) to ensure
 *              minimal padding in structures while enforcing the architecture-
 *              specific alignment. On compilers that do not support this
 *              attribute, expands to nothing.
 * ========================================================================== */
#ifndef __PACKED
  #if defined(__GNUC__)
    #define __PACKED __attribute__((packed, aligned(ARCH_ALIGNMENT)))
  #else
    #define __PACKED
  #endif
#endif

/** ============================================================================
 *  @def        PTR_ERR
 *  @brief      Encodes a negative error code as an error pointer.
 *
 *  @param[in]  x   Integer error code (negative errno value).
 *
 *  @return     A pointer whose value encodes the error code.
 *              To test and extract the code, use IS_ERR() and
 *              (intptr_t)ptr respectively.
 * ========================================================================== */
#define PTR_ERR(x)     ((void *)((intptr_t)(x)))

/** ============================================================================
 *  @def        ALIGN(x)
 *  @brief      Aligns a given value to the nearest memory boundary.
 *
 *  @param [in] x  Value to be aligned.
 *
 *  @details    Uses bitwise operations to align the value to the
 *              nearest multiple of the current architecture's alignment.
 * ========================================================================== */
#define ALIGN(x)       (((x) + (ARCH_ALIGNMENT - 1U)) & ~(ARCH_ALIGNMENT - 1U))

/** ============================================================================
 *  @def        DEFAULT_GC_INTERVAL_MS
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
 * ========================================================================== */
typedef enum AllocationStrategy
{
  FIRST_FIT = (uint8_t)(0u), /**< First available block allocation */
  NEXT_FIT  = (uint8_t)(1u), /**< Continue from last allocation */
  BEST_FIT  = (uint8_t)(2u)  /**< Smallest block fitting the request */
} allocation_strategy_t;

/** ============================================================================
 *  @struct     BlockHeader
 *  @typedef    block_header_t
 *  @brief      Represents the header for a memory block.
 *
 *  @details    This structure manages metadata for each block
 *              within the heap, including size, status, and
 *              debugging information.
 * ========================================================================== */
typedef struct __PACKED BlockHeader
{
  uint32_t magic;  /**< Magic number for integrity check */

  size_t size;     /**< Total block size (includes header, data, and canary) */

  uint32_t free;   /**< 1 if block is free, 0 if allocated */
  uint32_t marked; /**< Garbage collector mark flag */

  const char        *var_name; /**< Variable name (for debugging) */
  const char        *file;     /**< Source file of allocation (for debugging) */
  unsigned long long line;     /**< Line number of allocation (for debugging) */

  uint32_t canary;          /**< Canary value for buffer overflow detection */

  struct BlockHeader *next; /**< Pointer to the next block */
  struct BlockHeader *prev; /**< Pointer to the previous block */

  struct BlockHeader *fl_next; /**< Pointer to the next block on free list */
  struct BlockHeader *fl_prev; /**< Pointer to the previous block on free list */
} block_header_t;

/** ============================================================================
 *  @struct     MemArena
 *  @typedef    mem_arena_t
 *  @brief      Represents a memory arena with its own free lists.
 *
 *  @details    This structure manages a group of free lists (bins)
 *              and tracks the top chunk in the heap for allocation
 *              strategies like top chunk extension. Each arena can
 *              hold multiple size classes to optimize allocation
 *              and minimize fragmentation.
 * ========================================================================== */
typedef struct __PACKED MemArena
{
  block_header_t **bins; /**< Array of free lists (one per size class). */
  block_header_t
    *top_chunk;    /**< Top free block in the heap (for fast extension). */

  size_t num_bins; /**< Number of size classes (bins) managed by this arena. */
} mem_arena_t;

/** ============================================================================
 *  @struct     MmapBlock
 *  @typedef    mmap_t
 *  @brief      Tracks memory-mapped regions for large allocations.
 *
 *  @details    Each node records the base address and size of
 *              an mmap() allocation, forming a linked list
 *              maintained by the allocator.
 * ========================================================================== */
typedef struct __PACKED MmapBlock
{
  void             *addr; /**< Base address returned by mmap(). */
  size_t            size; /**< Total mapped region size (rounded to pages). */
  struct MmapBlock *next; /**< Next region in allocator's mmap list. */
} mmap_t;

/** ============================================================================
 *  @struct     GcThread
 *  @typedef    gc_thread_t
 *  @brief      Orchestrates the background mark-and-sweep garbage collector.
 *
 *  @details    The structure encapsulates all state and
 *              synchronization needed to run the garbage collector in its own
 *              thread. Once started, the GC thread will periodically wake up,
 *              scan the heap and any mapped regions for unreachable objects,
 *              reclaim them, and then sleep again. The structure holds the
 *              timing parameters, the thread handle, and the primitives used
 *              to signal the collector to start or stop its work.
 * ========================================================================== */
typedef struct __PACKED GcThread
{
  pthread_t gc_thread;    /**< Handle to the GC pthread */
  pthread_t main_thread;

  atomic_bool gc_running; /**< Whether the GC thread is active and should run */
  atomic_bool gc_exit;    /**< Signal for the GC thread to exit */

  uint32_t gc_interval_ms; /**< Interval between GC cycles, in milliseconds */
  uint16_t
    gc_thread_started; /**< Flag indicating the GC thread has been created */

  pthread_cond_t  gc_cond; /**< Condition variable to signal GC thread */
  pthread_mutex_t gc_lock; /**< Mutex for synchronizing GC start/stop */
} gc_thread_t;

/** ============================================================================
 *  @struct     MemoryAllocator
 *  @typedef    mem_allocator_t
 *  @brief      Manages dynamic memory allocation.
 *
 *  @details    This structure manages the heap, including free
 *              lists for memory blocks, garbage collection, and
 *              allocation strategies.
 * ========================================================================== */
typedef struct __PACKED MemoryAllocator
{
  uint8_t *heap_start;            /**< Base of the user heap region */
  uint8_t *heap_end;              /**< Current end of the heap */
  size_t   metadata_size;         /**< Bytes reserved for bins and arenas */

  uintptr_t *stack_top;           /**< Upper bound of application stack */
  uintptr_t *stack_bottom;        /**< Lower bound of application stack */

  block_header_t *last_allocated; /**< Last block returned (NEXT_FIT) */

  size_t       num_size_classes;  /**< Total size classes available */
  size_t       num_arenas;        /**< Number of arena partitions */
  mem_arena_t *arenas;            /**< Array of arena metadata */

  mmap_t          *mmap_list;     /**< Linked list of mmap’d regions */
  block_header_t **free_lists;    /**< Segregated free lists by size class */

  gc_thread_t gc_thread;          /**< Garbage collector controller */
} mem_allocator_t;

/** ============================================================================
 *          P U B L I C  F U N C T I O N S  P R O T O T Y P E S
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
__LIBMEMALLOC_API void *MEM_memset(void *const  source,
                                   const int    value,
                                   const size_t size);

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
__LIBMEMALLOC_API void *MEM_memcpy(void *const  dest,
                                   const void  *src,
                                   const size_t size);

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
__LIBMEMALLOC_API int MEM_allocatorInit(mem_allocator_t *const allocator);

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
__LIBMEMALLOC_API void *MEM_allocMallocFirstFit(mem_allocator_t *const allocator,
                                                const size_t      size,
                                                const char *const var)
  __LIBMEMALLOC_MALLOC;

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
__LIBMEMALLOC_API void *MEM_allocMallocBestFit(mem_allocator_t *const allocator,
                                               const size_t           size,
                                               const char *const      var)
  __LIBMEMALLOC_MALLOC;

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
__LIBMEMALLOC_API void *MEM_allocMallocNextFit(mem_allocator_t *const allocator,
                                               const size_t           size,
                                               const char *const      var)
  __LIBMEMALLOC_MALLOC;

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
__LIBMEMALLOC_API void *MEM_allocMalloc(mem_allocator_t *const      allocator,
                                        const size_t                size,
                                        const char *const           var,
                                        const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

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
__LIBMEMALLOC_API void *MEM_allocCalloc(mem_allocator_t *const      allocator,
                                        const size_t                size,
                                        const char *const           var,
                                        const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

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
__LIBMEMALLOC_API void *MEM_allocRealloc(mem_allocator_t *const      allocator,
                                         void *const                 ptr,
                                         const size_t                new_size,
                                         const char *const           var,
                                         const allocation_strategy_t strategy)
  __LIBMEMALLOC_REALLOC;

/** ============================================================================
 *  @fn         MEM_allocFree
 *  @brief      Releases allocated memory back to the heap.
 *
 *  @param[in]  allocator   Memory allocator context.
 *  @param[in]  ptr         Pointer to memory to free.
 *  @param[in]  var         Variable name (for debugging).
 *
 *  @return     Integer status code (SUCCESS if successful).
 *
 *  @note       Automatically passes file and line information.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_allocFree(mem_allocator_t *const allocator,
                                    void *const            ptr,
                                    const char *const      var);

/** ============================================================================
 *          G A R B A G E  C O L L E C T O R  F U N C T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         MEM_enableGc
 *  @brief      Initialize or signal the garbage collector thread to run
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_enableGc(mem_allocator_t *const allocator);

/** ============================================================================
 *  @fn         MEM_disableGc
 *  @brief      Stop the garbage collector thread and perform a final collection
 *              cycle
 *
 *  @param[in]  allocator   Pointer to the memory allocator context
 *
 *  @return     EXIT_SUCCESS (0) on success, or negative error code on failure
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_disableGc(mem_allocator_t *const allocator);

/*< C++ Compatibility >*/
#ifdef __cplusplus
}
#endif

/** @} */

/*< end of header file >*/
