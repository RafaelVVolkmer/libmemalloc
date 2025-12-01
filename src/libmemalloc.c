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
 *  @version    v2.0.00
 *  @date       28.09.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 *
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
#ifndef _GNU_SOURCE
  #define _GNU_SOURCE
#endif

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
#include <inttypes.h>
#include <stdbool.h>
#include <stddef.h>
#include <sys/mman.h>
#include <sys/resource.h>

#if defined(__linux__) || defined(__unix__) || defined(__APPLE__)
  #if __has_include(<valgrind/memcheck.h>)
    #include <valgrind/memcheck.h>
  #endif
#endif

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
 *  @def        CACHE_LINE_SIZE
 *  @brief      Size of the CPU cache line in bytes.
 *
 *  @details    This constant defines the cache-line size used for
 *              prefetching and alignment optimizations, ensuring memory
 *              accesses align to hardware cache boundaries for maximum
 *              performance and correctness on platforms with strict
 *              alignment requirements.
 * ========================================================================== */
#define CACHE_LINE_SIZE  (uint8_t)(64U)

/** ============================================================================
 *  @def        MAGIC_NUMBER
 *  @brief      Magic number to validate memory blocks.
 *
 *  @details    This constant is used to verify the integrity of
 *              allocated memory blocks and detect corruption.
 * ========================================================================== */
#if ARCH_ALIGNMENT == 8
  #define MAGIC_NUMBER (uintptr_t)(0xBEEFDEADBEEFDEADULL)
#elif ARCH_ALIGNMENT == 4
  #define MAGIC_NUMBER (uintptr_t)(0xBEEFDEADU)
#elif ARCH_ALIGNMENT == 1
  #define MAGIC_NUMBER (uintptr_t)(0xADU)
#else
  #error "Unsupported ARCH_ALIGNMENT for MAGIC_NUMBER"
#endif

/** ============================================================================
 *  @def        CANARY_VALUE
 *  @brief      Canary value to detect buffer overflows.
 *
 *  @details    This constant is placed at the boundaries of
 *              memory allocations to detect buffer overflows.
 * ========================================================================== */
#if ARCH_ALIGNMENT == 8
  #define CANARY_VALUE (uintptr_t)(0xDEADBEEFDEADBEEFULL)
#elif ARCH_ALIGNMENT == 4
  #define CANARY_VALUE (uintptr_t)(0xDEADBEEFUL)
#elif ARCH_ALIGNMENT == 1
  #define CANARY_VALUE (uintptr_t)(0xEF)
#else
  #error "Unsupported ARCH_ALIGNMENT for CANARY_VALUE"
#endif

/** ============================================================================
 *  @def        PREFETCH_MULT
 *  @brief      Prefetch optimization multiplier constant
 *
 *  @details    Repeating-byte pattern used for efficient memory block
 *              operations. Faz stores de largura igual a ARCH_ALIGNMENT.
 * ========================================================================== */
#if ARCH_ALIGNMENT == 8
  #define PREFETCH_MULT (uintptr_t)(0x0101010101010101ULL)
#elif ARCH_ALIGNMENT == 4
  #define PREFETCH_MULT (uintptr_t)(0x01010101U)
#elif ARCH_ALIGNMENT == 1
  #define PREFETCH_MULT (uintptr_t)(0x01U)
#else
  #error "Unsupported ARCH_ALIGNMENT for PREFETCH_MULT"
#endif

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
 *  @def        MIN_BLOCK_SIZE
 *  @brief      Defines the minimum memory block size.
 *
 *  @details    Ensures each memory block is large enough to hold
 *              a block header and alignment padding.
 * ========================================================================== */
#define MIN_BLOCK_SIZE  (size_t)(sizeof(block_header_t) + ARCH_ALIGNMENT)

/** ============================================================================
 *  @def        NR_OBJS
 *  @brief      Number of iterations used to scale GC sleep duration
 *
 *  @details    Specifies the multiplier applied to the base GC interval
 *              (in milliseconds) to compute the actual sleep time between
 *              successive garbage-collection cycles:
 *                  sleep_time = gc_interval_ms * NR_OBJS
 * ========================================================================== */
#define NR_OBJS         (uint16_t)(1000U)

/** ============================================================================
 *              P R I V A T E  T Y P E S  D E F I N I T I O N
 * ========================================================================== */

/** ============================================================================
 *  @typedef  find_fn_t
 *  @brief    Type for functions that locate a suitable free block.
 *
 *  @param [in]  allocator  Memory allocator context in which to search.
 *  @param [in]  size       Total size requested (including header and canary).
 *  @param [out] block      Address of pointer to store the found block header.
 *
 *  @return Integer
 * ========================================================================== */
typedef int (*find_fn_t)(mem_allocator_t *const,
                         const size_t,
                         block_header_t **);

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Invokes sbrk-like behavior by moving the program break.
 *
 *  This function reads the current program break, attempts to move it by the
 *  signed offset @p increment via sbrk(), and returns the original break on
 *  success.  If any call to sbrk() or reading the break fails, it encodes the
 *  negative errno into a pointer via PTR_ERR.
 *
 *  @param[in]  increment Signed offset in bytes to move the program break:
 *                        positive to grow, negative to shrink.
 *
 *  @return Original program break address on success;
 *          an error-encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval ret>-1:   Previous break on success.
 *  @retval -ENOMEM:  Failed to read or adjust the break.
 * ========================================================================== */
void *MEM_sbrk(const intptr_t increment);

/** ============================================================================
 *  @brief  Calculates the size class index for a requested memory size.
 *
 *  This function determines which size class the given allocation request
 *  belongs to by dividing the requested @p size by BYTES_PER_CLASS (rounding
 *  up). If the computed index exceeds the maximum available class, it will
 *  be clamped to the highest class and a warning emitted.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  size  Requested memory size in bytes (must be > 0).
 *
 *  @return On success, returns a non-negative integer size class index;
 *          on failure, returns a negative error code.
 *
 *  @retval ret>0:    Valid size class index.
 *  @retval -EINVAL:  @p allocator is NULL, or @p size is zero.
 * ========================================================================== */
static int MEM_getSizeClass(mem_allocator_t *const allocator,
                            const size_t           size);

/** ============================================================================
 *  @brief  Validates the integrity and boundaries of a memory block.
 *
 *  This function ensures that the specified @p block lies within the
 * allocator’s heap or one of its mmap regions, that its header canary matches
 * the expected magic value to detect metadata corruption, that its data canary
 * is intact to catch buffer overruns, and that the block’s size does not extend
 * past the heap’s end.  On any failure, an appropriate negative errno is
 * returned.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the block header to validate.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: @p block is valid.
 *  @retval -EINVAL:      @p allocator or @p block pointer is NULL.
 *  @retval -EFAULT:      @p block lies outside heap and mmap regions.
 *  @retval -EPROTO:      @p block canary does not match expected value.
 *  @retval -EFBIG:       @p block size causes it to extend past heap end.
 *  @retval -EOVERFLOW:   @p block canary indicates buffer overflow.
 * ========================================================================== */
static int MEM_validateBlock(mem_allocator_t *const allocator,
                             block_header_t *const  block);

/** ============================================================================
 *  @brief  Inserts a block into the appropriate free list based on its size.
 *
 *  This function computes the size class index for the given @p block by
 *  calling MEM_getSizeClass(), then pushes the block onto the head of that
 *  free list within the allocator. It updates both forward and backward
 *  links to maintain the doubly‐linked list of free blocks.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the block header to insert.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: @p block successfully inserted.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval -ENOMEM:      Size class calculation failed (request too large).
 * ========================================================================== */
static int MEM_insertFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block);

/** ============================================================================
 *  @brief  Removes a block from its free list.
 *
 *  This function unlinks the specified @p block from the free list
 * corresponding to its size class within the allocator. It computes the
 * size‐class index via MEM_getSizeClass(), validates parameters, then adjusts
 * the neighboring blocks’ fl_next and fl_prev pointers (or the list head) to
 * remove @p block. The block’s own fl_next and fl_prev are then cleared.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  block     Block header to remove.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Block removed successfully.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval -ENOMEM:      Size‐class calculation failed.
 * ========================================================================== */
static int MEM_removeFreeBlock(mem_allocator_t *const allocator,
                               block_header_t *const  block);

/** ============================================================================
 *  @brief  Searches for the first suitable free memory block in size‐class
 * lists.
 *
 *  This function computes the starting size class for the requested @p size via
 *  MEM_getSizeClass(), then scans each free‐list from that class upward.  For
 * each candidate block, it calls MEM_validateBlock() to ensure integrity, and
 * returns the first block that is marked free and large enough. The found block
 * pointer is stored in @p fit_block.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  siz       Requested allocation size in bytes.
 *  @param[out] fit_block On success, set to the pointer of a suitable free
 * block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found successfully.
 *  @retval -EINVAL:      @p allocator or @p fit_block are NULL;
 *  @retval -ENOMEM:      Siz calculation failed or no suitable block found.
 * ========================================================================== */
static int MEM_findFirstFit(mem_allocator_t *const allocator,
                            const size_t           size,
                            block_header_t       **fit_block);

/** ============================================================================
 *  @brief  Searches for the next suitable free memory block using the
 *          NEXT_FIT strategy starting from the last allocated position.
 *
 *  This function attempts to find a free block of at least @p size bytes by
 *  scanning the heap starting at allocator->last_allocated.  If last_allocated
 *  is NULL, not free, or corrupted, it falls back to First-Fit.  It wraps
 *  around to the heap start if needed, stopping once it returns to the start.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  size      Requested allocation size in bytes.
 *  @param[out] fit_block Pointer to store the address of the found block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found and fit_block set.
 *  @retval -EINVAL:      @p allocator or @p fit_block is NULL.
 *  @retval -ENOMEM:      No suitable block found in heap.
 * ========================================================================== */
static int MEM_findNextFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **fit_block);

