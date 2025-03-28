/** ================================================================
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
 *  @version    v2.0.00.00
 *  @date       27.03.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ================================================================ */

/** ===============================================================
 *                  P R I V A T E  I N C L U D E S                  
 * ================================================================ */

/*< Dependencies >*/
#include <stdio.h>
#include <stdint.h>
#include <stddef.h>
#include <errno.h>
#include <stdarg.h>
#include <inttypes.h>
#include <stdlib.h>

/*< Implemented >*/
#include "logs.h"
#include "libmemalloc.h"

/** ===============================================================
 *          P R I V A T E  D E F I N E S  &  M A C R O S            
 * ================================================================ */

/** =============================================================
 *  @def        MAGIC_NUMBER
 *  @brief      Magic number to validate memory blocks.
 *
 *  @details    This constant is used to verify the integrity of
 *              allocated memory blocks and detect corruption.
 * ============================================================= */
#define MAGIC_NUMBER    (uint32_t)(0xBEEFDEADU)

/** =============================================================
 *  @def        CANARY_VALUE
 *  @brief      Canary value to detect buffer overflows.
 *
 *  @details    This constant is placed at the boundaries of
 *              memory allocations to detect buffer overflows.
 * ============================================================= */
#define CANARY_VALUE    (uint32_t)(0xDEADBEEFULL)

/** ============================================================== 
 *  @def        PREFETCH_MULT  
 *  @brief      Prefetch optimization multiplier constant  
 * 
 *  @details    64-bit repeating byte pattern (0x01 per byte) used 
 *              for efficient  memory block operations. Enables
 *              single-byte value replication across full register 
 *              width in vectorized operations.  
 * ============================================================= */
#define PREFETCH_MULT   (uint64_t)(0x0101010101010101ULL)

/** =============================================================
 *  @def        BYTES_PER_CLASS  
 *  @brief      Fixed byte allocation per classification unit  
 * 
 *  @details    Defines the number of bytes assigned to each 
 *              classification category. Ensures memory alignment 
 *              and efficient block processing in data structures.  
 * ============================================================= */
#define BYTES_PER_CLASS (uint8_t)(128U)

/** =============================================================
 *  @def        MIN_BLOCK_SIZE
 *  @brief      Defines the minimum memory block size.
 *
 *  @details    Ensures each memory block is large enough to hold
 *              a block header and alignment padding.
 * ============================================================= */
#define MIN_BLOCK_SIZE  (size_t)(sizeof(block_header_t) + ARCH_ALIGNMENT)

/** =============================================================
 *  @def        LIKELY(x)
 *  @brief      Compiler hint for likely branch prediction.
 *
 *  @param [in] x   Condition that is likely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be true.
 * ============================================================= */
#define LIKELY(x)       (_Bool)(__builtin_expect(!!(x), 1))

/** =============================================================
 *  @def        UNLIKELY(x)
 *  @brief      Compiler hint for unlikely branch prediction.
 *
 *  @param [in] x   Condition that is unlikely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be false.
 * ============================================================= */
#define UNLIKELY(x)     (_Bool)(__builtin_expect(!!(x), 0))

/** ===============================================================
 *      P R I V A T E  F U N C T I O N S  P R O T O T Y P E S       
 * =============================================================== */

/** ============================================================== 
 *  @fn         MEM_validateBlock
 *  @brief      Validates the integrity and boundaries of a 
 *              memory block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to validate
 *
 *  @return     Integer status code indicating validation result
 * 
 *  @retval     SUCCESS:            Block is valid
 *  @retval     -EINVAL:            Invalid NULL parameters
 *  @retval     -EFAULT:            Block outside heap boundaries
 *  @retval     -ENOTRECOVERABLE:   Invalid magic number
 *  @retval     -EPROTO:            Corrupted header canary
 *  @retval     -EOVERFLOW:         Data canary corruption
 *  @retval     -EFBIG:             Block size exceeds heap end
 * ============================================================= */
static int MEM_validateBlock(mem_allocator_t *const allocator, block_header_t *const block);

/** ============================================================== 
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
 * ============================================================= */
static inline int MEM_getSizeClass(mem_allocator_t *const allocator, const size_t size);

/** ============================================================== 
 *  @fn         MEM_insertFreeBlock
 *  @brief      Inserts a block into the appropriate free list 
 *              based on its size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to insert into the free list
 *
 *  @return     Integer status code indicating operation result
 * 
 *  @retval     SUCCESS:    Block successfully inserted
 *  @retval     -EINVAL:    Invalid arguments or size class
 * ============================================================= */
static inline int MEM_insertFreeBlock(mem_allocator_t *const allocator, block_header_t *const block);

/** ============================================================== 
 *  @fn         MEM_removeFreeBlock
 *  @brief      Removes a block from its free list
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to remove
 *
 *  @return     Integer status code
 * 
 *  @retval     SUCCESS:    Block removed successfully
 *  @retval     -EINVAL:    Invalid arguments or size class
 * ============================================================= */
static inline int MEM_removeFreeBlock(mem_allocator_t *const allocator, block_header_t *const block);

/** ============================================================== 
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
 *  @retval     SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:    No suitable block found in free lists
 * ============================================================= */
static int MEM_findFirstFit(mem_allocator_t *const allocator, const size_t size, block_header_t **fit_block);

/** ============================================================== 
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
 *  @retval     SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters
 *  @retval     -ENOMEM:    No suitable block found in heap
 * ============================================================= */
static int MEM_findNextFit(mem_allocator_t *const allocator, const size_t size, block_header_t **fit_block);

/** ============================================================== 
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
 *  @retval     SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:    No suitable block found in free lists
 * ============================================================= */
static int MEM_findBestFit(mem_allocator_t *const allocator, const size_t size, block_header_t **best_fit);

/** ============================================================== 
 *  @fn         MEM_mergeBlocks
 *  @brief      Merges adjacent free memory blocks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to merge with neighbors
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Blocks merged successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted blocks
 *
 *  @note       Merges with both previous and next blocks if possible
 * ============================================================= */
static int MEM_mergeBlocks(mem_allocator_t *const allocator, block_header_t *const block);

