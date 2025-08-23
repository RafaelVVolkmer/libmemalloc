/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Test suite for realloc functionality under multiple scenarios.
 *
 *  @file       test_multiple_realloc.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Validates correct behavior of MEM_allocRealloc in the following
 * cases:
 *                - Growing an existing allocation
 *                - Shrinking an existing allocation
 *                - Freeing a shrunk allocation
 *                - Reallocating from NULL pointer (malloc via realloc)
 *                - Freeing the realloc-from-NULL allocation
 *
 *              Test steps include:
 *                1. Initialize allocator
 *                2. Allocate an initial block of 16 bytes
 *                3. Realloc to grow to 32 bytes
 *                4. Realloc to shrink to 8 bytes
 *                5. Free the shrunk block
 *                6. Realloc(NULL) to allocate 24 bytes
 *                7. Free the realloc-from-NULL block
 *
 *              Runtime DEBUG prints trace each operation and pointer value.
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
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*< Implemented >*/
#include "libmemalloc.h"
#include "logs.h"

/** ============================================================================
 *               P R I V A T E  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        PATTERN_SIZE
 *  @brief      Maximum byte-pattern size for realloc tests.
 *
 *  @details    Defined as a size_t value of 32 bytes.
 *              Used as the buffer length for pattern-based memory operations
 *              during realloc growth/shrink validation.
 * ========================================================================== */
#define PATTERN_SIZE (size_t)(32U)

/** ============================================================================
 *  @def        INITIAL_SIZE
 *  @brief      Initial allocation size for realloc tests.
 *
 *  @details    Defined as half of PATTERN_SIZE (32 / 2 = 16 bytes).
 *              Used to allocate the original block before resizing.
 * ========================================================================== */
#define INITIAL_SIZE (size_t)(PATTERN_SIZE / 2U)

/** ============================================================================
 *  @def        GROWN_SIZE
 *  @brief      Grown allocation size for realloc tests.
 *
 *  @details    Defined equal to PATTERN_SIZE (32 bytes).
 *              Used to expand the original allocation.
 * ========================================================================== */
#define GROWN_SIZE   (size_t)(PATTERN_SIZE)

/** ============================================================================
 *  @def        SHRUNK_SIZE
 *  @brief      Shrunk allocation size for realloc tests.
 *
 *  @details    Defined as one-quarter of PATTERN_SIZE (32 / 4 = 8 bytes).
 *              Used to shrink the allocation after growth.
 * ========================================================================== */
#define SHRUNK_SIZE  (size_t)(PATTERN_SIZE / 4U)

/** ============================================================================
 *  @def        NULL_SIZE
 *  @brief      Allocation size for realloc(NULL) tests.
 *
 *  @details    Defined as three-quarters of PATTERN_SIZE
 *              ((32 * 3) / 4 = 24 bytes).
 *              Used to allocate a new block via realloc(NULL, size).
 * ========================================================================== */
#define NULL_SIZE    (size_t)((PATTERN_SIZE * 3U) / 4U)

/** ============================================================================
 *  @def        EXIT_ERRROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERRROR  (uint8_t)(1U)

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
#define CHECK(expr)                                                          \
  do                                                                         \
  {                                                                          \
    if (!(expr))                                                             \
    {                                                                        \
      LOG_ERROR("Assertion failed at %s:%d: %s", __FILE__, __LINE__, #expr); \
      return EXIT_ERRROR;                                                    \
    }                                                                        \
  } while (0)

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_multipleRealloc
 *  @brief      Validates realloc behavior for growing, shrinking,
 *              and NULL-pointer cases.
 *
 *  @return     EXIT_SUCCESS when all realloc and free operations succeed
 *              EXIT_ERRROR when any CHECK() assertion fails
 *
 *  @retval     EXIT_SUCCESS  All steps completed successfully
 *  @retval     EXIT_ERRROR   A test assertion failed during execution
 * ========================================================================== */
static int TEST_multipleRealloc(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = TEST_multipleRealloc( );
  CHECK(ret == EXIT_SUCCESS);

  printf("All realloc tests passed.\n");
  return EXIT_SUCCESS;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_multipleRealloc
 *  @brief      Validates realloc behavior for growing, shrinking,
 *              and NULL-pointer cases.
 *
 *  @return     EXIT_SUCCESS when all realloc and free operations succeed
 *              EXIT_ERRROR when any CHECK() assertion fails
 *
 *  @retval     EXIT_SUCCESS  All steps completed successfully
 *  @retval     EXIT_ERRROR   A test assertion failed during execution
 * ========================================================================== */
static int TEST_multipleRealloc(void)
{
  int ret = EXIT_SUCCESS;

  mem_allocator_t allocator;

  void *ptr_0 = NULL;
  void *ptr_1 = NULL;
  void *ptr_2 = NULL;
  void *ptr_3 = NULL;

  CHECK(MEM_allocatorInit(&allocator) == EXIT_SUCCESS);

  ptr_0 = MEM_allocMallocFirstFit(&allocator, INITIAL_SIZE, "p");

  ptr_1 = MEM_allocRealloc(&allocator, ptr_0, GROWN_SIZE, "p2", FIRST_FIT);

  ptr_2 = MEM_allocRealloc(&allocator, ptr_1, SHRUNK_SIZE, "p3", FIRST_FIT);

  CHECK(MEM_allocFree(&allocator, ptr_2, "p3") == EXIT_SUCCESS);

  ptr_3 = MEM_allocRealloc(&allocator, NULL, NULL_SIZE, "pn", FIRST_FIT);

  CHECK(MEM_allocFree(&allocator, ptr_3, "pn") == EXIT_SUCCESS);

  return ret;
}

/*< end of file >*/