/** ============================================================================
 *  @brief  Searches for the smallest suitable free memory block
 *          in size‐class lists (BEST_FIT).
 *
 *  This function computes the starting size class for the requested @p size via
 *  MEM_getSizeClass(), then scans each free‐list from that class upward.  It
 *  validates each candidate with MEM_validateBlock() and tracks the smallest
 *  free block that is large enough.  Once a block in any class is chosen, the
 *  search stops.
 *
 *  @param[in]   allocator  Pointer to the allocator context.
 *  @param[in]   size       Requested allocation size in bytes.
 *  @param[out]  best_fit   On success, set to the pointer of the free block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found successfully.
 *  @retval -EINVAL:      @p allocator or @p best_fit is NULL.
 *  @retval -ENOMEM:      Size calculation failed or no suitable block found.
 * ========================================================================== */
static int MEM_findBestFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **best_fit);

/** ============================================================================
 *  @brief  Splits a memory block into allocated and free portions.
 *
 *  This function takes an existing free @p block and a requested allocation
 *  size @p req_size, and divides the block into:
 *    - an allocated portion of size aligned up to ALIGN(req_size) plus header
 *      and canary, marked as used;
 *    - a remaining free portion (if its size ≥ MIN_BLOCK_SIZE) inserted back
 *      into the appropriate free list.
 *  If the leftover space would be too small (< MIN_BLOCK_SIZE), the entire
 *  block is allocated without splitting.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *  @param[in]  block     Pointer to the block_header_t to split.
 *  @param[in]  req_size  Requested allocation size in bytes.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Block split (or fully allocated) successfully.
 *  @retval -EINVAL:      nvalid @p allocator or @p block pointer.
 *  @retval -EPROTO:      Header canary mismatch (block corrupted).
 *  @retval -EOVERFLOW:   Data canary mismatch (buffer overflow detected).
 *  @retval -EFBIG:       Block’s size would extend past heap end.
 *  @retval -EFAULT:      Block lies outside heap or mmap regions.
 *  @retval -ENOMEM:      Failed to insert the new free remainder block.
 *
 *  @note If the remaining space after splitting would be less than
 *        MIN_BLOCK_SIZE, this function allocates the entire block
 *        no split) and removes it from its free list.
 * ========================================================================== */
static int MEM_splitBlock(mem_allocator_t *const allocator,
                          block_header_t *const  block,
                          const size_t           req_size);

/** ============================================================================
 *  @brief      Merges adjacent free memory blocks.
 *
 *  This function removes the specified @p block from its free list, then checks
 *  its immediate neighbor blocks in memory.  If the next block is free and
 *  valid, it unlinks and combines it with @p block, updating size, links, and
 *  trailing canary.  It then checks the previous block; if it is also free and
 *  valid, it merges @p block into the previous block.  Finally, the resulting
 *  merged block is reinserted into the appropriate free list.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the free block header to merge.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Blocks merged (or single block reinserted)
 * successfully.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval ret<0:        Returned by MEM_removeFreeBlock(),
 * MEM_validateBlock(), MEM_insertFreeBlock(), or munmap() in inner calls
 *                        indicating the specific failure.
 * ========================================================================== */
static int MEM_mergeBlocks(mem_allocator_t *const allocator,
                           block_header_t        *block);

/** ============================================================================
 *  @brief  Expands the user heap by a specified increment.
 *
 *  This function moves the program break by @p inc bytes via MEM_sbrk(),
 *  zeroes the newly allocated region, updates the allocator’s heap_end, and
 *  initializes a block_header_t at the start of the new region to record its
 *  size, mark it as allocated, and set its free flag to false.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  inc       Signed number of bytes to grow (or shrink) the heap.
 *
 *  @return Pointer to the previous program break (start of new region)
 *          on success; an error-encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval (ret>=0): Previous heap end address (new region start).
 *  @retval -EINVAL:  @p allocator is NULL.
 *  @retval -ENOMEM:  Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *const allocator,
                              const intptr_t         inc);

/** ============================================================================
 *  @brief      Allocates a page-aligned memory region via mmap and registers it
 *              in the allocator’s mmap list for later freeing.
 *
 *  This function rounds up @p total_size to a multiple of the system page size,
 *  invokes mmap() to obtain an anonymous read/write region, then allocates
 *  an mmap_t metadata node via MEM_allocatorMalloc() and links it into
 *  allocator->mmap_list.  It initializes a block_header_t and trailing canary
 *  in the mapped region to integrate with the allocator’s debugging and GC.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  total_size  Number of bytes requested.
 *
 *  @return On success, returns the address of the mapped region.
 *          On failure, returns an error-encoded pointer (via PTR_ERR()).
 *
 *  @retval ret!=MAP_FAILED:  Address of the mapped region.
 *  @retval -EINVAL:          @p allocator is NULL.
 *  @retval -EIO:             mmap() failed.
 *  @retval -ENOMEM:          Allocation of mmap_t metadata failed.
 * ========================================================================== */
static void *MEM_mapAlloc(mem_allocator_t *const allocator,
                          const size_t           total_size);

/** ============================================================================
 *  @brief  Unmaps a previously mapped memory region and removes its
 *          metadata entry from the allocator’s mmap list.
 *
 *  This function searches the allocator’s mmap_list for an entry matching
 *  @p addr, calls munmap() to unmap the region, unlinks the corresponding
 *  mmap_t metadata node, and frees it via MEM_allocatorFree().  Errors during
 *  munmap are returned; if metadata freeing fails, an error is logged but
 *  success is returned.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  addr      Address of the memory region to unmap.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Region unmapped and metadata entry removed.
 *  @retval -EINVAL:      @p allocator / @p addr is NULL, or not found in list.
 *  @retval -ENOMEM:      munmap() failed to unmap the region.
 * ========================================================================== */
static int MEM_mapFree(mem_allocator_t *const allocator, void *const addr);

/** ============================================================================
 *  @brief  Allocates memory using the specified strategy.
 *
 *  This function attempts to allocate at least @p size bytes of user data by
 *  choosing between heap‐based allocation (via free‐lists and optional heap
 *  growth) or mmap (for large requests > MMAP_THRESHOLD).  It uses the
 *  given @p strategy (FIRST_FIT, NEXT_FIT, BEST_FIT) to locate a free block,
 *  grows the heap if necessary, splits a larger block to fit exactly, and
 *  records debugging metadata (source file, line, variable name).  For mmap
 *  allocations it rounds up to page size and tracks the region in the
 * allocator.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the start of the allocated user region (just past
 *          the internal header) on success; an error‐encoded pointer
 *          (via PTR_ERR()) on failure.
 *
 *  @retval ptr:      Valid user pointer on success.
 *  @retval -EINVAL:  @p allocator is NULL or @p size is zero.
 *  @retval -ENOMEM:  Out of memory: heap grow failed, no free
 *                    block found, or internal metadata allocation
 *                    (e.g. mmap_t node) failed.
 *  @retval -EIO:     mmap() I/O error for large allocations.
 * ========================================================================== */
static void *MEM_allocatorMalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Reallocates memory with safety checks.
 *
 *  This function resizes an existing allocation to @p new_size bytes:
 *    - If @p ptr is NULL, behaves like malloc().
 *    - If the existing block is already large enough, returns the same pointer.
 *    - Otherwise, allocates a new block with the specified @p strategy,
 *      copies the lesser of old and new sizes, frees the old block, and
 *      returns the new pointer.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to the block to resize, or NULL to allocate.
 *  @param[in]  new_size  New requested size in bytes.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy to use.
 *
 *  @return Pointer to the reallocated memory region (which may be the same
 *          as @p ptr) on success; an error-encoded pointer (via PTR_ERR())
 *          on failure.
 *
 *  @retval ptr:      Valid pointer to a block of at least @p new_size bytes.
 *  @retval -EINVAL:  @p allocator is NULL, @p new_size is zero.
 *  @retval -ENOMEM:  Out of memory (allocation or free failure).
 *  @retval -EIO:     I/O error for large mmap-based allocations.
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
 *  @brief  Allocates and zero‐initializes memory.
 *
 *  This function behaves like calloc(), allocating at least @p size bytes of
 *  zeroed memory via MEM_allocatorMalloc() and then setting all bytes to zero.
 *  It records debugging metadata (source file, line, variable name) and uses
 *  the given @p strategy for allocation.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *  @param[in]  size      Number of bytes to allocate.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy to use.
 *
 *  @return Pointer to the start of the allocated zeroed region;
 *          an error‐encoded pointer via PTR_ERR() on failure.
 *
 *  @retval ptr:      Valid pointer to @p size bytes of zeroed memory.
 *  @retval -EINVAL:  @p allocator is NULL or @p size is zero.
 *  @retval -ENOMEM:  Out of memory: allocation failed.
 *  @retval -EIO:     I/O error for large mmap‐based allocations.
 * ========================================================================== */
static void *MEM_allocatorCalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Releases allocated memory back to the heap.
 *
 *  This function frees a pointer previously returned by MEM_allocatorMalloc().
 *  It supports both heap‐based and mmap‐based allocations:
 *    - For mmap regions, it delegates to MEM_mapFree() to unmap and remove
 metadata.
 *    - For heap blocks, it validates the block, checks for double frees,
 *      marks the block free, merges with adjacent free blocks, and reinserts
 *      the merged block into the free list.  If the freed block lies at the
 *      current heap end, it shrinks the heap via MEM_sbrk().
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to memory to free.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Memory freed (and heap possibly shrunk) successfully.
 *  @retval -EINVAL:      @p allocator or @p ptr is NULL, @p ptr not found in
                          @p allocator, or double free detected.
 *  @retval -ENOMEM:      munmap() failed when freeing an mmap region.
 *  @retval -EFAULT:      Block lies outside heap and mmap regions.
 *  @retval -EPROTO:      Header canary mismatch (block corrupted).
 *  @retval -EOVERFLOW:   Data canary mismatch (buffer overrun detected).
 *  @retval -EFBIG:       Block size extends past heap end.
 *  @retval rer<0:        Errors returned by MEM_validateBlock(),
 *                        MEM_removeFreeBlock(), MEM_mergeBlocks(),
 *                        or MEM_insertFreeBlock().
 * ========================================================================== */
static int MEM_allocatorFree(mem_allocator_t *const allocator,
                             void *const            ptr,
                             const char *const      file,
                             const int              line,
                             const char *const      var_name);

