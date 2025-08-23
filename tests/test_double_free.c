/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Double free detection test.
 *
 *  @file       test_double_free.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Allocates a single block, frees it, then attempts to free it
 * again. Verifies that the second free returns an error (not EXIT_SUCCESS).
 *
 *  @version    v4.0.00
 *  @date       26.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ============================================================================
 */

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
 *  @def        EXIT_ERRROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERRROR (uint8_t)(1U)

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
 *  @fn         TEST_doubleFree
 *  @brief      Tests that freeing the same pointer twice triggers an error.
 *
 *  @return     EXIT_SUCCESS on correct behavior, EXIT_ERRROR on failure.
 *
 *  @retval     EXIT_SUCCESS  Second free returned an error as expected.
 *  @retval     EXIT_ERRROR   Unexpected success or initial operations failed.
 * ========================================================================== */
static int TEST_doubleFree(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  ret = TEST_doubleFree( );
  CHECK(ret == EXIT_SUCCESS);

  LOG_INFO("Double free detection test passed.\n");
  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_doubleFree
 *  @brief      Tests that freeing the same pointer twice triggers an error.
 *
 *  @return     EXIT_SUCCESS on correct behavior, EXIT_ERRROR on failure.
 *
 *  @retval     EXIT_SUCCESS  Second free returned an error as expected.
 *  @retval     EXIT_ERRROR   Unexpected success or initial operations failed.
 * ========================================================================== */
static int TEST_doubleFree(void)
{
  int ret = EXIT_SUCCESS;

  void *ptr = (void *)NULL;

  mem_allocator_t allocator;

  ret = MEM_allocatorInit(&allocator);
  CHECK(ret == EXIT_SUCCESS);

  ptr = MEM_allocMallocFirstFit(&allocator, 64, "dfree");
  CHECK(ptr != NULL);

  ret = MEM_allocFree(&allocator, ptr, "dfree");
  CHECK(ret == EXIT_SUCCESS);

  ret = MEM_allocFree(&allocator, ptr, "dfree");
  CHECK(ret != EXIT_SUCCESS);

  return EXIT_SUCCESS;
}

/*< end of file >*/
