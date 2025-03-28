/** ===============================================================
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
 *              - Block validation with magic numbers/canaries
 *              - Multiple allocation strategies (First/Best/Next Fit)
 *
 *  @version    v2.0.00.00
 *  @date       27.03.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ================================================================ */

#ifndef LIBMEMALLOC_H_
#define LIBMEMALLOC_H_

/*< C++ Compatibility >*/
#ifdef __cplusplus
    extern "C" {
#endif

/** ===============================================================
 *                  P U B L I C  I N C L U D E S                    
 * ================================================================ */

/*< Dependencies >*/
#include <stdint.h>
#include <string.h>

/** ===============================================================
 *          P U B L I C  D E F I N E S  &  M A C R O S              
 * ================================================================ */

/** ==============================================================
 *  @def        ARCH_ALIGNMENT
 *  @brief      Defines architecture-specific memory alignment.
 *
 *  @details    Determines the appropriate memory alignment based
 *              on the current target architecture.
 * ============================================================== */
#if defined(__x86_64__) || defined(_M_X64)

    #define ARCH_ALIGNMENT ((uint8_t)8U)    /**< x86_64 (CISC 64 bits) */

#elif defined(__i386__) || defined(_M_IX86)

    #define ARCH_ALIGNMENT ((uint8_t)4U)    /**< x86 (CISC 32 bits) */

#elif defined(__aarch64__) || defined(_M_ARM64)

    #define ARCH_ALIGNMENT ((uint8_t)8U)    /**< ARM (64 bits) */

#elif defined(__arm__) || defined(_M_ARM)

    #define ARCH_ALIGNMENT ((uint8_t)4U)    /**< ARM (32 bits) */

#elif defined(__riscv) && (__riscv_xlen == 64)

    #define ARCH_ALIGNMENT ((uint8_t)8U)    /**< RISC-V (64 bits) */

#elif defined(__riscv) && (__riscv_xlen == 32)

    #define ARCH_ALIGNMENT ((uint8_t)4U)    /**< RISC-V (32 bits) */

#elif defined(__powerpc64__)

    #define ARCH_ALIGNMENT ((uint8_t)8U)    /**< PowerPC (64 bits) */

#elif defined(__powerpc__)

    #define ARCH_ALIGNMENT ((uint8_t)4U)    /**< PowerPC (32 bits) */

#elif defined(__AVR__)

    #define ARCH_ALIGNMENT ((uint8_t)2U)    /**< AVR (8 bits) */

#else

    #define ARCH_ALIGNMENT ((uint8_t)4U)    /**< Fallback */

#endif

/** =============================================================
 *  @def        ALIGN(x)
 *  @brief      Aligns a given value to the nearest memory boundary.
 *
 *  @param [in] x  Value to be aligned.
 *
 *  @details    Uses bitwise operations to align the value to the
 *              nearest multiple of the current architecture's alignment.
 * ============================================================= */
#define ALIGN(x)        (((x) + (ARCH_ALIGNMENT - 1U)) & ~(ARCH_ALIGNMENT - 1U))

/** =============================================================
 *  @def        HEAP_SIZE
 *  @brief      Defines the size of the memory heap.
 *
 *  @details    Set to 1 MB (1024 * 1024 bytes) for dynamic memory
 *              allocation.
 * ============================================================= */
#define HEAP_SIZE       (size_t)(1024U * 1024U) /*< 1 MB >*/

/** ============================================================== 
 *  @def        SUCCESS  
 *  @brief      Standard success function return code
 * =============================================================== */  
#define SUCCESS 0U

/** ===============================================================
 *          P U B L I C  S T R U C T U R E S  &  T Y P E S          
 * ================================================================ */

/** =============================================================
 *  @enum       AllocationStrategy
 *  @typedef    allocation_strategy_t
 *  @brief      Defines allocation strategies for memory management.
 *
 *  @details    This enum specifies the available strategies for
 *              memory block allocation within the heap.
 * ============================================================= */
typedef enum AllocationStrategy
{
    FIRST_FIT = (uint8_t)(0u),          /**< First available block allocation */
    NEXT_FIT  = (uint8_t)(1u),          /**< Continue from last allocation */
    BEST_FIT  = (uint8_t)(2u)           /**< Smallest block fitting the request */
} allocation_strategy_t;

/** =============================================================
 *  @struct     BlockHeader
 *  @typedef    block_header_t
 *  @brief      Represents the header for a memory block.
 *
 *  @details    This structure manages metadata for each block
 *              within the heap, including size, status, and
 *              debugging information.
 * ============================================================= */
typedef struct __attribute__((packed, aligned(ARCH_ALIGNMENT))) BlockHeader
{
    uint32_t            magic;          /**< Magic number for integrity check */

    size_t              size;           /**< Total block size (includes header, data, and canary) */

    _Bool               free;           /**< 1 if block is free, 0 if allocated */
    _Bool               marked;         /**< Garbage collector mark flag */

    const char          *file;          /**< Source file of allocation (for debugging) */
    unsigned long long  line;           /**< Line number of allocation (for debugging) */
    const char          *var_name;      /**< Variable name (for debugging) */

    struct BlockHeader  *next;          /**< Pointer to the next block */
    struct BlockHeader  *prev;          /**< Pointer to the previous block */

    uint32_t            canary;         /**< Canary value for buffer overflow detection */
} block_header_t;

/** =============================================================
 *  @struct    <F10> MemoryAllocator
 *  @typedef    mem_allocator_t
 *  @brief      Manages dynamic memory allocation.
 *
 *  @details    This structure manages the heap, including free
 *              lists for memory blocks, garbage collection, and
 *              allocation strategies.
 * ============================================================= */
typedef struct __attribute__((packed, aligned(ARCH_ALIGNMENT))) MemoryAllocator
{
    uint8_t         *heap;              /**< Start address of the heap */
    size_t          heap_size;          /**< Total size of the heap */
    uint8_t         *heap_end;          /**< Current end of the heap */

    block_header_t  **free_lists;       /**< Array of pointers to segregated free lists */
    size_t          num_size_classes;   /**< Number of size classes */

    block_header_t  *last_allocated;    /**< Last allocated block (for NEXT_FIT strategy) */

    _Bool           gc_enabled;         /**< 1 if garbage collection is enabled */
    void            **roots;            /**< Array of registered roots for garbage collection */
    size_t          num_roots;          /**< Current number of registered roots */
    size_t          roots_capacity;     /**< Capacity of the roots array */
} mem_allocator_t;

/** ===============================================================
 *       P U B L I C  F U N C T I O N S  P R O T O T Y P E S        
 * ================================================================ */

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
 * =============================================================== */
void *MEM_memset(void *const source, const int value, const size_t size);

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
 * =============================================================== */
void *MEM_memcpy(void *const dest, const void *src, const size_t size);

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
 * =============================================================== */
int MEM_newBrk(mem_allocator_t *const allocator, void *const new_break);

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
 * =============================================================== */
void *MEM_newSbrk(mem_allocator_t *const allocator, const intptr_t increment);

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
 * =============================================================== */
void *MEM_allocatorMalloc(mem_allocator_t *const allocator,
                            const size_t size,
                            const char *const file,
                            const int line,
                            const char *const var_name,
                            const allocation_strategy_t strategy);

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
 * =============================================================== */
void *MEM_allocatorRealloc(mem_allocator_t *const allocator,
                            void *const ptr,
                            const size_t new_size,
                            const char *const file,
                            const int line,
                            const char *const var_name,
                            const allocation_strategy_t strategy);

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
 * =============================================================== */
void *MEM_allocatorCalloc(mem_allocator_t *const allocator,
                            const size_t num,
                            const size_t size,
                            const char *const file,
                            const int line,
                            const char *const var_name,
                            const allocation_strategy_t strategy);

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
 * =============================================================== */
int MEM_allocatorFree(mem_allocator_t *const allocator,
                        void *const ptr,
                        const char *const file,
                        const int line,
                        const char *const var_name);

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
 * =============================================================== */
void *MEM_alloca(const size_t size);

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
 * =============================================================== */
int MEM_allocatorPrintAll(mem_allocator_t *const allocator);

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
 * =============================================================== */
int MEM_runGC(mem_allocator_t *const allocator);
/** ================================================================
 *              P U B L I C   M A C R O S   A P I                  
 * ================================================================ */

/** ==============================================================
 *  @def        MALLOC_FIRST_FIT
 *  @brief      Allocates memory using FIRST_FIT strategy
 *
 *  @param      allocator   Memory allocator context
 *  @param      size        Requested allocation size
 *  @param      var         Variable name (automatically captured)
 *
 *  @return     Pointer to allocated memory or NULL
 *
 *  @note       Strategy: Finds first suitable block in free lists
 *              Auto-captures file/line information
 * =============================================================== */
#define MALLOC_FIRST_FIT(allocator, size, var) \
    MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, #var, FIRST_FIT)

/** ==============================================================
 *  @def        MALLOC_BEST_FIT
 *  @brief      Allocates memory using BEST_FIT strategy
 *
 *  @param      allocator   Memory allocator context
 *  @param      size        Requested allocation size
 *  @param      var         Variable name (automatically captured)
 *
 *  @return     Pointer to allocated memory or NULL
 *
 *  @note       Strategy: Finds smallest suitable block in free lists
 *              Auto-captures file/line information
 * =============================================================== */
#define MALLOC_BEST_FIT(allocator, size, var) \
    MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, #var, BEST_FIT)

/** ==============================================================
 *  @def        MALLOC_NEXT_FIT
 *  @brief      Allocates memory using NEXT_FIT strategy
 *
 *  @param      allocator   Memory allocator context
 *  @param      size        Requested allocation size
 *  @param      var         Variable name (automatically captured)
 *
 *  @return     Pointer to allocated memory or NULL
 *
 *  @note       Strategy: Continues search from last allocation point
 *              Auto-captures file/line information
 * =============================================================== */
#define MALLOC_NEXT_FIT(allocator, size, var) \
    MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, #var, NEXT_FIT)

/** ==============================================================
 *  @def        MALLOC
 *  @brief      General purpose allocation with strategy selection
 *
 *  @param      allocator   Memory allocator context
 *  @param      size        Requested allocation size
 *  @param      var         Variable name (automatically captured)
 *  @param      strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 *
 *  @note       Allows explicit strategy selection
 *              Auto-captures file/line information
 * =============================================================== */
#define MALLOC(allocator, size, var, strategy) \
    MEM_allocatorMalloc(allocator, size, __FILE__, __LINE__, #var, strategy)

/** ==============================================================
 *  @def        CALLOC
 *  @brief      Allocates and zero-initializes memory
 *
 *  @param      allocator   Memory allocator context
 *  @param      num         Number of elements
 *  @param      size        Element size
 *  @param      var         Variable name (automatically captured)
 *  @param      strategy    Allocation strategy to use
 *
 *  @return     Pointer to allocated memory or NULL
 *
 *  @note       Combines allocation and zero-initialization
 *              Auto-captures file/line information
 * =============================================================== */
#define CALLOC(allocator, num, size, var, strategy) \
    MEM_allocatorCalloc(allocator, num, size, __FILE__, __LINE__, #var, strategy)

/** ==============================================================
 *  @def        REALLOC
 *  @brief      Reallocates memory with safety checks
 *
 *  @param      allocator   Memory allocator context
 *  @param      ptr         Pointer to reallocate
 *  @param      new_size    New allocation size
 *  @param      var         Variable name (automatically captured)
 *  @param      strategy    Allocation strategy to use
 *
 *  @return     Pointer to reallocated memory or NULL
 *
 *  @note       Preserves existing data during reallocation
 *              Auto-captures file/line information
 * =============================================================== */
#define REALLOC(allocator, ptr, new_size, var, strategy) \
    MEM_allocatorRealloc(allocator, ptr, new_size, __FILE__, __LINE__, #var, strategy)

/** ==============================================================
 *  @def        FREE
 *  @brief      Releases allocated memory back to the heap
 *
 *  @param      allocator   Memory allocator context
 *  @param      ptr         Pointer to memory to free
 *  @param      var         Variable name (automatically captured)
 *
 *  @return     Integer status code
 *
 *  @note       Performs automatic garbage collection if enabled
 *              Auto-captures file/line information
 * =============================================================== */
#define FREE(allocator, ptr, var) \
    MEM_allocatorFree(allocator, ptr, __FILE__, __LINE__, #var)

/*< C++ Compatibility >*/
#ifdef __cplusplus
    }
#endif

#endif /* LIBMEMALLOC_H_ */

/** @} */

/*< end of header file >*/