/** ============================================================================
 *  @brief  Determine at runtime whether the stack grows downward
 *
 *  This function places two volatile local variables on the stack and compares
 *  their addresses to infer the growth direction:
 *    - If &addr_1 < &addr_0, the stack grows toward lower addresses.
 *    - Otherwise, it grows toward higher addresses.
 *
 *  @return true if stack grows down (higher addresses → lower),
 *          false if it grows up (lower addresses → higher)
 *
 *  @retval true:   Stack grows downward (newer frames at lower addresses)
 *  @retval false:  Stack grows upward (newer frames at higher addresses)
 * ========================================================================== */
static bool MEM_stackGrowsDown(void);

/** ============================================================================
 *  @brief  Query and record the bounding addresses of a thread’s stack
 *
 *  This function retrieves the stack base address, total stack size, and
 *  guard size for the specified thread, then computes the usable stack
 *  bounds within the allocator object, taking into account whether the
 *  stack grows up or down in memory.
 *
 *  @param[in]  id          The thread identifier whose stack to inspect.
 *  @param[in]  allocator   Pointer to the allocator object where stack_bottom
 *                          and stack_top will be stored.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Stack bounds successfully recorded.
 *  @retval -EINVAL:      @p allocator was NULL.
 *  @retval ret>0:        Error code from one of the pthread or system calls
 * ========================================================================== */