/** ============================================================== 
 *  @fn         MEM_splitBlock
 *  @brief      Splits a memory block into allocated and free portions
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to split
 *  @param[in]  req_size    Requested allocation size
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Block split successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted block
 * 
 *  @note       If remaining space < MIN_BLOCK_SIZE, uses entire block
 * ============================================================= */
static int MEM_splitBlock(mem_allocator_t *const allocator, block_header_t *const block, const size_t req_size);

/** ============================================================== 
 *  @fn         MEM_mergeBlocks
 *  @brief      Merges adjacent free memory blocks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to merge with neighbors
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Blocks merged successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted blocks
 * ============================================================= */
static int MEM_mergeBlocks(mem_allocator_t *const allocator, block_header_t *block);

/** ============================================================== 
 *  @fn         MEM_registerRoot
 *  @brief      Registers a root pointer for garbage collection
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  root        Pointer to register as root
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Root registered successfully
 *  @retval     -ENOMEM:    Failed to expand roots array
 * ============================================================= */
static int MEM_registerRoot(mem_allocator_t *const allocator, void *const root);

/** ============================================================== 
 *  @fn         MEM_gcMarkPointer
 *  @brief      Marks a valid heap pointer for garbage collection
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to validate and mark
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Pointer marked successfully
 *  @retval     -EINVAL:    Invalid pointer or out of heap range
 * ============================================================= */
static int MEM_gcMarkPointer(mem_allocator_t *const allocator, void *const ptr);

/** ============================================================== 
 *  @fn         MEM_gcMarkBlockRecursive
 *  @brief      Recursively marks all reachable blocks from starting block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Starting block header for recursive marking
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    All reachable blocks marked
 *  @retval     -EINVAL:    Invalid block or already marked
 * ============================================================= */
static int MEM_gcMarkBlockRecursive(mem_allocator_t *const allocator, block_header_t *const block);

/** ============================================================== 
 *  @fn         MEM_gcMark
 *  @brief      Executes garbage collection marking phase
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Marking completed successfully
 *  @retval     -EINVAL:    Error during root marking
 * ============================================================= */
static int MEM_gcMark(mem_allocator_t *const allocator);

/** ============================================================== 
 *  @fn         MEM_gcSweep
 *  @brief      Executes garbage collection sweeping phase
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Sweeping completed successfully
 *  @retval     -EINVAL:    Error during block merging
 * ============================================================= */
static int MEM_gcSweep(mem_allocator_t *const allocator);

/** ===============================================================
 *          F U N C T I O N S  D E F I N I T I O N S                
 * =============================================================== */

/** ============================================================== 
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
 * ============================================================= */
void *MEM_memset(void *const source, const int value, const size_t size)
{
    void *ret = NULL;
    unsigned char *ptr = NULL;
    unsigned char *ptr_aux = NULL;
    size_t iterator = 0u;

    if (UNLIKELY((source == NULL) || (size <= 0)))
    {
        ret = (void *)(-EINVAL);
        LOG_ERROR("Invalid memset arguments: source=%p, size=%zu. "
                  "Error code: %d.", 
                  source, size, (int)(intptr_t)ret);
        goto function_output;
    }

    ptr = (unsigned char *)source;

    if ((uintptr_t)ptr % ARCH_ALIGNMENT != 0)
    {
        while ((iterator < size) && ((uintptr_t)(ptr + iterator) % ARCH_ALIGNMENT != 0))
        {
            ptr[iterator] = (unsigned char)value;
            iterator++;
        }
    }

    for ( ; (size_t)(iterator + ARCH_ALIGNMENT) <= size ; iterator += (size_t)ARCH_ALIGNMENT)
    {
        *(uint64_t *)(ptr + iterator) = ((uint64_t)(unsigned char)value) * PREFETCH_MULT;
        __builtin_prefetch(((ptr + iterator) + 64u), 1u, 1u);
    }

    ptr_aux = (unsigned char *)(ptr + iterator);
    while (iterator < size)
    {
        *ptr_aux++ = (unsigned char)value;
        iterator++;
    }

    ret = source;
    LOG_INFO("Memory set: source=%p, value=0x%X, size=%zu.", source, value, size);

function_output:
    return ret;
}

/** ============================================================== 
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
 * ============================================================= */
