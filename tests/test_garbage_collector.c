 /** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Unit tests for core memory allocator functions.
 *
 *  @file       test_memalloc.c
 *  @headerfile libmemalloc.h
 *
 *  @details    This file implements a suite of unit tests for validating
 *              the main memory management operations provided by libmemalloc.
 *              It covers basic allocation, deallocation, alignment,
 *              calloc zero-initialization, and realloc content preservation.
 *
 *              The following test cases are executed:
 *              - Initialization of allocator context
 *              - Simple malloc and free operations
 *              - Calloc with zero-initialized memory verification
 *              - Reallocation with content preservation
 *              - Memory alignment checking
 *
 *              All tests use CHECK() macro for runtime assertions,
 *              and return EXIT_SUCCESS or EXIT_ERRROR.
 *
 *  @version    v4.0.00
 *  @date       26.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

/** ============================================================================
 *                      P R I V A T E  I N C L U D E S                          
 * ========================================================================== */

/*< Dependencies >*/
#include <assert.h>
#include <errno.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/*< Implemented >*/
#include "libmemalloc.h"
#include "logs.h"

/** ============================================================================
 *               P R I V A T E  D E F I N E S  &  M A C R O S                   
 * ========================================================================== */

/** ============================================================================
 *  @def        MMAP_THRESHOLD
 *  @brief      Threshold size to switch to mmap for large allocations.
 *
 *  @details    Defined as a uint64_t value of 131072 (128U * 1024U) bytes.
 *              Allocation requests larger than this value will be served via mmap
 *              instead of sbrk.
 * ========================================================================== */
#define MMAP_THRESHOLD   (uint64_t)(128U * 1024U)

/** ============================================================================
 *  @def        SMALL_ALLOC_SIZE
 *  @brief      Size for small allocations via sbrk.
 *
 *  @details    Defined as a uint64_t value of 1024 (1U * 1024U) bytes.
 *              Allocation requests up to this size will use sbrk.
 * ========================================================================== */
#define SMALL_ALLOC_SIZE (uint64_t)(1024U)

/** ============================================================================
 *  @def        LARGE_ALLOC_SIZE
 *  @brief      Example large allocation size to force an mmap call.
 *
 *  @details    Defined as a uint64_t value of (MMAP_THRESHOLD + 4096U) bytes,
 *              i.e., approximately 132KB, to ensure the allocator chooses mmap.
 * ========================================================================== */
#define LARGE_ALLOC_SIZE (uint64_t)(MMAP_THRESHOLD + 4096U)

/** ============================================================================
 *  @def        NR_OBJS
 *  @brief      Number of objects for batch or pool tests.
 *
 *  @details    Defined as a uint8_t value of 16 to specify the count of objects
 *              created or managed in testing scenarios.
 * ========================================================================== */
#define NR_OBJS          (uint8_t)(16U)

/** ============================================================================
 *  @def        ADDR_STR_LEN
 *  @brief      Length for stringified pointer representations.
 *
 *  @details    Defined as a uint32_t value of 32, to accommodate
 *              the hexadecimal string of a pointer (including “0x”).
 * ========================================================================== */
#define ADDR_STR_LEN    (uint32_t)(32U)

/** ============================================================================
 *  @def        HALF_OBJS
 *  @brief      Half of the total number of test objects.
 *
 *  @details    Defined as NR_OBJS divided by 2, to be used when
 *              only every other allocation is recycled (e.g., in GC tests).
 * ========================================================================== */
#define HALF_OBJS       (uint8_t)(NR_OBJS / 2U)

/** ============================================================================
 *  @def        GC_MARGIN_US
 *  @brief      Additional usleep margin beyond the GC interval.
 *
 *  @details    Fixed extra delay in microseconds to ensure the GC thread
 *              has completed its cycle before resuming test execution.
 * ========================================================================== */
#define GC_MARGIN_US     (uint32_t)(5000U)

/** ============================================================================
 *  @def        GC_SLEEP_US
 *  @brief      Total usleep duration for one GC cycle plus margin.
 *
 *  @details    Sum of GC interval (in microseconds) and an extra margin,
 *              used in usleep() to wait for one full GC cycle.
 * ========================================================================== */
#define GC_SLEEP_US      (GC_INTERVAL_MS + GC_MARGIN_US)

/** ============================================================================
 *  @def        EXIT_ERRROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERRROR     (uint8_t)(1U)

/** ============================================================================
 *  @def        CHECK(expr)
 *  @brief      Assertion macro for validating test expressions.
 *
 *  @param [in] expr  Boolean expression to evaluate.
 *
 *  @details    Evaluates the given expression and, if false,
 *              logs an error with file and line information,
 *              then returns EXIT_ERRROR from the current function.
 *              Ensures immediate test termination on failure.
 * ========================================================================== */
