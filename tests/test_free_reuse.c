/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Free-then-reuse allocation test.
 *
 *  @file       test_free_reuse.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Allocates a set of blocks, frees every other block,
 *              then allocates new smaller blocks to verify that freed
 *              space is being reused by the allocator (First Fit strategy).
 *
 *  @version    v1.0.00
 *  @date       23.08.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

/** ============================================================================
 *                      P R I V A T E  I N C L U D E S
 * ========================================================================== */

/*< Implemented >*/
#include "libmemalloc.h"
#include "logs.h"

/*< Dependencies >*/
#include <assert.h>
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/** ============================================================================
 *               P R I V A T E  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        LARGE_SZ
 *  @brief      Size of large test allocation in units.
 *
 *  @details    Defined as a size_t value of 64 to represent the number of
 *              bytes (or elements, depending on context) for large allocations
 *              in test scenarios.
 * ========================================================================== */
#define LARGE_SZ   (size_t)(64U)

/** ============================================================================
 *  @def        SMALL_SZ
 *  @brief      Size of small test allocation in units.
 *
 *  @details    Defined as a size_t value of 32 to represent the number of
 *              bytes (or elements, depending on context) for small allocations
 *              in test scenarios.
 * ========================================================================== */
#define SMALL_SZ   (size_t)(32U)

/** ============================================================================
 *  @def        NR_BLOCKS
 *  @brief      Total number of allocation blocks in the test array.
 *
 *  @details    Defined as an unsigned integer value of 10 to specify
 *              the size of the arrays used for allocation tracking.
 * ========================================================================== */
#define NR_BLOCKS  (uint8_t)(10U)

/** ============================================================================
 *  @def        NR_REUSED
 *  @brief      Number of blocks to be freed and then reused.
 *
 *  @details    Calculated as half of NR_BLOCKS (integer division).
 *              Specifies how many blocks will be dropped and
 *              later reallocated during GC testing.
 * ========================================================================== */
#define NR_REUSED  (uint8_t)(NR_BLOCKS / 2U)

/** ============================================================================
 *  @def        EXIT_ERROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERROR (uint8_t)(1U)

/** ============================================================================
 *  @def        CHECK(expr)
 *  @brief      Assertion macro for validating test expressions.
 *
 *  @param [in] expr  Boolean expression to evaluate.
 *
 *  @details    Evaluates the given expression and, if false,
 *              logs an error with file and line information,
 *              then returns EXIT_ERROR from the current function.
 *              Ensures immediate test termination on failure.
 * ========================================================================== */
#define CHECK(expr)                                                          \
  do                                                                         \
  {                                                                          \
    if (!(expr))                                                             \
    {                                                                        \
      LOG_ERROR("Assertion failed at %s:%d: %s", __FILE__, __LINE__, #expr); \
      return EXIT_ERROR;                                                     \
    }                                                                        \
  } while (0)

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_freeThenReuse
 *  @brief      Tests reuse of freed blocks via First Fit strategy.
 *
 *  @return     EXIT_SUCCESS on success, EXIT_ERROR on failure.
 *
 *  @retval     EXIT_SUCCESS  Free-and-reuse behavior validated.
 *  @retval     EXIT_ERROR   Any allocation/free or reuse check failed.
 * ========================================================================== */
static int TEST_freeThenReuse(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  ret = TEST_freeThenReuse( );
  CHECK(ret == EXIT_SUCCESS);

  LOG_INFO("Free-then-reuse test passed.\n");
  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_freeThenReuse
 *  @brief      Tests reuse of freed blocks via First Fit strategy.
 *
 *  @return     EXIT_SUCCESS on success, EXIT_ERROR on failure.
 *
 *  @retval     EXIT_SUCCESS  Free-and-reuse behavior validated.
 *  @retval     EXIT_ERROR   Any allocation/free or reuse check failed.
 * ========================================================================== */
static int TEST_freeThenReuse(void)
{
  int ret = EXIT_SUCCESS;

  void *blocks[NR_BLOCKS];
  void *reused[NR_REUSED];

  size_t iterator     = 0u;
  size_t iterator_aux = 0u;

  CHECK(ret == EXIT_SUCCESS);

  for (iterator = 0u; iterator < NR_BLOCKS; ++iterator)
  {
    blocks[iterator] = MEM_allocFirstFit(LARGE_SZ);
    CHECK(blocks[iterator] != NULL);
    MEM_memset(blocks[iterator], (int)iterator, LARGE_SZ);
  }

  for (iterator = 0u; iterator < NR_BLOCKS; iterator += 2u)
  {
    ret = MEM_free(blocks[iterator]);
    CHECK(ret == EXIT_SUCCESS);
    blocks[iterator] = NULL;
  }

  for (iterator = 0u, iterator_aux  = 0u; iterator < NR_REUSED;
       ++iterator, iterator_aux    += 2u)
  {
    reused[iterator] = MEM_allocFirstFit(SMALL_SZ);
    CHECK(reused[iterator] != NULL);
    MEM_memset(reused[iterator], 0x55, SMALL_SZ);
  }

  for (iterator = 1u; iterator < NR_BLOCKS; iterator += 2u)
  {
    ret = MEM_free(blocks[iterator]);
    CHECK(ret == EXIT_SUCCESS);
  }

  for (iterator = 0u; iterator < NR_REUSED; ++iterator)
  {
    ret = MEM_free(reused[iterator]);
    CHECK(ret == EXIT_SUCCESS);
  }

  return EXIT_SUCCESS;
}

/*< end of file >*/
