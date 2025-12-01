/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Multi-strategy allocation test (simplified).
 *
 *  @file       test_multi_strategy.c
 *  @headerfile libmemalloc.h
 *
 *  @details    For each allocation strategy (First Fit, Next Fit, Best Fit):
 *                - Allocate a single block
 *                - Verify the returned pointer is not NULL
 *                - Write to the block using memset
 *                - Immediately free the block
 *
 *              This approach tests each strategy in isolation without
 *              retaining multiple live allocations, thereby preventing
 *              heap exhaustion during the test.
 *
 *  @version    v1.0.00
 *  @date       23.08.2025
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
 *  @def        ALLOC_SIZE
 *  @brief      Default allocation size for test scenarios.
 *
 *  @details    Defined as a size_t value of 128 bytes,
 *              used for allocations when a fixed-size buffer is required.
 * ========================================================================== */
#define ALLOC_SIZE (size_t)(128U)

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
  FIRST_FILL
    = (uint8_t)(0xAA), /**< Initial small-block fill pattern (170 decimal) */
  SECOND_FILL
    = (uint8_t)(0xBB), /**< Initial large-block fill pattern (187 decimal) */
  THIRD_FILL
    = (uint8_t)(0xCC), /**< Reused small-block fill pattern (204 decimal) */
} fills_t;

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_multiStrategy
 *  @brief      Aloca e libera blocos usando First, Next e Best Fit.
 *
 *  @return     EXIT_SUCCESS em caso de sucesso, EXIT_ERROR em falha.
 *
 *  @retval     EXIT_SUCCESS  Todas as operações sucederam.
 *  @retval     EXIT_ERROR   Alguma operação falhou.
 * ========================================================================== */
static int TEST_multiStrategy(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  ret = TEST_multiStrategy( );
  ;
  CHECK(ret == EXIT_SUCCESS);

  LOG_INFO("Multi-strategy allocation test passed.\n");
  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_multiStrategy
 *  @brief      Aloca e libera blocos usando First, Next e Best Fit.
 *
 *  @return     EXIT_SUCCESS em caso de sucesso, EXIT_ERROR em falha.
 *
 *  @retval     EXIT_SUCCESS  Todas as operações sucederam.
 *  @retval     EXIT_ERROR   Alguma operação falhou.
 * ========================================================================== */
static int TEST_multiStrategy(void)
{
  int ret = EXIT_SUCCESS;

  void *ptr = NULL;

  ptr = MEM_allocFirstFit(ALLOC_SIZE);
  CHECK((intptr_t)ptr >= 0);
  MEM_memset(ptr, FIRST_FILL, ALLOC_SIZE);

  ret = MEM_free(ptr);
  CHECK(ret == EXIT_SUCCESS);

  ptr = MEM_allocNextFit(ALLOC_SIZE);
  CHECK((intptr_t)ptr >= 0);
  MEM_memset(ptr, SECOND_FILL, ALLOC_SIZE);

  ret = MEM_free(ptr);
  CHECK(ret == EXIT_SUCCESS);

  ptr = MEM_allocBestFit(ALLOC_SIZE);
  CHECK((intptr_t)ptr >= 0);

  MEM_memset(ptr, THIRD_FILL, ALLOC_SIZE);
  ret = MEM_free(ptr);
  CHECK(ret == EXIT_SUCCESS);

  return EXIT_SUCCESS;
}

/*< end of file >*/