#define CHECK(expr)                                     \
    do {                                                \
        if (!(expr))                                    \
        {                                               \
            LOG_ERROR("Assertion failed at %s:%d: %s",  \
                      __FILE__, __LINE__, #expr);       \
            return EXIT_ERRROR;                         \
        }                                               \
    } while (0)

/** ============================================================================
 *              P R I V A T E  S T R U C T U R E S  &  T Y P E S                
 * ========================================================================== */

/** ============================================================================
 *  @enum       Fills
 *  @typedef    fills_t
 *  @brief      Byte-pattern constants used to fill memory regions in tests.
 *
 *  @details
 *    - FIRST_FILL  (0xAA): Pattern for initial small-block fills.
 *    - SECOND_FILL (0xBB): Pattern for large-block fills via mmap.
 *    - THIRD_FILL  (0xCC): Pattern for reused small-block fills after GC.
 *    - FOURTH_FILL (0xDD): Pattern for reused large-block fills after GC.
 * ========================================================================== */
typedef enum Fills
{
    FIRST_FILL  = (uint8_t)(0xAA),      /**< Initial small-block fill pattern (170 decimal) */
    SECOND_FILL = (uint8_t)(0xBB),      /**< Initial large-block fill pattern (187 decimal) */
    THIRD_FILL  = (uint8_t)(0xCC),      /**< Reused small-block fill pattern (204 decimal) */
    FOURTH_FILL = (uint8_t)(0xDD)       /**< Reused large-block fill pattern (221 decimal) */
} fills_t;

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S               
 * ========================================================================== */

 /** ===========================================================================
 *  @fn         TEST_gcMmapAndSbrkPaths
 *  @brief      Verifies that the garbage collector correctly reclaims and
 *              reuses both sbrk and mmap allocations after a GC cycle.
 *
 *  @return     EXIT_SUCCESS when all allocation, GC, and free operations
 *              complete as expected
 *              EXIT_ERRROR when any CHECK() assertion fails
 *
 *  @retval     EXIT_SUCCESS  All test steps passed successfully
 *  @retval     EXIT_ERRROR   A test assertion failed during execution
 * ========================================================================== */
static int TEST_gcMmapAndSbrkPaths(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N                            
 * ========================================================================== */

int main(void)
{
    int ret = EXIT_SUCCESS;

    ret = TEST_gcMmapAndSbrkPaths();
    CHECK(ret == EXIT_SUCCESS);

    LOG_INFO("Garbage Collector test passed.\n");

    return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S                    
 * ========================================================================== */

 /** ===========================================================================
 *  @fn         TEST_gcMmapAndSbrkPaths
 *  @brief      Verifies that the garbage collector correctly reclaims and
 *              reuses both sbrk and mmap allocations after a GC cycle.
 *
 *  @return     EXIT_SUCCESS when all allocation, GC, and free operations
 *              complete as expected
 *              EXIT_ERRROR when any CHECK() assertion fails
 *
 *  @retval     EXIT_SUCCESS  All test steps passed successfully
 *  @retval     EXIT_ERRROR   A test assertion failed during execution
 * ========================================================================== */
static int TEST_gcMmapAndSbrkPaths(void)
{
    int ret = EXIT_SUCCESS;

    mem_allocator_t allocator;

    void *ptr = NULL;

    void *volatile small_objs[NR_OBJS];
    void *volatile large_objs[NR_OBJS];

    char old_large_str[HALF_OBJS][ADDR_STR_LEN];
    char reused_large_str[HALF_OBJS][ADDR_STR_LEN];

    size_t iterator = 0u;
    size_t iterator_ptr = 0u;

    ret = MEM_allocatorInit(&allocator);
    CHECK(ret == EXIT_SUCCESS);

    for (iterator = 0u; iterator < NR_OBJS; iterator++)
    {
        small_objs[iterator] = MEM_allocMallocFirstFit(&allocator,
                                                        SMALL_ALLOC_SIZE,
                                                        "small_obj");
        CHECK(small_objs[iterator] != NULL);
        MEM_memset(small_objs[iterator], FIRST_FILL, SMALL_ALLOC_SIZE);

        large_objs[iterator] = MEM_allocMallocFirstFit(&allocator,
                                                        LARGE_ALLOC_SIZE,
                                                        "large_obj");
        CHECK(large_objs[iterator] != NULL);
        MEM_memset(large_objs[iterator], SECOND_FILL, LARGE_ALLOC_SIZE);
    }

    for (iterator = 0u, iterator_ptr = 0u;
        iterator < NR_OBJS;
        iterator += 2u, iterator_ptr++)
    {
        small_objs[iterator] = NULL;

        snprintf(old_large_str[iterator_ptr],
            sizeof(old_large_str[iterator_ptr]), "%p", large_objs[iterator]);
        large_objs[iterator] = NULL;
    }

    ret = MEM_enableGc(&allocator);
    CHECK(ret == EXIT_SUCCESS);

    usleep(GC_SLEEP_US);

    ret = MEM_disableGc(&allocator);
    CHECK(ret == EXIT_SUCCESS);

    for (iterator = 0u; iterator < HALF_OBJS; iterator++)
    {
        ptr = MEM_allocMallocBestFit(&allocator,
                                      SMALL_ALLOC_SIZE,
                                      "reused_small");
        CHECK(ptr != NULL);

        ptr = MEM_allocMallocBestFit(&allocator,
                                      LARGE_ALLOC_SIZE,
                                      "reused_large");
        CHECK(ptr != NULL);
        snprintf(reused_large_str[iterator],
                    sizeof(reused_large_str[iterator]), "%p", ptr);
        CHECK(strcmp(reused_large_str[iterator],
                old_large_str[iterator]) == EXIT_SUCCESS);

        MEM_memset(ptr, FOURTH_FILL, LARGE_ALLOC_SIZE);
    }

    for (iterator = 0u; iterator < NR_OBJS; ++iterator)
    {
        if (small_objs[iterator])
        {
            MEM_allocFree(&allocator, (void*)small_objs[iterator], "small_obj");
            small_objs[iterator] = NULL;
        }
        if (large_objs[iterator])
        {
            MEM_allocFree(&allocator, (void*)large_objs[iterator], "large_obj");
            large_objs[iterator] = NULL;
        }
    }

    return ret;
}

/*< end of file >*/