static int MEM_stackBounds(const pthread_t        id,
                           mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Dedicated thread loop driving mark-and-sweep iterations.
 *
 *  This function runs as the GC worker thread.  It locks gc_lock and waits
 *  on gc_cond until either gc_running or gc_exit is set.  On wakeup, if
 *  gc_exit is true, it breaks and exits the loop; otherwise it unlocks and
 *  performs one full GC cycle by calling MEM_gcMark() and MEM_gcSweep(),
 *  then sleeps for gc_interval_ms before re-acquiring the lock and waiting
 *  again.  On exit it ensures gc_lock is released.
 *
 *  @param[in]  arg Pointer to the mem_allocator_t context.
 *
 *  @return NULL on clean exit; an error-encoded pointer (via PTR_ERR())
 *          if any initialization or GC step fails.
 *
 *  @retval NULL:     Clean exit after gc_exit.
 *  @retval -EINVAL:  @p arg is NULL.
 *  @retval ret<0:    cond errors, or MEM_gcMark() / MEM_gcSweep() failures.
 * ========================================================================== */
__GC_HOT static void *MEM_gcThreadFunc(void *arg);

/** ============================================================================
 *  @brief  Reset “marked” flags across all allocated regions.
 *
 *  This function prepares for a new garbage-collection cycle by clearing the
 *  mark flag on every heap block and every mmap’d block payload.  It scans
 *  the heap from allocator->heap_start + metadata_size up to
 * allocator->heap_end, resetting each valid block’s marked flag (and skipping
 * malformed blocks to avoid infinite loops).  It then iterates
 * allocator->mmap_list, clearing the mark on each payload block while
 * preserving the metadata header’s mark so the allocator’s own bookkeeping
 * regions are never freed.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All marks cleared and metadata marks preserved.
 *  @retval -EINVAL:      @p allocator is NULL.
 * ========================================================================== */
__GC_HOT static int MEM_setInitialMarks(mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Mark all live blocks reachable from the stack.
 *
 *  This function performs the marking phase of garbage collection by:
 *    - Calling MEM_setInitialMarks() to clear previous marks.
 *    - Capturing stack bounds via MEM_stackBounds() for the current thread.
 *    - Optionally informing Valgrind to treat the stack region as defined.
 *    - Scanning each word between stack_bottom and stack_top:
 *        • If the word’s value lies within the heap bounds, validating the
 *          corresponding block header and marking the block if it is live.
 *    - Iterating the allocator’s mmap_list and marking any mmap’d block whose
 *      payload contains a stack reference.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All reachable blocks marked successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code returned by MEM_stackBounds(),
 *                        MEM_validateBlock(), or other internal calls.
 * ========================================================================== */
__GC_HOT static int MEM_gcMark(mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Reclaim any unmarked blocks from heap and mmap regions.
 *
 *  This function performs the “sweep” phase of garbage collection:
 *    - It iterates over every block in the heap:
 *        • Logs each block’s free and marked status.
 *        • If a block is allocated (free==0) but unmarked, calls
 *          MEM_allocatorFree() on its payload pointer to reclaim it.
 *        • Clears each block’s marked flag.
 *    - It then traverses allocator->mmap_list via a pointer-to-pointer scan:
 *        • Logs each mmap’d region’s status.
 *        • If an mmap’d block is unmarked and not already free, unlinks
 *          the mmap_t node, calls munmap() on the region, and frees its
 *          metadata header via MEM_allocatorFree().
 *        • Otherwise, clears the block’s marked flag and advances to the next
 * node.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All unreachable blocks reclaimed successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Errors returned by MEM_allocatorFree(),
 *                        munmap(), or internal validation functions.
 * ========================================================================== */
__GC_HOT static int MEM_gcSweep(mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Start or signal the GC thread to perform a collection cycle.
 *
 *  This function saves the caller’s thread ID as main_thread, locks gc_lock,
 *  and if the GC thread has not been started, sets gc_running and gc_exit
 *  flags and spawns MEM_gcThreadFunc(); otherwise it sets gc_running and
 *  signals gc_cond to wake the existing thread.  Finally it unlocks gc_lock.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: GC thread started or signaled successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code returned by pthread_create().
 * ========================================================================== */
__GC_COLD static int MEM_runGc(mem_allocator_t *const allocator);

/** ============================================================================
 *  @brief  Stop the GC thread and perform a final collection.
 *
 *  This function clears gc_running and sets gc_exit, signals gc_cond to wake
 *  the GC thread if it’s running, then joins it.  After the thread exits, it
 *  runs one final MEM_gcMark() + MEM_gcSweep() on the caller thread to
 *  reclaim any remaining garbage, then clears gc_thread_started.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: GC thread stopped and final collection done.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code from pthread MEM_gcMark(), or
 * MEM_gcSweep().
 * ========================================================================== */
__GC_COLD static int MEM_stopGc(mem_allocator_t *const allocator);

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Determine at runtime whether the stack grows downward
 *
 *  This function places two volatile local variables on the stack and compares
 *  their addresses to infer the growth direction:
 *    - If &addr_1 < &addr_0, the stack grows toward lower addresses.
 *    - Otherwise, it grows toward higher addresses.
 *
 *  @return true if stack grows down (higher addresses → lower),
 *          false if it grows up (lower addresses → higher)
 *
 *  @retval true:   Stack grows downward (newer frames at lower addresses)
 *  @retval false:  Stack grows upward (newer frames at higher addresses)
 * ========================================================================== */
static bool MEM_stackGrowsDown(void)
{
  bool ret = false;

  volatile int addr_0 = 0u;
  volatile int addr_1 = 0u;

  ret = (bool)(&addr_1 < &addr_0);

  return ret;
}

/** ============================================================================
 *  @brief  Query and record the bounding addresses of a thread’s stack
 *
 *  This function retrieves the stack base address, total stack size, and
 *  guard size for the specified thread, then computes the usable stack
 *  bounds within the allocator object, taking into account whether the
 *  stack grows up or down in memory.
 *
 *  @param[in]  id          The thread identifier whose stack to inspect.
 *  @param[in]  allocator   Pointer to the allocator object where stack_bottom
 *                          and stack_top will be stored.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Stack bounds successfully recorded.
 *  @retval -EINVAL:      @p allocator was NULL.
 *  @retval ret>0:        Error code from one of the pthread or system calls
 * ========================================================================== */
static int MEM_stackBounds(const pthread_t id, mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  pthread_attr_t attr;

  void *base_addr = (void *)NULL;

  uintptr_t base = 0u;

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

  base = (uintptr_t)base_addr;

  grows_down = MEM_stackGrowsDown( );
  if (grows_down)
  {
    allocator->stack_bottom = (uintptr_t *)(base + guard_size);
    allocator->stack_top    = (uintptr_t *)(base + stack_size);
  }
  else
  {
    allocator->stack_bottom = (uintptr_t *)base_addr;
    allocator->stack_top    = (uintptr_t *)(base + stack_size - guard_size);
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
void *MEM_memset(void *const source, const int value, const size_t size)
{
  void *ret = (void *)NULL;

  unsigned char *ptr       = (unsigned char *)NULL;
  unsigned char *ptr_aux   = (unsigned char *)NULL;
  unsigned char *ptr_fetch = (unsigned char *)NULL;

  uintptr_t *word = (uintptr_t *)NULL;

  uintptr_t pattern = 0u;

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

  pattern = ((uintptr_t)(unsigned char)value) * PREFETCH_MULT;

  for (; iterator + ARCH_ALIGNMENT <= size; iterator += ARCH_ALIGNMENT)
  {
    ptr_fetch = ptr + iterator;
    PREFETCH_W(ptr_fetch + CACHE_LINE_SIZE);
    word  = (uintptr_t *)ASSUME_ALIGNED(ptr_fetch, ARCH_ALIGNMENT);
    *word = pattern;
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
void *MEM_memcpy(void *const dest, const void *src, const size_t size)
{
  void *ret = (void *)NULL;

  unsigned char       *destine      = (unsigned char *)NULL;
  unsigned char       *destine_aux  = (unsigned char *)NULL;
  unsigned char       *dest_fetch   = (unsigned char *)NULL;
  const unsigned char *source       = (const unsigned char *)NULL;
  const unsigned char *source_fetch = (const unsigned char *)NULL;

  uintptr_t       *dest_word = (uintptr_t *)NULL;
  const uintptr_t *src_word  = (const uintptr_t *)NULL;

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

  for (; iterator + ARCH_ALIGNMENT <= size; iterator += ARCH_ALIGNMENT)
  {
    dest_fetch   = destine + iterator;
    source_fetch = source + iterator;

    PREFETCH_R(source_fetch + CACHE_LINE_SIZE);
    PREFETCH_W(dest_fetch + CACHE_LINE_SIZE);

    dest_word = (uintptr_t *)ASSUME_ALIGNED(dest_fetch, ARCH_ALIGNMENT);
    src_word  = (const uintptr_t *)ASSUME_ALIGNED(source_fetch, ARCH_ALIGNMENT);

    *dest_word = *src_word;
  }

  destine_aux = destine + iterator;
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
 *  @brief  Invokes sbrk-like behavior by moving the program break.
 *
 *  This function reads the current program break, attempts to move it by the
 *  signed offset @p increment via sbrk(), and returns the original break on
 *  success.  If any call to sbrk() or reading the break fails, it encodes the
 *  negative errno into a pointer via PTR_ERR.
 *
 *  @param[in]  increment Signed offset in bytes to move the program break:
 *                        positive to grow, negative to shrink.
 *
 *  @return Original program break address on success;
 *          an error-encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval ret>-1:   Previous break on success.
 *  @retval -ENOMEM:  Failed to read or adjust the break.
 * ========================================================================== */
void *MEM_sbrk(const intptr_t increment)
{
  void *old_break = (void *)NULL;
  void *new_break = (void *)NULL;

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
 *  @brief  Validates the integrity and boundaries of a memory block.
 *
 *  This function ensures that the specified @p block lies within the
 * allocator’s heap or one of its mmap regions, that its header canary matches
 * the expected magic value to detect metadata corruption, that its data canary
 * is intact to catch buffer overruns, and that the block’s size does not extend
 * past the heap’s end.  On any failure, an appropriate negative errno is
 * returned.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the block header to validate.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: @p block is valid.
 *  @retval -EINVAL:      @p allocator or @p block pointer is NULL.
 *  @retval -EFAULT:      @p block lies outside heap and mmap regions.
 *  @retval -EPROTO:      @p block canary does not match expected value.
 *  @retval -EFBIG:       @p block size causes it to extend past heap end.
 *  @retval -EOVERFLOW:   @p block canary indicates buffer overflow.
 * ========================================================================== */
static int MEM_validateBlock(mem_allocator_t *const allocator,
                             block_header_t *const  block)
{
  int ret = EXIT_SUCCESS;

  mmap_t *map = (mmap_t *)NULL;

  uintptr_t addr       = 0u;
  uintptr_t heap_start = 0u;
  uintptr_t heap_end   = 0u;
  uintptr_t map_start  = 0u;
  uintptr_t map_end    = 0u;

  size_t hdr_sz    = 0u;
  size_t min_total = 0u;
  size_t bsize     = 0u;

  uintptr_t  tail_addr = 0u;
  uintptr_t *tail      = (uintptr_t *)NULL;

  bool in_heap = false;
  bool in_mmap = false;

  if (UNLIKELY((allocator == NULL) || (block == NULL)))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters. Allocator: %p, Block: %p. Error code: %d.\n",
              (void *)allocator,
              (void *)block,
              ret);
    goto function_output;
  }

  addr       = (uintptr_t)block;
  heap_start = (uintptr_t)allocator->heap_start;
  heap_end   = (uintptr_t)allocator->heap_end;
  hdr_sz     = sizeof(block_header_t);
  min_total  = (size_t)(hdr_sz + sizeof(uintptr_t));

  if ((addr >= heap_start) && (addr < heap_end))
  {
    in_heap = true;
  }
  else
  {
    for (map = allocator->mmap_list; map; map = map->next)
    {
      map_start = (uintptr_t)map->addr;
      map_end   = map_start + map->size;

      if ((addr >= map_start) && (addr < map_end))
      {
        in_mmap = true;
        break;
      }
    }
  }

  if (UNLIKELY(!in_heap && !in_mmap))
  {
    ret = -EFAULT;
    LOG_ERROR("Block %p is outside managed regions. Heap=[%p .. %p]. Error "
              "code: %d.\n",
              (void *)block,
              (void *)allocator->heap_start,
              (void *)allocator->heap_end,
              ret);
    goto function_output;
  }

  if ((addr & (ARCH_ALIGNMENT - 1u)) != 0u)
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: misaligned header at %p (alignment=%u). "
                "Error code: %d.\n",
                (void *)block,
                (unsigned)ARCH_ALIGNMENT,
                ret);
    goto function_output;
  }

  if (in_heap)
  {
    const uintptr_t user_start = heap_start + allocator->metadata_size;

    if (addr < user_start)
    {
      ret = -ENOENT;
      LOG_WARNING("Not a memalloc block: header at %p lies inside allocator "
                  "metadata region [%p .. %p). Error code: %d.\n",
                  (void *)block,
                  (void *)allocator->heap_start,
                  (void *)user_start,
                  ret);
      goto function_output;
    }

    if (addr > (heap_end - hdr_sz))
    {
      ret = -ENOENT;
      LOG_WARNING("Not a memalloc block: header at %p truncated at heap end "
                  "%p. Error code: %d.\n",
                  (void *)block,
                  (void *)allocator->heap_end,
                  ret);
      goto function_output;
    }
  }
  else
  {
    if (addr > (map_end - hdr_sz))
    {
      ret = -ENOENT;
      LOG_WARNING("Not a memalloc block: header at %p truncated inside mmap "
                  "region [%p .. %p). Error code: %d.\n",
                  (void *)block,
                  (void *)map->addr,
                  (void *)((uint8_t *)map->addr + map->size),
                  ret);
      goto function_output;
    }
  }

  bsize = block->size;

  if (bsize < min_total)
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: too small size at %p (%zu < %zu). Error "
                "code: %d.\n",
                (void *)block,
                bsize,
                min_total,
                ret);
    goto function_output;
  }

  if ((bsize & (ARCH_ALIGNMENT - 1u)) != 0u)
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: size not aligned at %p (%zu, "
                "alignment=%u). Error code: %d.\n",
                (void *)block,
                bsize,
                (unsigned)ARCH_ALIGNMENT,
                ret);
    goto function_output;
  }

  if (in_heap && ((addr + bsize) > heap_end))
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: block at %p extends past heap end (%p). "
                "size=%zu. Error code: %d.\n",
                (void *)block,
                (void *)allocator->heap_end,
                bsize,
                ret);
    goto function_output;
  }
  if (in_mmap && ((addr + bsize) > map_end))
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: block at %p extends past mmap end (%p). "
                "size=%zu. Error code: %d.\n",
                (void *)block,
                (void *)map_end,
                bsize,
                ret);
    goto function_output;
  }

  if (block->magic != MAGIC_NUMBER)
  {
    ret = -ENOENT;
    LOG_WARNING("Not a memalloc block: magic mismatch at %p (0x%" PRIxPTR
                " vs 0x%" PRIxPTR "). Error code: %d.\n",
                (void *)block,
                block->magic,
                (uintptr_t)MAGIC_NUMBER,
                ret);
    goto function_output;
  }

  if (in_heap && (block->canary != CANARY_VALUE))
  {
    ret = -EPROTO;
    LOG_WARNING("Memalloc block corrupted: header canary mismatch at %p "
                "(0x%" PRIxPTR " vs 0x%" PRIxPTR "). Error code: %d.\n",
                (void *)block,
                block->canary,
                (uintptr_t)CANARY_VALUE,
                ret);
    goto function_output;
  }

  tail_addr = addr + bsize - sizeof(uintptr_t);
  tail      = (uintptr_t *)tail_addr;

  if (in_heap)
  {
    if (*tail != CANARY_VALUE)
    {
      ret = -EOVERFLOW;
      LOG_WARNING("Memalloc block corrupted: data canary mismatch at %p "
                  "(0x%" PRIxPTR "). Error code: %d.\n",
                  (void *)block,
                  *tail,
                  ret);
      goto function_output;
    }
  }
  else
  {
    if (tail_addr >= map_end)
    {
      ret = -ENOENT;
      LOG_WARNING("Not a memalloc block: trailing canary out of mmap bounds at "
                  "%p. Error code: %d.\n",
                  (void *)block,
                  ret);
      goto function_output;
    }

    if (*tail != CANARY_VALUE)
    {
      ret = -EOVERFLOW;
      LOG_WARNING("Memalloc block corrupted (mmap): data canary mismatch at %p "
                  "(0x%" PRIxPTR "). Error code: %d.\n",
                  (void *)block,
                  *tail,
                  ret);
      goto function_output;
    }
  }

  LOG_INFO("Block validated: addr=%p, size=%zu, region=%s.\n",
           (void *)block,
           bsize,
           in_heap ? "heap" : "mmap");

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Calculates the size class index for a requested memory size.
 *
 *  This function determines which size class the given allocation request
 *  belongs to by dividing the requested @p size by BYTES_PER_CLASS (rounding
 *  up). If the computed index exceeds the maximum available class, it will
 *  be clamped to the highest class and a warning emitted.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  size  Requested memory size in bytes (must be > 0).
 *
 *  @return On success, returns a non-negative integer size class index;
 *          on failure, returns a negative error code.
 *
 *  @retval ret>0:    Valid size class index.
 *  @retval -EINVAL:  @p allocator is NULL, or @p size is zero.
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
 *  @brief  Inserts a block into the appropriate free list based on its size.
 *
 *  This function computes the size class index for the given @p block by
 *  calling MEM_getSizeClass(), then pushes the block onto the head of that
 *  free list within the allocator. It updates both forward and backward
 *  links to maintain the doubly‐linked list of free blocks.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the block header to insert.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: @p block successfully inserted.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval -ENOMEM:      Size class calculation failed (request too large).
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

  block->fl_prev = (block_header_t *)NULL;
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
 *  @brief  Removes a block from its free list.
 *
 *  This function unlinks the specified @p block from the free list
 * corresponding to its size class within the allocator. It computes the
 * size‐class index via MEM_getSizeClass(), validates parameters, then adjusts
 * the neighboring blocks’ fl_next and fl_prev pointers (or the list head) to
 * remove @p block. The block’s own fl_next and fl_prev are then cleared.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  block     Block header to remove.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Block removed successfully.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval -ENOMEM:      Size‐class calculation failed.
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
    ret = -ENOMEM;
    goto function_output;
  }

  if (block->fl_prev)
    block->fl_prev->fl_next = block->fl_next;
  else
    allocator->free_lists[index] = block->fl_next;

  if (block->fl_next)
    block->fl_next->fl_prev = block->fl_prev;

  block->fl_next = (block_header_t *)NULL;
  block->fl_prev = (block_header_t *)NULL;

  LOG_INFO("Block %p removed from free list %d (size: %zu)\n",
           (void *)block,
           index,
           block->size);