void *MEM_memcpy(void *const dest, const void *src, const size_t size)
{
    void *ret = NULL;
    unsigned char *destine = NULL;
    unsigned char *destine_aux = NULL;
    const unsigned char *source = NULL;
    size_t iterator = 0u;

    if (UNLIKELY((dest == NULL) || (src == NULL) || (size <= 0)))
    {
        ret = (void *)(-EINVAL);
        LOG_ERROR("Invalid memcpy arguments: dest=%p, src=%p, size=%zu. "
                  "Error code: %d.", 
                  dest, src, size, (int)(intptr_t)ret);
        goto function_output;
    }

    destine = (unsigned char *)dest;
    source = (const unsigned char *)src;

    if ((uintptr_t)destine % ARCH_ALIGNMENT != 0) 
    {
        while ((iterator < size) && ((uintptr_t)(destine + iterator) % ARCH_ALIGNMENT != 0)) 
        {
            destine[iterator] = source[iterator];
            iterator++;
        }
    }

    for ( ; (size_t)(iterator + ARCH_ALIGNMENT) <= size; iterator += (size_t)ARCH_ALIGNMENT)
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
    LOG_INFO("Memory copied: dest=%p, src=%p, size=%zu.", dest, src, size);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_newBrk
 *  @brief      Sets new heap boundary for memory allocator
 *
 *  @param[in]  allocator    Memory allocator context
 *  @param[in]  new_break    Target end address for heap
 *
 *  @return     Operation status code
 * 
 *  @retval     SUCCESS:    Function success
 *  @retval     -EINVAL:    Invalid parameters or address out 
 *  @retval     -ENOMEM:    address out of heap bounds 
 * ============================================================= */
int MEM_newBrk(mem_allocator_t *const allocator, void *const new_break)
{
    int ret = SUCCESS;
    uint8_t *heap_start = NULL;
    uint8_t *heap_max = NULL;
    uint8_t *new_end = NULL;

    if (UNLIKELY(allocator == NULL || new_break == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid arguments: (allocator=%p, new_break=%p). "
                  "Error code: %d.\n", (void*)allocator, (void*)new_break, ret);
        goto end_of_function;
    }

    heap_start = allocator->heap;
    heap_max = (uint8_t*)(heap_start + allocator->heap_size);
    new_end = (uint8_t*)new_break;

    if (new_end < heap_start || new_end > heap_max)
    {
        ret = -ENOMEM;
        LOG_ERROR("Invalid new break address (heap=[%p-%p], requested=%p). "
                  "Error code: %d.\n", (void*)heap_start, (void*)heap_max, (void*)new_end, ret);
        goto end_of_function;
    }

    allocator->heap_end = (uint8_t *)new_end;
    LOG_INFO("New break successfully set to %p.\n", (void*)new_end);

end_of_function:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_newSbrk
 *  @brief      Adjusts heap boundary by specified increment
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  increment   Signed offset to move break pointer
 *
 *  @return     Previous break address on success, 
 *              error code cast to void* on failure
 * 
 *  @retval     Previous brk:   Successful operation
 *  @retval     -EINVAL:        (cast to void*) Invalid parameters
 *  @retval     -ENOMEM:        (cast to void*) Heap overflow
 * ============================================================= */
void *MEM_newSbrk(mem_allocator_t *const allocator, const intptr_t increment)
{
    void *ret = NULL;
    uint8_t *new_end = NULL;
    uint8_t *heap_start = NULL;
    uint8_t *heap_max = NULL;

    if (UNLIKELY(allocator == NULL))
    {
        ret = (void *)(-EINVAL);
        LOG_ERROR("Invalid allocator: NULL. "
                  "Error code: %d.\n", (int)(intptr_t)ret);
        goto function_output;
    }

    heap_start = allocator->heap;
    heap_max = heap_start + allocator->heap_size;

    if ((increment > 0) && (((intptr_t)allocator->heap_end + increment) < (intptr_t)allocator->heap_end))
    {
        ret = (void *)(-ENOMEM);
        LOG_ERROR("Pointer overflow detected. "
                  "Error code: %d.\n", (int)(intptr_t)ret);
        goto function_output;
    }

    if ((increment < 0) && (((intptr_t)allocator->heap_end + increment) > (intptr_t)allocator->heap_end))
    {
        ret = (void *)(-ENOMEM);
        LOG_ERROR("Pointer underflow detected. "
                  "Error code: %d.\n", (int)(intptr_t)ret);
        goto function_output;
    }

    new_end = allocator->heap_end + increment;

    if ((new_end < heap_start) || (new_end > heap_max))
    {
        ret = (void *)(-ENOMEM);
        LOG_ERROR("Heap overflow: attempted to move break to %p (heap range: [%p - %p]). "
                  "Error code: %d.\n", (void *)new_end, (void *)heap_start, (void *)heap_max, (int)(intptr_t)ret);
        goto function_output;
    }

    ret = allocator->heap_end;
    allocator->heap_end = new_end;
    LOG_INFO("Heap break moved from %p to %p (increment: %" PRIdPTR ").", ret, (void *)new_end, increment);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_validateBlock
 *  @brief      Validates the integrity and boundaries of a 
 *              memory block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to validate
 *
 *  @return     Integer status code indicating validation result
 * 
 *  @retval     SUCCESS:            Block is valid
 *  @retval     -EINVAL:            Invalid NULL parameters
 *  @retval     -EFAULT:            Block outside heap boundaries
 *  @retval     -ENOTRECOVERABLE:   Invalid magic number
 *  @retval     -EPROTO:            Corrupted header canary
 *  @retval     -EOVERFLOW:         Data canary corruption
 *  @retval     -EFBIG:             Block size exceeds heap end
 * ============================================================= */
static int MEM_validateBlock(mem_allocator_t *const allocator, block_header_t *const block)
{
    int ret = SUCCESS;
    uint32_t *data_canary = NULL;

    if (UNLIKELY((allocator == NULL) || (block == NULL)))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid NULL parameter. Allocator: %p, Block: %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    if (((uint8_t *)block < allocator->heap) || ((uint8_t *)block >= allocator->heap_end))
    {
        ret = -EFAULT;
        LOG_ERROR("Block %p outside heap boundaries [%p - %p]. "
                  "Error code: %d.\n", (void *)block, (void *)allocator->heap, (void *)allocator->heap_end, ret);
        goto function_output;
    }
 
    if (block->magic != MAGIC_NUMBER)
    {
        ret = -ENOTRECOVERABLE;
        LOG_ERROR("Invalid magic at %p: 0x%X (expected 0x%X). "
                  "Error code: %d.\n", (void *)block, block->magic, MAGIC_NUMBER, ret);
        goto function_output;
    }
 
    if (block->canary != CANARY_VALUE)
    {
        ret = -EPROTO;
        LOG_ERROR("Corrupted header at %p: 0x%X vs 0x%X. "
                  "Error code: %d.\n", (void *)block, block->canary, CANARY_VALUE, ret);
        goto function_output;
    }
 
    data_canary = (uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t));
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
        LOG_ERROR("Structural overflow at %p (size: %zu). Heap range [%p - %p]. "
                  "Error code: %d.\n", (void *)block, block->size, (void *)allocator->heap, (void *)allocator->heap_end, ret);
        goto function_output;
    }

function_output:
    return ret;
}

/** ============================================================== 
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
 * ============================================================= */
static inline int MEM_getSizeClass(mem_allocator_t *const allocator, const size_t size)
{
    int ret = SUCCESS;
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
 
    max_class_size = (size_t)((allocator->num_size_classes - 1u) * BYTES_PER_CLASS);
    index = (size_t)((size + BYTES_PER_CLASS - 1u) / BYTES_PER_CLASS);
 
    if (UNLIKELY(index >= allocator->num_size_classes))
    {
        LOG_WARNING("Size overflow - "
                    "Requested: %zu bytes | Max class: %zu bytes | Clamped to class %zu",
                    size, max_class_size, (allocator->num_size_classes - 1u));
        index = (size_t)(allocator->num_size_classes - 1);
    }
    else
    {
        LOG_INFO("Size class calculated - "
                 "Requested: %zu bytes | Class: %zu (%zu-%zu bytes)",
                 size, index, index * BYTES_PER_CLASS, ((index + 1u) * BYTES_PER_CLASS - 1u));
    }
 
    ret = (int)index;

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_insertFreeBlock
 *  @brief      Inserts a block into the appropriate free list 
 *              based on its size
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to insert into the free list
 *
 *  @return     Integer status code indicating operation result
 * 
 *  @retval     SUCCESS:    Block successfully inserted
 *  @retval     -EINVAL:    Invalid arguments or size class
 * ============================================================= */
static inline int MEM_insertFreeBlock(mem_allocator_t *const allocator, block_header_t *const block)
{
    int ret = SUCCESS;
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

    block->next = allocator->free_lists[index];
    block->prev = NULL;
    if (allocator->free_lists[index])
    {
        allocator->free_lists[index]->prev = block;
    }
    allocator->free_lists[index] = block;
    LOG_INFO("Block %p inserted into free list %d (size: %zu)\n", (void *)block, index, block->size);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_removeFreeBlock
 *  @brief      Removes a block from its free list
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to remove
 *
 *  @return     Integer status code
 * 
 *  @retval     SUCCESS:    Block removed successfully
 *  @retval     -EINVAL:    Invalid arguments or size class
 * ============================================================= */
static inline int MEM_removeFreeBlock(mem_allocator_t *const allocator, block_header_t *const block)
{
    int ret = SUCCESS;
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

    if (block->prev)
    {
        block->prev->next = block->next;
    }
    else
    {
        allocator->free_lists[index] = block->next;
    }
    if (block->next)
    {
        block->next->prev = block->prev;
    }
    block->next = NULL;
    block->prev = NULL;
    LOG_INFO("Block %p removed from free list %d (size: %zu)\n", (void *)block, index, block->size);

function_output:
    return ret;
}

/** ============================================================== 
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
 *  @retval     -ENOMEM:    Failed to allocate free lists or roots
 * ============================================================= */
int MEM_allocatorInit(mem_allocator_t *const allocator)
{
    int ret = SUCCESS;
    block_header_t *initial_block = NULL;
    uint32_t *data_canary = NULL;
    static uint8_t heap_memory[HEAP_SIZE] __attribute__((section(".heap"), aligned(ARCH_ALIGNMENT)));

    if (UNLIKELY(allocator == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameter 'allocator': %p. "
                  "Error code: %d.\n", (void *)allocator, ret);
        goto function_output;
    }
     
    allocator->heap = heap_memory;
    allocator->heap_size = HEAP_SIZE;
    allocator->heap_end = (allocator->heap + HEAP_SIZE);
    allocator->gc_enabled = 1u;
    allocator->last_allocated = NULL;
    allocator->num_size_classes = 10u;
    allocator->free_lists = (block_header_t **)calloc(allocator->num_size_classes, sizeof(block_header_t *));
    if (!allocator->free_lists)
    {
        ret = -ENOMEM;
        LOG_ERROR("Failed to allocate free lists for %zu size classes. "
                  "Error code: %d.\n", allocator->num_size_classes, ret);
        goto function_output;
    }
    allocator->roots_capacity = 10u;
    allocator->roots = (void **)calloc(allocator->roots_capacity, sizeof(void *));
    if (!allocator->roots)
    {
        ret = -ENOMEM;
        LOG_ERROR("Failed to allocate roots array with capacity %lu. "
                  "Error code: %d.\n", allocator->roots_capacity, ret);
        goto function_output;
    }
    allocator->num_roots = 0u;
    initial_block = (block_header_t *)allocator->heap;
    initial_block->magic = MAGIC_NUMBER;
    initial_block->size = HEAP_SIZE;
    initial_block->free = 1u;
    initial_block->marked = 0u;
    initial_block->file = NULL;
    initial_block->line = 0ull;
    initial_block->var_name = NULL;
    initial_block->next = NULL;
    initial_block->prev = NULL;
    initial_block->canary = CANARY_VALUE;
    data_canary = (uint32_t *)((uint8_t *)initial_block + initial_block->size - sizeof(uint32_t));
    *data_canary = CANARY_VALUE;
    MEM_insertFreeBlock(allocator, initial_block);
    allocator->last_allocated = initial_block;
    LOG_INFO("Heap initialized with %zu bytes at %p.\n", allocator->heap_size, (void *)allocator->heap);

function_output:
    return ret;
}
 
/** ============================================================== 
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
 *  @retval     SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:    No suitable block found in free lists
 * ============================================================= */
static int MEM_findFirstFit(mem_allocator_t *const allocator, const size_t size, block_header_t **fit_block)
{
    int ret = SUCCESS;
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

    for (iterator = (size_t)start_class; iterator < allocator->num_size_classes; iterator++)
    {
        current = allocator->free_lists[iterator];
        while (current)
        {
            if ((MEM_validateBlock(allocator, current) == SUCCESS) && (current->free && current->size >= size))
            {
                *fit_block = current;
                ret = SUCCESS;
                goto function_output;
            }
            current = current->next;
        }
    }
    ret = -ENOMEM;
    LOG_WARNING("First-fit allocation failed: Req size: %zu | Max checked class: %zu "
                "Error code: %d.\n", size, (allocator->num_size_classes - 1u), ret);

function_output:
    return ret;
}

/** ============================================================== 
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
 * @retval      SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters
 *  @retval     -ENOMEM:    No suitable block found in heap
 * ============================================================= */
static int MEM_findNextFit(mem_allocator_t *const allocator, const size_t size, block_header_t **fit_block)
{
    int ret = SUCCESS;
    block_header_t *current = NULL;
    block_header_t *start = NULL;

    if (UNLIKELY(allocator == NULL || fit_block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | fit_block %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)fit_block, ret);
        goto function_output;
    }

    current = allocator->last_allocated;
    start = current;

    do 
    {
        if ((MEM_validateBlock(allocator, current) == SUCCESS) && (current->free && current->size >= size))
        {
            *fit_block = current;
            allocator->last_allocated = current;
            goto function_output;
        }
        current = (current->next) ? current->next : (block_header_t *)allocator->heap;
    } while (current != start);

    ret = -ENOMEM;
    LOG_WARNING("Next-fit allocation failed: Req size: %zu | Start block: %p. "
                "Error code: %d.\n", size, (void *)start, ret);

function_output:
    return ret;
}

/** ============================================================== 
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
 *  @retval     SUCCESS:    Suitable block found successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted size class index
 *  @retval     -ENOMEM:    No suitable block found in free lists
 * ============================================================= */
static int MEM_findBestFit(mem_allocator_t *const allocator, const size_t size, block_header_t **best_fit)
{
    int ret = SUCCESS;
    block_header_t *current = NULL;
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

    for (int i = start_class; i < (int)allocator->num_size_classes; i++)
    {
        current = allocator->free_lists[i];
        while (current)
        {
            if ((MEM_validateBlock(allocator, current) == SUCCESS) && (current->free && current->size >= size))
            {
                if (!(*best_fit) || current->size < (*best_fit)->size)
                {
                    *best_fit = current;
                }
            }
            current = current->next;
        }
        if (*best_fit)
        {
            goto function_output;
        }
    }

    ret = -ENOMEM;
    LOG_WARNING("Best-fit allocation failed: Req size: %zu | Max checked class: %zu. Error code: %d.\n", 
                size, (allocator->num_size_classes - 1), ret);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_splitBlock
 *  @brief      Splits a memory block into allocated and free portions
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to split
 *  @param[in]  req_size    Requested allocation size
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Block split successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted block
 * 
 *  @note       If remaining space < MIN_BLOCK_SIZE, uses entire block
 * ============================================================= */
static int MEM_splitBlock(mem_allocator_t *const allocator, block_header_t *const block, const size_t req_size)
{
    int ret = SUCCESS;
    size_t aligned_size = 0u;
    size_t total_size = 0u;
    size_t remaining_size = 0u;
    block_header_t *new_block = NULL;
    uint32_t *data_canary = NULL;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | block %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    if (MEM_validateBlock(allocator, block) != SUCCESS)
    {
        ret = -EINVAL;
        LOG_ERROR("Block validation failed: %p. "
                  "Error code: %d.\n", (void *)block, ret);
        goto function_output;
    }

    aligned_size = ALIGN(req_size);
    total_size = (size_t)(aligned_size + sizeof(block_header_t) + sizeof(uint32_t));

    if (block->size < total_size + MIN_BLOCK_SIZE)
    {
        block->free = 0u;
        MEM_removeFreeBlock(allocator, block);
        block->next = block->prev = NULL;
        LOG_DEBUG("Using full block %p | Req size: %zu | Block size: %zu",
                  (void *)block, req_size, block->size);
        goto function_output;
    }

    remaining_size = (size_t)(block->size - total_size);
    MEM_removeFreeBlock(allocator, block);
    block->next = block->prev = NULL;
    block->size = total_size;
    block->free = 0u;
    block->magic = MAGIC_NUMBER;
    block->canary = CANARY_VALUE;
    data_canary = (uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t));
    *data_canary = CANARY_VALUE;
    new_block = (block_header_t *)((uint8_t *)block + total_size);
    new_block->magic = MAGIC_NUMBER;
    new_block->size = remaining_size;
    new_block->free = 1u;
    new_block->marked = 0u;
    new_block->file = NULL;
    new_block->line = 0ull;
    new_block->var_name = NULL;
    new_block->next = NULL;
    new_block->prev = block;
    new_block->canary = CANARY_VALUE;
    data_canary = (uint32_t *)((uint8_t *)new_block + new_block->size - sizeof(uint32_t));
    *data_canary = CANARY_VALUE;
    block->next = new_block;
    MEM_insertFreeBlock(allocator, new_block);
    LOG_DEBUG("Block split | Original: %p (%zuB) | New: %p (%zuB)",
              (void *)block, block->size, (void *)new_block, new_block->size);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_mergeBlocks
 *  @brief      Merges adjacent free memory blocks
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Block header to merge with neighbors
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Blocks merged successfully
 *  @retval     -EINVAL:    Invalid parameters or corrupted blocks
 * ============================================================= */
static int MEM_mergeBlocks(mem_allocator_t *const allocator, block_header_t *block)
{
    int ret = SUCCESS;
    block_header_t *next_block = NULL;
    block_header_t *prev_block = NULL;
    uint32_t *data_canary = NULL;

    if (UNLIKELY(allocator == NULL || block == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | block %p. "
                  "Error code: %d.\n", (void *)allocator, (void *)block, ret);
        goto function_output;
    }

    if (MEM_validateBlock(allocator, block) != SUCCESS)
    {
        ret = -EINVAL;
        LOG_ERROR("Block validation failed: %p. "
                  "Error code: %d.\n", (void *)block, ret);
        goto function_output;
    }

    next_block = (block_header_t *)((uint8_t *)block + block->size);

    if ((uint8_t *)next_block < allocator->heap_end && next_block->free)
    {
        if (MEM_validateBlock(allocator, next_block) != SUCCESS)
        {
            ret = -EINVAL;
            LOG_ERROR("Next block validation failed: %p. "
                      "Error code: %d.\n", (void *)next_block, ret);
            goto function_output;
        }
        
        MEM_removeFreeBlock(allocator, next_block);
        block->size += next_block->size;
        block->next = next_block->next;
        if (next_block->next)
        {
            next_block->next->prev = block;
        }
        
        data_canary = (uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t));
        *data_canary = CANARY_VALUE;
        LOG_DEBUG("Merged with next block | New size: %zu", block->size);
    }

    if (block->prev && block->prev->free)
    {
        prev_block = block->prev;
        if (MEM_validateBlock(allocator, prev_block) != SUCCESS)
        {
            ret = -EINVAL;
            LOG_ERROR("Prev block validation failed: %p. "
                      "Error code: %d.\n", (void *)prev_block, ret);
            goto function_output;
        }
        
        MEM_removeFreeBlock(allocator, prev_block);
        prev_block->size += block->size;
        prev_block->next = block->next;
        if (block->next)
        {
            block->next->prev = prev_block;
        }
        
        block = prev_block;
        data_canary = (uint32_t *)((uint8_t *)block + block->size - sizeof(uint32_t));
        *data_canary = CANARY_VALUE;
        LOG_DEBUG("Merged with prev block | New size: %zu", block->size);
    }

    MEM_insertFreeBlock(allocator, block);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_registerRoot
 *  @brief      Registers a root pointer for garbage collection
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  root        Pointer to register as root
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Root registered successfully
 *  @retval     -ENOMEM:    Failed to expand roots array
 * ============================================================= */
static int MEM_registerRoot(mem_allocator_t *const allocator, void *const root)
{
    int ret = SUCCESS;
    size_t new_capacity = 0u;
    void **new_roots = NULL;
    
    if (UNLIKELY(allocator == NULL || root == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | root %p. "
                  "Error code: %d.\n", (void *)allocator, root, ret);
        goto function_output;
    }

    if (allocator->num_roots == allocator->roots_capacity)
    {
        new_capacity = (size_t)(allocator->roots_capacity * 2u);
        new_roots = realloc(allocator->roots, new_capacity * sizeof(void *));
        
        if (UNLIKELY(new_roots == NULL))
        {
            ret = -ENOMEM;
            LOG_ERROR("Roots array expansion failed | Capacity: %zu. "
                      "Error code: %d.\n", new_capacity, ret);
            goto function_output;
        }
        
        allocator->roots = new_roots;
        allocator->roots_capacity = new_capacity;
        LOG_DEBUG("Roots array expanded to %zu elements", new_capacity);
    }

    allocator->roots[allocator->num_roots++] = root;
    LOG_DEBUG("Root registered | Count: %zu | Addr: %p", allocator->num_roots, root);

function_output:
    return ret;
}

/** ============================================================== 
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
 * ============================================================= */
void *MEM_allocatorMalloc(mem_allocator_t *const allocator,
                          const size_t size,
                          const char *const file,
                          const int line,
                          const char *const var_name,
                          const allocation_strategy_t strategy)
{
    int ret = SUCCESS;
    void *user_ptr = NULL;
    block_header_t *block = NULL;
    size_t total_size = 0u;

    if (UNLIKELY(allocator == NULL || size == 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters: allocator %p | size %zu. "
                  "Error code: %d.\n", (void *)allocator, size, ret);
        goto function_output;
    }

    total_size = ALIGN(size) + sizeof(block_header_t) + sizeof(uint32_t);

    switch (strategy)
    {
        case FIRST_FIT:
            ret = MEM_findFirstFit(allocator, total_size, &block);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
        break;

        case NEXT_FIT:
            ret = MEM_findNextFit(allocator, total_size, &block);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
        break;

        case BEST_FIT:
            ret = MEM_findBestFit(allocator, total_size, &block);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
        break;

        default:
            ret = -EINVAL;
            LOG_ERROR("Invalid allocation strategy: %d. "
                      "Error code: %d.\n", strategy, ret);
            goto function_output;
        break;
    }

    if (UNLIKELY(ret != SUCCESS || block == NULL))
    {
        ret = -ENOMEM;
        LOG_WARNING("Allocation failed | Size: %zu | Strategy: %d. "
                    "Error code: %d.\n", size, strategy, ret);
        goto function_output;
    }

    MEM_splitBlock(allocator, block, size);
    block->file = file;
    block->line = (unsigned long long)line;
    block->var_name = var_name;
    user_ptr = (uint8_t *)block + sizeof(block_header_t);
    LOG_INFO("Memory allocated | Addr: %p | Size: %zu | Source: %s:%d", user_ptr, size, file, line);

function_output:
    return user_ptr;
}

/** ============================================================== 
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
 * ============================================================= */
void *MEM_allocatorRealloc(mem_allocator_t *const allocator,
                           void *const ptr,
                           const size_t new_size,
                           const char *const file,
                           const int line,
                           const char *const var_name,
                           const allocation_strategy_t strategy)
{
    int ret = SUCCESS;
    void *new_ptr = NULL;
    block_header_t *old_block = NULL;
    size_t old_size = 0u;

    if (UNLIKELY(allocator == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid allocator: %p. "
                  "Error code: %d.\n", (void *)allocator, ret);
        goto function_output;
    }

    if (ptr == NULL)
    {
        new_ptr = MEM_allocatorMalloc(allocator, new_size, file, line, var_name, strategy);
        goto function_output;
    }

    old_block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    if (MEM_validateBlock(allocator, old_block) != SUCCESS)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid block | Addr: %p. "
                  "Error code: %d.\n", ptr, ret);
        goto function_output;
    }

    old_size = (size_t)(old_block->size - sizeof(block_header_t) - sizeof(uint32_t));
    if (old_size >= new_size)
    {
        LOG_DEBUG("Reallocation not needed | Addr: %p | Current size: %zu | New size: %zu",
                  ptr, old_size, new_size);
        new_ptr = ptr;
        goto function_output;
    }

    new_ptr = MEM_allocatorMalloc(allocator, new_size, file, line, var_name, strategy);
    if (new_ptr != NULL)
    {
        if (MEM_memcpy(new_ptr, ptr, old_size) != new_ptr)
        {
            ret = -EINVAL;
            goto function_output;
        }

        ret = MEM_allocatorFree(allocator, ptr, file, line, var_name);
        if (ret != SUCCESS)
        {
            goto function_output;
        }

        LOG_INFO("Memory reallocated | Old: %p | New: %p | Size: %zu",
                 ptr, new_ptr, new_size);
    }

function_output:
    return new_ptr;
}

/** ============================================================== 
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
 * ============================================================= */
void *MEM_allocatorCalloc(mem_allocator_t *const allocator,
                          const size_t num,
                          const size_t size,
                          const char *const file,
                          const int line,
                          const char *const var_name,
                          const allocation_strategy_t strategy)
{
    int ret = SUCCESS;
    void *ptr = NULL;
    size_t total = 0u;

    if (UNLIKELY(allocator == NULL || num == 0 || size == 0))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters | Allocator: %p | Num: %zu | Size: %zu. "
                  "Error code: %d.\n", (void *)allocator, num, size, ret);
        goto function_output;
    }

    total = (size_t)(num * size);
    ptr = MEM_allocatorMalloc(allocator, total, file, line, var_name, strategy);
    
    if (ptr != NULL)
    {
        if (MEM_memset(ptr, 0, total) != ptr)
        {
            ret = -EINVAL;
            goto function_output;
        }

        LOG_DEBUG("Zero-initialized memory | Addr: %p | Size: %zu", ptr, total);
    }

