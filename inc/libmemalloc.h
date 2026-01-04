/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

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
 *  @version    v3.0.00
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

/*< Implemented >*/
#include "memalloc_utils.h"

/*< Dependencies >*/
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <string.h>

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
 *              P U B L I C  F U N C T I O N  C A L L S  A P I
 * ========================================================================== */

/** ============================================================================
 *  @brief  Allocates memory using the FIRST_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  FIRST_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  size      Number of bytes requested.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocFirstFit(const size_t size)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the BEST_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  BEST_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  size      Number of bytes requested.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocBestFit(const size_t size)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the NEXT_FIT strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with
 *  NEXT_FIT strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  size      Number of bytes requested.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_allocNextFit(const size_t size)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates memory using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorMalloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  size      Number of bytes requested
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the allocated user memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_alloc(const size_t                size,
                                  const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Allocates and zero‐initializes memory using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorCalloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  size      Number of bytes requested.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the allocated zeroed memory on success,
 *          or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_calloc(const size_t                size,
                                   const allocation_strategy_t strategy)
  __LIBMEMALLOC_MALLOC;

/** ============================================================================
 *  @brief  Reallocates memory with safety checks using the specified strategy.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorRealloc() with the
 *  given @p strategy, automatically supplying __FILE__, __LINE__, and variable
 *  name for debugging, then unlocks the mutex.
 *
 *  @param[in]  ptr       Pointer to existing memory.
 *  @param[in]  new_size  New requested size.
 *  @param[in]  strategy  Allocation strategy.
 *
 *  @return Pointer to the reallocated memory on success (may be same as @p
 * ptr), or an error‐encoded pointer (via PTR_ERR()) on failure.
 * ========================================================================== */
__LIBMEMALLOC_API void *MEM_realloc(void *const                 ptr,
                                    const size_t                new_size,
                                    const allocation_strategy_t strategy)
  __LIBMEMALLOC_REALLOC;

/** ============================================================================
 *  @brief  Releases allocated memory back to the heap.
 *
 *  This function locks the GC mutex, invokes MEM_allocatorFree() with
 *  automatically supplied __FILE__, __LINE__, and variable name for debugging,
 *  then unlocks the mutex.
 *
 *  @param[in]  ptr       Pointer to memory to free.
 *
 *  @return EXIT_SUCCESS on success,
 *          negative error code on failure.
 * ========================================================================== */
__LIBMEMALLOC_API int MEM_free(void *const ptr);

/** ============================================================================
 *          G A R B A G E  C O L L E C T O R  F U N C T I O N S
 * ========================================================================== */

#if defined(GARBACE_COLLECTOR)

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

#endif

/*< C++ Compatibility >*/
#ifdef __cplusplus
}
#endif

/** @} */

/*< end of header file >*/