function_output:
  return ret;
}

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
int MEM_allocatorInit(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  __UNUSED static bool mempool_created = false;

  mem_arena_t *arena     = (mem_arena_t *)NULL;
  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  void *base = (void *)NULL;
  void *old  = (void *)NULL;

  uintptr_t addr = 0;

  size_t pad        = 0u;
  size_t bins_bytes = 0u;

  allocator->last_brk_start = NULL;
  allocator->last_brk_end   = NULL;

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
  allocator->last_allocated = (block_header_t *)NULL;

  allocator->num_arenas = 1u;

  allocator->arenas
    = (mem_arena_t *)MEM_growUserHeap(allocator, sizeof(mem_arena_t));
  if (allocator->arenas == PTR_ERR(-ENOMEM))
  {
    ret = -ENOMEM;
    LOG_ERROR("Unable to allocate memory for arenas. "
              "Error code: %d.\n",
              ret);
    goto function_output;
  }

  arena = &allocator->arenas[0];

  arena->num_bins = DEFAULT_NUM_BINS;

  bins_bytes = (size_t)(arena->num_bins * sizeof(block_header_t *));

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

  allocator->mmap_list = (mmap_t *)NULL;

  allocator->metadata_size
    = ((uintptr_t)arena->bins + bins_bytes) - (uintptr_t)allocator->heap_start;

  gc_thread = &allocator->gc_thread;

  gc_thread->gc_interval_ms = GC_INTERVAL_MS;

  gc_thread->gc_thread_started = false;
  gc_thread->gc_running        = false;
  gc_thread->gc_exit           = false;

  ret = pthread_mutex_init(&gc_thread->gc_lock,
                           (const pthread_mutexattr_t *)NULL);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  ret
    = pthread_cond_init(&gc_thread->gc_cond, (const pthread_condattr_t *)NULL);
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
  if (mempool_created)
    VALGRIND_DESTROY_MEMPOOL(allocator);

  VALGRIND_CREATE_MEMPOOL(allocator, 0, false);
  mempool_created = true;
#endif

  LOG_INFO("Allocator initialized: initial_heap=[%p...%p], bins=%zu.\n",
           (void *)allocator->heap_start,
           (void *)allocator->heap_end,
           arena->num_bins);

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Expands the user heap by a specified increment.
 *
 *  This function moves the program break by @p inc bytes via MEM_sbrk(),
 *  zeroes the newly allocated region, updates the allocator’s heap_end, and
 *  initializes a block_header_t at the start of the new region to record its
 *  size, mark it as allocated, and set its free flag to false.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  inc       Signed number of bytes to grow (or shrink) the heap.
 *
 *  @return Pointer to the previous program break (start of new region)
 *          on success; an error-encoded pointer (via PTR_ERR()) on failure.
 *
 *  @retval (ret>=0): Previous heap end address (new region start).
 *  @retval -EINVAL:  @p allocator is NULL.
 *  @retval -ENOMEM:  Heap expansion failed (out of memory).
 * ========================================================================== */
static void *MEM_growUserHeap(mem_allocator_t *const allocator,
                              const intptr_t         inc)
{
  void *old = (void *)NULL;

  block_header_t *header = (block_header_t *)NULL;

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

  header = (block_header_t *)old;

  header->size   = (size_t)inc;
  header->free   = 1u;
  header->marked = 0u;

  allocator->heap_end = (uint8_t *)((uint8_t *)old + inc);

  allocator->last_brk_start = (uint8_t *)old;
  allocator->last_brk_end   = (uint8_t *)old + inc;

function_output:
  return old;
}
/** ============================================================================
 *  @brief      Allocates a page-aligned memory region via mmap and registers it
 *              in the allocator’s mmap list for later freeing.
 *
 *  This function rounds up @p total_size to a multiple of the system page size,
 *  invokes mmap() to obtain an anonymous read/write region, then allocates
 *  an mmap_t metadata node via MEM_allocatorMalloc() and links it into
 *  allocator->mmap_list.  It initializes a block_header_t and trailing canary
 *  in the mapped region to integrate with the allocator’s debugging and GC.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  total_size  Number of bytes requested.
 *
 *  @return On success, returns the address of the mapped region.
 *          On failure, returns an error-encoded pointer (via PTR_ERR()).
 *
 *  @retval ret!=MAP_FAILED:  Address of the mapped region.
 *  @retval -EINVAL:          @p allocator is NULL.
 *  @retval -EIO:             mmap() failed.
 *  @retval -ENOMEM:          Allocation of mmap_t metadata failed.
 * ========================================================================== */
static void *MEM_mapAlloc(mem_allocator_t *const allocator,
                          const size_t           total_size)
{
  void *ptr = (void *)NULL;

  mmap_t *map_block = (mmap_t *)NULL;

  block_header_t *header = (block_header_t *)NULL;

  uintptr_t *data_canary = (uintptr_t *)NULL;
  uintptr_t  canary_addr = 0u;

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
  map_size = ((total_size + page - 1u) / page) * page;

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

  header = (block_header_t *)ptr;

  header->magic    = MAGIC_NUMBER;
  header->size     = map_size;
  header->free     = 0u;
  header->marked   = 1u;
  header->prev     = (block_header_t *)NULL;
  header->next     = (block_header_t *)NULL;
  header->file     = (const char *)NULL;
  header->line     = 0u;
  header->var_name = (const char *)NULL;

  canary_addr  = (uintptr_t)ptr + map_size - sizeof(uintptr_t);
  data_canary  = (uintptr_t *)canary_addr;
  *data_canary = CANARY_VALUE;

  LOG_INFO("Mmap allocated: %zu bytes at %p.\n", map_size, ptr);

function_output:
  return ptr;
}

/** ============================================================================
 *  @brief  Unmaps a previously mapped memory region and removes its
 *          metadata entry from the allocator’s mmap list.
 *
 *  This function searches the allocator’s mmap_list for an entry matching
 *  @p addr, calls munmap() to unmap the region, unlinks the corresponding
 *  mmap_t metadata node, and frees it via MEM_allocatorFree().  Errors during
 *  munmap are returned; if metadata freeing fails, an error is logged but
 *  success is returned.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  addr      Address of the memory region to unmap.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Region unmapped and metadata entry removed.
 *  @retval -EINVAL:      @p allocator / @p addr is NULL, or not found in list.
 *  @retval -ENOMEM:      munmap() failed to unmap the region.
 * ========================================================================== */
static int MEM_mapFree(mem_allocator_t *const allocator, void *const addr)
{
  int ret = EXIT_SUCCESS;

  mmap_t **map_ref = (mmap_t **)NULL;
  mmap_t  *to_free = (mmap_t *)NULL;

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

      ret = MEM_allocatorFree(allocator,
                              (void *)to_free,
                              __FILE__,
                              __LINE__,
                              "mmap_meta");
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
 *  @brief  Searches for the first suitable free memory block in size‐class
 * lists.
 *
 *  This function computes the starting size class for the requested @p size via
 *  MEM_getSizeClass(), then scans each free‐list from that class upward.  For
 * each candidate block, it calls MEM_validateBlock() to ensure integrity, and
 * returns the first block that is marked free and large enough. The found block
 * pointer is stored in @p fit_block.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  siz       Requested allocation size in bytes.
 *  @param[out] fit_block On success, set to the pointer of a suitable free
 * block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found successfully.
 *  @retval -EINVAL:      @p allocator or @p fit_block are NULL;
 *  @retval -ENOMEM:      Siz calculation failed or no suitable block found.
 * ========================================================================== */
static int MEM_findFirstFit(mem_allocator_t *const allocator,
                            const size_t           size,
                            block_header_t       **fit_block)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = (block_header_t *)NULL;

  int    start_class = 0;
  size_t class_idx   = 0u;

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
 *  @brief  Searches for the next suitable free memory block using the
 *          NEXT_FIT strategy starting from the last allocated position.
 *
 *  This function attempts to find a free block of at least @p size bytes by
 *  scanning the heap starting at allocator->last_allocated.  If last_allocated
 *  is NULL, not free, or corrupted, it falls back to First-Fit.  It wraps
 *  around to the heap start if needed, stopping once it returns to the start.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  size      Requested allocation size in bytes.
 *  @param[out] fit_block Pointer to store the address of the found block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found and fit_block set.
 *  @retval -EINVAL:      @p allocator or @p fit_block is NULL.
 *  @retval -ENOMEM:      No suitable block found in heap.
 * ========================================================================== */
static int MEM_findNextFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **fit_block)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = (block_header_t *)NULL;
  block_header_t *start   = (block_header_t *)NULL;

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

    current
      = (current->next)
          ? current->next
          : (block_header_t *)ASSUME_ALIGNED((uint8_t *)allocator->heap_start
                                               + allocator->metadata_size,
                                             ARCH_ALIGNMENT);

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
 *  @brief  Searches for the smallest suitable free memory block
 *          in size‐class lists (BEST_FIT).
 *
 *  This function computes the starting size class for the requested @p size via
 *  MEM_getSizeClass(), then scans each free‐list from that class upward.  It
 *  validates each candidate with MEM_validateBlock() and tracks the smallest
 *  free block that is large enough.  Once a block in any class is chosen, the
 *  search stops.
 *
 *  @param[in]   allocator  Pointer to the allocator context.
 *  @param[in]   size       Requested allocation size in bytes.
 *  @param[out]  best_fit   On success, set to the pointer of the free block.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Suitable block found successfully.
 *  @retval -EINVAL:      @p allocator or @p best_fit is NULL.
 *  @retval -ENOMEM:      Size calculation failed or no suitable block found.
 * ========================================================================== */
static int MEM_findBestFit(mem_allocator_t *const allocator,
                           const size_t           size,
                           block_header_t       **best_fit)
{
  int ret = EXIT_SUCCESS;

  block_header_t *current = (block_header_t *)NULL;

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

  *best_fit = (block_header_t *)NULL;

  start_class = MEM_getSizeClass(allocator, size);
  if (start_class < 0)
  {
    ret = -ENOMEM;
    goto function_output;
  }

  for (iterator = (size_t)start_class; iterator < allocator->num_size_classes;
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
 *  @brief  Splits a memory block into allocated and free portions.
 *
 *  This function takes an existing free @p block and a requested allocation
 *  size @p req_size, and divides the block into:
 *    - an allocated portion of size aligned up to ALIGN(req_size) plus header
 *      and canary, marked as used;
 *    - a remaining free portion (if its size ≥ MIN_BLOCK_SIZE) inserted back
 *      into the appropriate free list.
 *  If the leftover space would be too small (< MIN_BLOCK_SIZE), the entire
 *  block is allocated without splitting.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *  @param[in]  block     Pointer to the block_header_t to split.
 *  @param[in]  req_size  Requested allocation size in bytes.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Block split (or fully allocated) successfully.
 *  @retval -EINVAL:      nvalid @p allocator or @p block pointer.
 *  @retval -EPROTO:      Header canary mismatch (block corrupted).
 *  @retval -EOVERFLOW:   Data canary mismatch (buffer overflow detected).
 *  @retval -EFBIG:       Block’s size would extend past heap end.
 *  @retval -EFAULT:      Block lies outside heap or mmap regions.
 *  @retval -ENOMEM:      Failed to insert the new free remainder block.
 *
 *  @note If the remaining space after splitting would be less than
 *        MIN_BLOCK_SIZE, this function allocates the entire block
 *        no split) and removes it from its free list.
 * ========================================================================== */
static int MEM_splitBlock(mem_allocator_t *const allocator,
                          block_header_t *const  block,
                          const size_t           req_size)
{
  int ret = EXIT_SUCCESS;

  block_header_t *new_block = (block_header_t *)NULL;

  uintptr_t *data_canary = (uintptr_t *)NULL;
  uintptr_t  canary_addr = 0u;

  size_t aligned_size   = 0u;
  size_t total_size     = 0u;
  size_t remaining_size = 0u;
  size_t original_size  = 0u;

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
    = (size_t)(aligned_size + sizeof(block_header_t) + sizeof(uintptr_t));

  ret = MEM_removeFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  original_size = block->size;

  if (block->size < total_size + MIN_BLOCK_SIZE)
  {
    block->free   = 0u;
    block->magic  = MAGIC_NUMBER;
    block->canary = CANARY_VALUE;

    canary_addr  = (uintptr_t)block + block->size - sizeof(uintptr_t);
    data_canary  = (uintptr_t *)canary_addr;
    *data_canary = CANARY_VALUE;

    LOG_DEBUG("Using full block %p | Req size: %zu | Block size: %zu.\n",
              (void *)block,
              req_size,
              original_size);
    goto function_output;
  }

  remaining_size = block->size - total_size;

  block->size   = total_size;
  block->free   = 0u;
  block->magic  = MAGIC_NUMBER;
  block->canary = CANARY_VALUE;

  canary_addr  = (uintptr_t)block + block->size - sizeof(uintptr_t);
  data_canary  = (uintptr_t *)canary_addr;
  *data_canary = CANARY_VALUE;

  new_block = (block_header_t *)((uintptr_t)block + total_size);

  new_block->magic    = MAGIC_NUMBER;
  new_block->size     = remaining_size;
  new_block->free     = 1u;
  new_block->marked   = 0u;
  new_block->file     = (const char *)NULL;
  new_block->line     = 0ull;
  new_block->var_name = (const char *)NULL;
  new_block->prev     = block;
  new_block->next     = block->next;

  if (block->next)
    block->next->prev = new_block;
  block->next = new_block;

  new_block->canary = CANARY_VALUE;
  canary_addr  = (uintptr_t)new_block + new_block->size - sizeof(uintptr_t);
  data_canary  = (uintptr_t *)canary_addr;
  *data_canary = CANARY_VALUE;

  new_block->fl_next = (block_header_t *)NULL;
  new_block->fl_prev = (block_header_t *)NULL;

  ret = MEM_insertFreeBlock(allocator, new_block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  LOG_DEBUG("Block split | Original: %p (%zu) | Alloc: %p (%zu) | Remainder: "
            "%p (%zu).\n",
            (void *)block,
            original_size,
            (void *)block,
            block->size,
            (void *)new_block,
            new_block->size);

function_output:
  return ret;
}

/** ============================================================================
 *  @brief      Merges adjacent free memory blocks.
 *
 *  This function removes the specified @p block from its free list, then checks
 *  its immediate neighbor blocks in memory.  If the next block is free and
 *  valid, it unlinks and combines it with @p block, updating size, links, and
 *  trailing canary.  It then checks the previous block; if it is also free and
 *  valid, it merges @p block into the previous block.  Finally, the resulting
 *  merged block is reinserted into the appropriate free list.
 *
 *  @param[in]  allocator Pointer to the allocator context.
 *  @param[in]  block     Pointer to the free block header to merge.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Blocks merged (or single block reinserted)
 * successfully.
 *  @retval -EINVAL:      @p allocator or @p block is NULL.
 *  @retval ret<0:        Returned by MEM_removeFreeBlock(),
 * MEM_validateBlock(), MEM_insertFreeBlock(), or munmap() in inner calls
 *                        indicating the specific failure.
 * ========================================================================== */
static int MEM_mergeBlocks(mem_allocator_t *const allocator,
                           block_header_t        *block)
{
  int ret = EXIT_SUCCESS;

  uint8_t *next_addr = (uint8_t *)NULL;

  block_header_t *next_block = (block_header_t *)NULL;
  block_header_t *prev_block = (block_header_t *)NULL;

  uintptr_t *data_canary = (uintptr_t *)NULL;
  uintptr_t  canary_addr = 0u;

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

  ret = MEM_validateBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  next_addr = (uint8_t *)((uint8_t *)block + block->size);
  if (next_addr + sizeof(block_header_t) <= allocator->heap_end)
  {
    next_block = (block_header_t *)(uintptr_t)next_addr;

    ret = MEM_validateBlock(allocator, next_block);
    if (ret == EXIT_SUCCESS && next_block->free)
    {
      LOG_DEBUG("Merging blocks (next): cur=%p (%zu) | next=%p (%zu).\n",
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

      canary_addr  = (uintptr_t)block + block->size - sizeof(uintptr_t);
      data_canary  = (uintptr_t *)canary_addr;
      *data_canary = CANARY_VALUE;

      LOG_DEBUG("Merged(next): payload=%p (%zu).\n",
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
      LOG_DEBUG("Merging blocks (prev): prev=%p (%zu) | cur=%p (%zu).\n",
                (void *)((uint8_t *)prev_block + sizeof(block_header_t)),
                prev_block->size,
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size);

      ret = MEM_removeFreeBlock(allocator, prev_block);
      if (ret != EXIT_SUCCESS)
        goto function_output;

      prev_block->size += block->size;
      prev_block->next  = block->next;
      if (block->next)
        block->next->prev = prev_block;

      canary_addr
        = (uintptr_t)prev_block + prev_block->size - sizeof(uintptr_t);
      data_canary  = (uintptr_t *)canary_addr;
      *data_canary = CANARY_VALUE;

      block = prev_block;

      LOG_DEBUG("Merged(prev): payload=%p (%zu).\n",
                (void *)((uint8_t *)block + sizeof(block_header_t)),
                block->size);
    }
  }

  block->fl_next = (block_header_t *)NULL;
  block->fl_prev = (block_header_t *)NULL;

  ret = MEM_insertFreeBlock(allocator, block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Allocates memory using the specified strategy.
 *
 *  This function attempts to allocate at least @p size bytes of user data by
 *  choosing between heap‐based allocation (via free‐lists and optional heap
 *  growth) or mmap (for large requests > MMAP_THRESHOLD).  It uses the
 *  given @p strategy (FIRST_FIT, NEXT_FIT, BEST_FIT) to locate a free block,
 *  grows the heap if necessary, splits a larger block to fit exactly, and
 *  records debugging metadata (source file, line, variable name).  For mmap
 *  allocations it rounds up to page size and tracks the region in the
 * allocator.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the start of the allocated user region (just past
 *          the internal header) on success; an error‐encoded pointer
 *          (via PTR_ERR()) on failure.
 *
 *  @retval ptr:      Valid user pointer on success.
 *  @retval -EINVAL:  @p allocator is NULL or @p size is zero.
 *  @retval -ENOMEM:  Out of memory: heap grow failed, no free
 *                    block found, or internal metadata allocation
 *                    (e.g. mmap_t node) failed.
 *  @retval -EIO:     mmap() I/O error for large allocations.
 * ========================================================================== */
static void *MEM_allocatorMalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
{
  void *user_ptr = (void *)NULL;

  mem_arena_t    *arena = (mem_arena_t *)NULL;
  block_header_t *block = (block_header_t *)NULL;

  void *old_brk  = (void *)NULL;
  void *raw_mmap = (void *)NULL;

  uintptr_t *data_canary = (uintptr_t *)NULL;
  uintptr_t  canary_addr = 0u;

  size_t total_size = 0u;

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

  total_size = ALIGN(size) + sizeof(block_header_t) + sizeof(uintptr_t);
  arena      = &allocator->arenas[0];

  if (size > MMAP_THRESHOLD)
  {
    raw_mmap = MEM_mapAlloc(allocator, total_size);
    if (raw_mmap == NULL)
    {
      user_ptr = PTR_ERR(-ENOMEM);
      LOG_ERROR("Mmap failed: %zu bytes. Error code: %d.\n",
                total_size,
                (int)(intptr_t)user_ptr);
      goto function_output;
    }

    block = (block_header_t *)raw_mmap;

    block->magic  = MAGIC_NUMBER;
    block->size   = total_size;
    block->free   = 0u;
    block->marked = 0u;
    block->next   = (block_header_t *)NULL;
    block->prev   = (block_header_t *)NULL;
    block->canary = CANARY_VALUE;

    canary_addr  = (uintptr_t)block + total_size - sizeof(uintptr_t);
    data_canary  = (uintptr_t *)canary_addr;
    *data_canary = CANARY_VALUE;

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

    allocator->last_brk_start = (uint8_t *)((uint8_t *)old_brk);
    allocator->last_brk_end   = (uint8_t *)((uint8_t *)old_brk + total_size);

    block = (block_header_t *)old_brk;

    block->magic  = MAGIC_NUMBER;
    block->size   = total_size;
    block->free   = 1u;
    block->marked = 0u;
    block->next   = (block_header_t *)NULL;
    block->prev   = (block_header_t *)NULL;
    block->canary = CANARY_VALUE;

    canary_addr  = (uintptr_t)block + total_size - sizeof(uintptr_t);
    data_canary  = (uintptr_t *)canary_addr;
    *data_canary = CANARY_VALUE;

    block->fl_next = (block_header_t *)NULL;
    block->fl_prev = (block_header_t *)NULL;

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
                                  - sizeof(uintptr_t))
                               : 0);
#endif

null_pointer:
  return user_ptr;
}

/** ============================================================================
 *  @brief  Reallocates memory with safety checks.
 *
 *  This function resizes an existing allocation to @p new_size bytes:
 *    - If @p ptr is NULL, behaves like malloc().
 *    - If the existing block is already large enough, returns the same pointer.
 *    - Otherwise, allocates a new block with the specified @p strategy,
 *      copies the lesser of old and new sizes, frees the old block, and
 *      returns the new pointer.
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to the block to resize, or NULL to allocate.
 *  @param[in]  new_size  New requested size in bytes.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy to use.
 *
 *  @return Pointer to the reallocated memory region (which may be the same
 *          as @p ptr) on success; an error-encoded pointer (via PTR_ERR())
 *          on failure.
 *
 *  @retval ptr:      Valid pointer to a block of at least @p new_size bytes.
 *  @retval -EINVAL:  @p allocator is NULL, @p new_size is zero.
 *  @retval -ENOMEM:  Out of memory (allocation or free failure).
 *  @retval -EIO:     I/O error for large mmap-based allocations.
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

  void *new_ptr = (void *)NULL;
  ;

  block_header_t *old_block = (block_header_t *)NULL;
  ;

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
    new_ptr = MEM_allocatorMalloc(allocator,
                                  new_size,
                                  file,
                                  line,
                                  var_name,
                                  strategy);
    goto function_output;
  }

  old_block = (block_header_t *)((uintptr_t)ptr - sizeof(block_header_t));

  ret = MEM_validateBlock(allocator, old_block);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  old_size
    = (size_t)(old_block->size - sizeof(block_header_t) - sizeof(uintptr_t));
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
 *  @brief  Allocates and zero‐initializes memory.
 *
 *  This function behaves like calloc(), allocating at least @p size bytes of
 *  zeroed memory via MEM_allocatorMalloc() and then setting all bytes to zero.
 *  It records debugging metadata (source file, line, variable name) and uses
 *  the given @p strategy for allocation.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *  @param[in]  size      Number of bytes to allocate.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *  @param[in]  strategy  Allocation strategy to use.
 *
 *  @return Pointer to the start of the allocated zeroed region;
 *          an error‐encoded pointer via PTR_ERR() on failure.
 *
 *  @retval ptr:      Valid pointer to @p size bytes of zeroed memory.
 *  @retval -EINVAL:  @p allocator is NULL or @p size is zero.
 *  @retval -ENOMEM:  Out of memory: allocation failed.
 *  @retval -EIO:     I/O error for large mmap‐based allocations.
 * ========================================================================== */
static void *MEM_allocatorCalloc(mem_allocator_t *const      allocator,
                                 const size_t                size,
                                 const char *const           file,
                                 const int                   line,
                                 const char *const           var_name,
                                 const allocation_strategy_t strategy)
{
  void *ptr = (void *)NULL;
  ;

  block_header_t *block = (block_header_t *)NULL;
  ;

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

  block = (block_header_t *)((uintptr_t)ptr - sizeof(block_header_t));
  data_size
    = (size_t)(block->size - sizeof(block_header_t) - sizeof(uintptr_t));

  MEM_memset(ptr, 0, data_size);

  LOG_DEBUG("Zero-initialized memory: addr: %p (%zu bytes).\n", ptr, size);

function_output:
  return ptr;
}

/** ============================================================================
 *  @brief  Releases allocated memory back to the heap.
 *
 *  This function frees a pointer previously returned by MEM_allocatorMalloc().
 *  It supports both heap‐based and mmap‐based allocations:
 *    - For mmap regions, it delegates to MEM_mapFree() to unmap and remove
 metadata.
 *    - For heap blocks, it validates the block, checks for double frees,
 *      marks the block free, merges with adjacent free blocks, and reinserts
 *      the merged block into the free list.  If the freed block lies at the
 *      current heap end, it shrinks the heap via MEM_sbrk().
 *
 *  @param[in]  allocator Memory allocator context.
 *  @param[in]  ptr       Pointer to memory to free.
 *  @param[in]  file      Source file name for debugging metadata.
 *  @param[in]  line      Source line number for debugging metadata.
 *  @param[in]  var_name  Variable name for tracking.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: Memory freed (and heap possibly shrunk) successfully.
 *  @retval -EINVAL:      @p allocator or @p ptr is NULL, @p ptr not found in
                          @p allocator, or double free detected.
 *  @retval -ENOMEM:      munmap() failed when freeing an mmap region.
 *  @retval -EFAULT:      Block lies outside heap and mmap regions.
 *  @retval -EPROTO:      Header canary mismatch (block corrupted).
 *  @retval -EOVERFLOW:   Data canary mismatch (buffer overrun detected).
 *  @retval -EFBIG:       Block size extends past heap end.
 *  @retval rer<0:        Errors returned by MEM_validateBlock(),
 *                        MEM_removeFreeBlock(), MEM_mergeBlocks(),
 *                        or MEM_insertFreeBlock().
 * ========================================================================== */
static int MEM_allocatorFree(mem_allocator_t *const allocator,
                             void *const            ptr,
                             const char *const      file,
                             const int              line,
                             const char *const      var_name)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = (block_header_t *)NULL;
  mmap_t         *map   = (mmap_t *)NULL;

  void *old = (void *)NULL;

  uint8_t *block_end = (uint8_t *)NULL;

  uint8_t *cur_brk = (uint8_t *)NULL;

  intptr_t delta = 0;

  size_t shrink_size = 0u;
  size_t freed_size  = 0u;
  size_t lease       = 0u;

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

  block = (block_header_t *)((uintptr_t)ptr - sizeof(block_header_t));
  for (map = allocator->mmap_list; map; map = map->next)
  {
    if ((void *)block == map->addr)
    {
      ret = MEM_mapFree(allocator, map->addr);
      goto function_output;
    }
  }

  block = (block_header_t *)((uintptr_t)ptr - sizeof(block_header_t));

  ret = MEM_validateBlock(allocator, block);
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
    cur_brk = (uint8_t *)sbrk(0);

    if (cur_brk == allocator->heap_end && allocator->last_brk_start != NULL
        && allocator->last_brk_end != NULL
        && allocator->last_brk_end == allocator->heap_end)
    {
      lease = (size_t)(allocator->last_brk_end - allocator->last_brk_start);

      if (lease > 0u && block->size >= lease)
      {
        ret = MEM_removeFreeBlock(allocator, block);
        if (ret != EXIT_SUCCESS)
          goto function_output;

        shrink_size = lease;
        delta       = -(intptr_t)shrink_size;

        LOG_INFO("Conservative shrink: returning last lease of %zu bytes.\n",
                 shrink_size);

        old = MEM_sbrk(delta);
        if ((intptr_t)old >= 0)
        {
          allocator->heap_end       = allocator->heap_end + delta;
          allocator->last_brk_start = (uint8_t *)NULL;
          allocator->last_brk_end   = (uint8_t *)NULL;
          allocator->last_allocated
            = (block_header_t *)(uintptr_t)allocator->heap_start;

          LOG_INFO("Heap shrunk by %zu bytes. New heap_end=%p.\n",
                   shrink_size,
                   (void *)allocator->heap_end);

          goto function_output;
        }
        else
        {
          (void)MEM_insertFreeBlock(allocator, block);
          LOG_WARNING("sbrk(-%zu) failed; skipping shrink. errno=%d\n",
                      shrink_size,
                      ENOMEM);
          ret = EXIT_SUCCESS;
        }
      }
    }
  }

  freed_size = (size_t)(block->size - sizeof(*block) - sizeof(uintptr_t));
  LOG_INFO("Memory freed: addr: %p (%zu bytes).\n", ptr, freed_size);

function_output:
  return ret;
}
/** ============================================================================
 *      P R I V A T E  G A R B A G E  C O L L E C T O R  F U N C T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Reset “marked” flags across all allocated regions.
 *
 *  This function prepares for a new garbage-collection cycle by clearing the
 *  mark flag on every heap block and every mmap’d block payload.  It scans
 *  the heap from allocator->heap_start + metadata_size up to
 * allocator->heap_end, resetting each valid block’s marked flag (and skipping
 * malformed blocks to avoid infinite loops).  It then iterates
 * allocator->mmap_list, clearing the mark on each payload block while
 * preserving the metadata header’s mark so the allocator’s own bookkeeping
 * regions are never freed.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All marks cleared and metadata marks preserved.
 *  @retval -EINVAL:      @p allocator is NULL.
 * ========================================================================== */
static int MEM_setInitialMarks(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = (block_header_t *)NULL;

  block_header_t *meta_data = (block_header_t *)NULL;
  mmap_t         *map       = (mmap_t *)NULL;

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
      block->marked = 0u;

      heap_ptr += block->size;
    }
    else
    {
      heap_ptr += sizeof(block_header_t);
    }
  }

  for (map = allocator->mmap_list; map; map = map->next)
  {
    block = (block_header_t *)map->addr;

    block->marked = 0u;

    meta_data = (block_header_t *)((uintptr_t)map - sizeof(block_header_t));

    meta_data->marked = 1u;
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Mark all live blocks reachable from the stack.
 *
 *  This function performs the marking phase of garbage collection by:
 *    - Calling MEM_setInitialMarks() to clear previous marks.
 *    - Capturing stack bounds via MEM_stackBounds() for the current thread.
 *    - Optionally informing Valgrind to treat the stack region as defined.
 *    - Scanning each word between stack_bottom and stack_top:
 *        • If the word’s value lies within the heap bounds, validating the
 *          corresponding block header and marking the block if it is live.
 *    - Iterating the allocator’s mmap_list and marking any mmap’d block whose
 *      payload contains a stack reference.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All reachable blocks marked successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code returned by MEM_stackBounds(),
 *                        MEM_validateBlock(), or other internal calls.
 * ========================================================================== */
static int MEM_gcMark(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  block_header_t *block = (block_header_t *)NULL;

  mmap_t *map = (mmap_t *)NULL;

  volatile uintptr_t *stack_ptr = (volatile uintptr_t *)NULL;

  void *stack_frame = (void *)NULL;

  uintptr_t *stack_tmp    = (uintptr_t *)NULL;
  uintptr_t *stack_bottom = (uintptr_t *)NULL;
  uintptr_t *stack_top    = (uintptr_t *)NULL;

  uintptr_t heap_start = 0u;
  uintptr_t heap_end   = 0u;

  uintptr_t block_addr    = 0u;
  uintptr_t payload_start = 0u;
  uintptr_t payload_end   = 0u;

  bool mmap_found = false;

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

  ret = MEM_stackBounds(gc_thread->main_thread, allocator);
  if (ret != EXIT_SUCCESS)
    goto function_output;

  heap_start = (uintptr_t)allocator->heap_start + allocator->metadata_size;

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
        payload_end   = (uintptr_t)block + block->size - sizeof(uintptr_t);

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
        }
      }

      mmap_found = false;
      for (map = allocator->mmap_list; map && !mmap_found; map = map->next)
      {
        block = (block_header_t *)map->addr;

        payload_start = (uintptr_t)map->addr + sizeof(*block);
        payload_end   = (uintptr_t)map->addr + map->size - sizeof(uintptr_t);

        if (block_addr >= payload_start && block_addr < payload_end
            && !block->free)
        {
          block->marked = 1u;
          LOG_INFO("Block Marked(sbrk): %p (%zu bytes).\n",
                   (void *)((uint8_t *)block + sizeof(block_header_t)),
                   block->size);
          mmap_found = true;
        }
      }
    }

    ret = EXIT_SUCCESS;
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Reclaim any unmarked blocks from heap and mmap regions.
 *
 *  This function performs the “sweep” phase of garbage collection:
 *    - It iterates over every block in the heap:
 *        • Logs each block’s free and marked status.
 *        • If a block is allocated (free==0) but unmarked, calls
 *          MEM_allocatorFree() on its payload pointer to reclaim it.
 *        • Clears each block’s marked flag.
 *    - It then traverses allocator->mmap_list via a pointer-to-pointer scan:
 *        • Logs each mmap’d region’s status.
 *        • If an mmap’d block is unmarked and not already free, unlinks
 *          the mmap_t node, calls munmap() on the region, and frees its
 *          metadata header via MEM_allocatorFree().
 *        • Otherwise, clears the block’s marked flag and advances to the next
 * node.
 *
 *  @param[in]  allocator Memory allocator context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: All unreachable blocks reclaimed successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Errors returned by MEM_allocatorFree(),
 *                        munmap(), or internal validation functions.
 * ========================================================================== */
static int MEM_gcSweep(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  block_header_t *block = (block_header_t *)NULL;

  mmap_t  *map  = (mmap_t *)NULL;
  mmap_t **scan = (mmap_t **)NULL;

  void *user_ptr = (void *)NULL;

  uint8_t *heap_end   = (uint8_t *)NULL;
  uint8_t *heap_start = (uint8_t *)NULL;
  uint8_t *heap_ptr   = (uint8_t *)NULL;

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
  heap_end = allocator->heap_end;

  min_size = sizeof(block_header_t);

  heap_ptr = heap_start;

  while (heap_ptr < heap_end)
  {
    block = (block_header_t *)(uintptr_t)heap_ptr;

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
    heap_end  = allocator->heap_end;
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
      MEM_allocatorFree(allocator,
                        (void *)map,
                        __FILE__,
                        __LINE__,
                        "mmap_meta");
    }
    else
    {
      block->marked = 0;

      scan = &map->next;
    }
  }

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Dedicated thread loop driving mark-and-sweep iterations.
 *
 *  This function runs as the GC worker thread.  It locks gc_lock and waits
 *  on gc_cond until either gc_running or gc_exit is set.  On wakeup, if
 *  gc_exit is true, it breaks and exits the loop; otherwise it unlocks and
 *  performs one full GC cycle by calling MEM_gcMark() and MEM_gcSweep(),
 *  then sleeps for gc_interval_ms before re-acquiring the lock and waiting
 *  again.  On exit it ensures gc_lock is released.
 *
 *  @param[in]  arg Pointer to the mem_allocator_t context.
 *
 *  @return NULL on clean exit; an error-encoded pointer (via PTR_ERR())
 *          if any initialization or GC step fails.
 *
 *  @retval NULL:     Clean exit after gc_exit.
 *  @retval -EINVAL:  @p arg is NULL.
 *  @retval ret<0:    cond errors, or MEM_gcMark() / MEM_gcSweep() failures.
 * ========================================================================== */
static void *MEM_gcThreadFunc(void *arg)
{
  int ret = EXIT_SUCCESS;

  mem_allocator_t *allocator = (mem_allocator_t *)NULL;
  gc_thread_t     *gc_thread = (gc_thread_t *)NULL;

  if (UNLIKELY(arg == NULL))
  {
    ret = -EINVAL;
    LOG_ERROR("Invalid parameters: arg: %p. "
              "Error code: %d.\n",
              (void *)arg,
              (int)(intptr_t)ret);
    goto function_output;
  }

  allocator = (mem_allocator_t *)arg;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);

  while (!gc_thread->gc_exit)
  {
    while (!gc_thread->gc_running && !gc_thread->gc_exit)
      pthread_cond_wait(&gc_thread->gc_cond, &gc_thread->gc_lock);

    if (gc_thread->gc_exit)
      goto mutex_unlock;

    pthread_mutex_unlock(&gc_thread->gc_lock);

    ret = MEM_gcMark(allocator);
    if (ret != EXIT_SUCCESS)
      goto mutex_unlock;

    ret = MEM_gcSweep(allocator);
    if (ret != EXIT_SUCCESS)
      goto mutex_unlock;

    usleep((__useconds_t)(gc_thread->gc_interval_ms * NR_OBJS));

    pthread_mutex_lock(&gc_thread->gc_lock);
  }

mutex_unlock:
  pthread_mutex_unlock(&gc_thread->gc_lock);
function_output:
  return PTR_ERR(ret);
}

/** ============================================================================
 *  @brief  Start or signal the GC thread to perform a collection cycle.
 *
 *  This function saves the caller’s thread ID as main_thread, locks gc_lock,
 *  and if the GC thread has not been started, sets gc_running and gc_exit
 *  flags and spawns MEM_gcThreadFunc(); otherwise it sets gc_running and
 *  signals gc_cond to wake the existing thread.  Finally it unlocks gc_lock.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: GC thread started or signaled successfully.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code returned by pthread_create().
 * ========================================================================== */
static int MEM_runGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  pthread_t thread;

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

  gc_thread->main_thread = pthread_self( );

  pthread_mutex_lock(&gc_thread->gc_lock);
  if (!gc_thread->gc_thread_started)
  {
    gc_thread->gc_thread_started = true;
    gc_thread->gc_running        = true;
    gc_thread->gc_exit           = false;

    thread = gc_thread->gc_thread;

    ret = pthread_create((pthread_t *)&thread,
                         (const pthread_attr_t *)NULL,
                         MEM_gcThreadFunc,
                         (void *)allocator);
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
    gc_thread->gc_running = true;
    pthread_cond_signal(&gc_thread->gc_cond);
  }

  pthread_mutex_unlock(&gc_thread->gc_lock);

function_output:
  return ret;
}