function_output:
    return ptr;
}

/** ============================================================== 
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
 * ============================================================= */
int MEM_allocatorFree(mem_allocator_t *const allocator,
                      void *const ptr,
                      const char *const file,
                      const int line,
                      const char *const var_name)
{
    int ret = SUCCESS;
    block_header_t *block = NULL;

    if (UNLIKELY(allocator == NULL || ptr == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid parameters | Allocator: %p | Ptr: %p. "
                  "Error code: %d.\n", (void *)allocator, ptr, ret);
        goto function_output;
    }

    block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    if (MEM_validateBlock(allocator, block) != SUCCESS)
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid block | Addr: %p | Source: %s:%d. "
                  "Error code: %d.\n", ptr, file, line, ret);
        goto function_output;
    }

    block->free = 1u;
    block->marked = 0u;
    block->file = file;
    block->line = (unsigned long long)line;
    block->var_name = var_name;
    
    MEM_mergeBlocks(allocator, block);
    LOG_INFO("Memory freed | Addr: %p | Source: %s:%d", ptr, file, line);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_gcMarkPointer
 *  @brief      Marks a valid heap pointer for garbage collection
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  ptr         Pointer to validate and mark
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Pointer marked successfully
 *  @retval     -EINVAL:    Invalid pointer or out of heap range
 * ============================================================= */