/** ============================================================================
 *  @brief  Stop the GC thread and perform a final collection.
 *
 *  This function clears gc_running and sets gc_exit, signals gc_cond to wake
 *  the GC thread if it’s running, then joins it.  After the thread exits, it
 *  runs one final MEM_gcMark() + MEM_gcSweep() on the caller thread to
 *  reclaim any remaining garbage, then clears gc_thread_started.
 *
 *  @param[in]  allocator Pointer to the mem_allocator_t context.
 *
 *  @return Integer status code.
 *
 *  @retval EXIT_SUCCESS: GC thread stopped and final collection done.
 *  @retval -EINVAL:      @p allocator is NULL.
 *  @retval ret<0:        Error code from pthread MEM_gcMark(), or
 * MEM_gcSweep().
 * ========================================================================== */
static int MEM_stopGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

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

  gc_thread->gc_running = false;
  gc_thread->gc_exit    = true;

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

    gc_thread->gc_thread_started = false;
  }

function_output:
  return ret;
}

/** ============================================================================
 *          P U B L I C  F U N C T I O N S  D E F I N I T I O N S
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
void *MEM_allocMallocFirstFit(mem_allocator_t *const allocator,
                              const size_t           size,
                              const char *const      var)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret
    = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, FIRST_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
void *MEM_allocMallocBestFit(mem_allocator_t *const allocator,
                             const size_t           size,
                             const char *const      var)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, BEST_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
void *MEM_allocMallocNextFit(mem_allocator_t *const allocator,
                             const size_t           size,
                             const char *const      var)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, NEXT_FIT);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
void *MEM_allocMalloc(mem_allocator_t *const      allocator,
                      const size_t                size,
                      const char *const           var,
                      const allocation_strategy_t strategy)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, var, strategy);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
void *MEM_allocCalloc(mem_allocator_t *const      allocator,
                      const size_t                size,
                      const char *const           var,
                      const allocation_strategy_t strategy)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorCalloc(allocator, size, __FILE__, __LINE__, var, strategy);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
void *MEM_allocRealloc(mem_allocator_t *const      allocator,
                       void *const                 ptr,
                       const size_t                new_size,
                       const char *const           var,
                       const allocation_strategy_t strategy)
{
  void *ret = (void *)NULL;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

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
int MEM_allocFree(mem_allocator_t *const allocator,
                  void *const            ptr,
                  const char *const      var)
{
  int ret = EXIT_SUCCESS;

  gc_thread_t *gc_thread = (gc_thread_t *)NULL;

  gc_thread = &allocator->gc_thread;

  pthread_mutex_lock(&gc_thread->gc_lock);
  ret = MEM_allocatorFree(allocator, ptr, __FILE__, __LINE__, var);
  pthread_mutex_unlock(&gc_thread->gc_lock);

  return ret;
}

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
int MEM_enableGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  ret = MEM_runGc(allocator);

  return ret;
}

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
int MEM_disableGc(mem_allocator_t *const allocator)
{
  int ret = EXIT_SUCCESS;

  ret = MEM_stopGc(allocator);

  return ret;
}

/** @} */

/*< end of file >*/