static int MEM_gcMarkPointer(mem_allocator_t *const allocator, void *const ptr)
{
    int ret = SUCCESS;
    block_header_t *block = NULL;

    if (UNLIKELY(ptr == NULL || 
        (uint8_t *)ptr < allocator->heap || 
        (uint8_t *)ptr >= allocator->heap_end))
    {
        ret = -EINVAL;
        LOG_DEBUG("Invalid pointer for marking: %p. "
                  "Error code: %d.\n", ptr, ret);
        goto function_output;
    }

    block = (block_header_t *)((uint8_t *)ptr - sizeof(block_header_t));
    if (UNLIKELY((uint8_t *)block < allocator->heap || 
               (uint8_t *)block >= allocator->heap_end || 
               block->free))
    {
        ret = -EINVAL;
        LOG_WARNING("Invalid block during marking: %p. "
                    "Error code: %d.\n", (void *)block, ret);
        goto function_output;
    }

    block->marked = 1u;
    LOG_INFO("Block marked | Addr: %p", (void *)block);

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_gcMarkBlockRecursive
 *  @brief      Recursively marks all reachable blocks from starting block
 *
 *  @param[in]  allocator   Memory allocator context
 *  @param[in]  block       Starting block header for recursive marking
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    All reachable blocks marked
 *  @retval     -EINVAL:    Invalid block or already marked
 * ============================================================= */
static int MEM_gcMarkBlockRecursive(mem_allocator_t *const allocator, block_header_t *const block)
{
    int ret = SUCCESS;
    size_t data_size = 0u;
    size_t iterator = 0u;
    uint8_t *data = NULL;

    if (UNLIKELY(block == NULL || block->marked))
    {
        ret = -EINVAL;
        LOG_DEBUG("Invalid pointer for marking: %p. "
                  "Error code: %d.\n", (void *)block, ret);
        goto function_output;
    }

    block->marked = 1u;
    LOG_INFO("Recursive marking | Block: %p", (void *)block);

    data = (uint8_t *)block + sizeof(block_header_t);
    data_size = block->size - sizeof(block_header_t) - sizeof(uint32_t);

    for (iterator = 0u; (size_t)(iterator + sizeof(void *)) <= data_size; iterator += sizeof(void *))
    {
        void *possible_ptr = *(void **)(data + iterator);
        ret = MEM_gcMarkPointer(allocator, possible_ptr);
        if (ret != SUCCESS)
        {
            goto function_output;
        }
    }

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_gcMark
 *  @brief      Executes garbage collection marking phase
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Marking completed successfully
 *  @retval     -EINVAL:    Error during root marking
 * ============================================================= */
static int MEM_gcMark(mem_allocator_t *const allocator)
{
    int ret = SUCCESS;
    size_t itertor = 0u;
    block_header_t *current = NULL;

    for (itertor = 0u; itertor < allocator->num_roots; itertor++)
    {
        if (allocator->roots[itertor])
        {
            ret = MEM_gcMarkPointer(allocator, allocator->roots[itertor]);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
        }
    }

    current = (block_header_t *)allocator->heap;

    while ((uint8_t *)current < allocator->heap_end)
    {
        if (!current->free)
        {
            ret = MEM_gcMarkBlockRecursive(allocator, current);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
        }
        current = (block_header_t *)((uint8_t *)current + current->size);
    }

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_gcSweep
 *  @brief      Executes garbage collection sweeping phase
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Sweeping completed successfully
 *  @retval     -EINVAL:    Error during block merging
 * ============================================================= */
static int MEM_gcSweep(mem_allocator_t *const allocator)
{
    int ret = SUCCESS;
    block_header_t *current = NULL;
    current = (block_header_t *)allocator->heap;

    while ((uint8_t *)current < allocator->heap_end)
    {
        if (!current->free && !current->marked)
        {
            current->free = 1u;
            ret = MEM_mergeBlocks(allocator, current);
            if (ret != SUCCESS)
            {
                goto function_output;
            }
            LOG_DEBUG("Memory reclaimed | Block: %p | Size: %zu",
                      (void *)current, current->size);
        }

        current->marked = 0u;
        current = (block_header_t *)((uint8_t *)current + current->size);
    }

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_runGC
 *  @brief      Executes complete garbage collection cycle
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    GC cycle completed successfully
 *  @retval     -EINVAL:    Invalid parameters or GC disabled
 * ============================================================= */
int MEM_runGC(mem_allocator_t *const allocator)
{
    int ret = SUCCESS;

    if (UNLIKELY(allocator == NULL || !allocator->gc_enabled))
    {
        ret = -EINVAL;
        LOG_WARNING("GC execution skipped | GC Enabled: %d", allocator ? allocator->gc_enabled : 0);
        goto function_output;
    }

    LOG_INFO("Starting garbage collection");

    ret = MEM_gcMark(allocator);
    if (ret != SUCCESS)
    {
        goto function_output;
    }

    ret = MEM_gcSweep(allocator);
    if (ret != SUCCESS)
    {
        goto function_output;
    }

    LOG_INFO("Garbage collection completed");

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_allocatorPrintAll
 *  @brief      Prints detailed heap status information
 *
 *  @param[in]  allocator   Memory allocator context
 *
 *  @return     Integer status code
 *
 *  @retval     SUCCESS:    Heap information printed
 *  @retval     -EINVAL:    Invalid allocator parameter
 * ============================================================= */
int MEM_allocatorPrintAll(mem_allocator_t *const allocator)
{
    int ret = SUCCESS;
    block_header_t *current = NULL;

    if (UNLIKELY(allocator == NULL))
    {
        ret = -EINVAL;
        LOG_ERROR("Invalid allocator parameter. "
                  "Error code: %d.\n", ret);
        goto function_output;
    }

    printf("\nHeap Status Report:\n");
    printf("Address\t\tSize\tFree\tOrigin\n");
    printf("------------------------------------------------\n");
    
    current = (block_header_t *)allocator->heap;
    while ((uint8_t *)current < allocator->heap_end)
    {
        printf("%p\t%zu\t%s\t%s:%lld\n",
               (void *)((uint8_t *)current + sizeof(block_header_t)),
               current->size - sizeof(block_header_t) - sizeof(uint32_t),
               current->free ? "Yes" : "No",
               current->file ? current->file : "N/A",
               current->line);
        
        current = (block_header_t *)((uint8_t *)current + current->size);
    }

    LOG_DEBUG("Heap status printed successfully");

function_output:
    return ret;
}

/** ============================================================== 
 *  @fn         MEM_alloca
 *  @brief      Allocates memory on the stack with 
 *              architecture-specific handling
 *
 *  @param[in]  size        Requested allocation size
 *
 *  @return     Pointer to allocated stack memory or NULL
 *
 *  @retval     void*:      Successfully allocated stack memory
 *  @retval     NULL:       Invalid size or architecture not supported
 * ============================================================= */
void *MEM_alloca(const size_t size)
{
    void *ptr = NULL;
    size_t aligned_size = 0u;
    aligned_size = ALIGN(size);

    if (aligned_size > 1024)
    {
        LOG_ERROR("Requested size (%zu) exceeds safe limit", aligned_size);
        ptr = NULL;
        goto function_output;
    }

#if defined(__x86_64__) || defined(_M_X64)
    /* x86-64 (64-bit) implementation */
    __asm__ volatile (
        "subq %[size], %%rsp\n\t"   /* 1. Subtract size from stack pointer */
        "movq %%rsp, %[output]"     /* 2. Store stack pointer in output */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "memory"
    );

#elif defined(__i386__) || defined(_M_IX86)
    /* x86 (32-bit) implementation */
    __asm__ volatile (
        "subl %[size], %%esp\n\t"   /* 1. Adjust stack pointer */
        "movl %%esp, %[output]"     /* 2. Store ESP in output */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "memory"
    );

#elif defined(__aarch64__) || defined(_M_ARM64)
    /* ARM64 (AArch64) implementation */
    __asm__ volatile (
        "sub sp, sp, %[size]\n\t"   /* 1. Decrement stack pointer */
        "mov %[output], sp"         /* 2. Move SP to output register */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "memory"
    );

#elif defined(__riscv) && (__riscv_xlen == 64)
    /* RISC-V 64-bit implementation */
    __asm__ volatile (
        "sub sp, sp, %[size]\n\t"   /* 1. Adjust stack pointer */
        "mv %[output], sp"          /* 2. Store SP in output */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "memory"
    );

#elif defined(__powerpc64__)
    /* PowerPC 64-bit implementation */
    __asm__ volatile (
        "subf 1, %[size], 1\n\t"   /* 1. Subtract from stack pointer (r1) */
        "mr %[output], 1"           /* 2. Move r1 to output register */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "memory"
    );

#elif defined(__AVR__)
    /* AVR (8-bit) implementation */
    __asm__ volatile (
        "in r28, __SP_L__\n\t"      /* 1. Load SP low byte */
        "in r29, __SP_H__\n\t"      /* 2. Load SP high byte */
        "sub r28, %A[size]\n\t"     /* 3. Subtract size low byte */
        "sbc r29, %B[size]\n\t"     /* 4. Subtract size high byte with carry */
        "out __SP_H__, r29\n\t"     /* 5. Update SP high byte */
        "out __SP_L__, r28\n\t"     /* 6. Update SP low byte */
        "movw %[output], r28"       /* 7. Move 16-bit SP to output */
        : [output] "=r" (ptr)
        : [size] "r" (aligned_size)
        : "r28", "r29", "memory"
    );

#else
    #error "MEM_alloca: Unsupported architecture"
    LOG_ERROR("Architecture not supported");
    ptr = NULL;
#endif

function_output:
    if (ptr == NULL)
    {
        LOG_WARNING("MEM_alloca: Allocation failed | Size: %zu", aligned_size);
    }
    else
    {
        LOG_DEBUG("MEM_alloca: Allocated %zu bytes at %p", aligned_size, ptr);
    }
    
    return ptr;
}

/*< end of file >*/
