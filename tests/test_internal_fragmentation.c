/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Internal fragmentation and alignment test.
 *
 *  @file       test_internal_fragmentation.c
 *  @headerfile libmemalloc.h
 *
 *  @details    Allocates a series of blocks with varying small sizes to verify
 *              that:
 *              - Each allocation succeeds (no NULL returns)
 *              - Returned pointers respect ARCH_ALIGNMENT
 *              - Memory within each block is writable up to the requested size
 *              - Blocks can be freed without error
 *
 *              This helps detect internal fragmentation issues and ensures
 *              that alignment logic works correctly for small allocations.
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
 *  @def        FILL_PATTERN
 *  @brief      Fill byte pattern used for initial memory writes.
 *
 *  @details    Defined as a uint8_t value of 0xAA (170 decimal),
 *              used to mark or test memory regions with a recognizable pattern.
 * ========================================================================== */
#define FILL_PATTERN (uint8_t)(0xAAU)

/** ============================================================================
 *  @def        EXIT_ERROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERROR   (uint8_t)(1U)

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
 *  @enum   SizeConstants
 *  @brief  Named constants for each test allocation size.
 *
 *  @details
 *    Maps each ordinal in the `sizes[]` vector to its actual byte value,
 *    so you can refer to `SIZE_FOURTEENTH_ORDER` for the 128-byte case, etc.
 * ========================================================================== */
typedef enum SizeConstants
{
  SIZE_FIRST_ORDER      = (uint8_t)(1u),   /**< sizes[0]  ==   1 byte   */
  SIZE_SECOND_ORDER     = (uint8_t)(2u),   /**< sizes[1]  ==   2 bytes  */
  SIZE_THIRD_ORDER      = (uint8_t)(3u),   /**< sizes[2]  ==   3 bytes  */
  SIZE_FOURTH_ORDER     = (uint8_t)(4u),   /**< sizes[3]  ==   4 bytes  */
  SIZE_FIFTH_ORDER      = (uint8_t)(7u),   /**< sizes[4]  ==   7 bytes  */
  SIZE_SIXTH_ORDER      = (uint8_t)(8u),   /**< sizes[5]  ==   8 bytes  */
  SIZE_SEVENTH_ORDER    = (uint8_t)(15u),  /**< sizes[6]  ==  15 bytes  */
  SIZE_EIGHTH_ORDER     = (uint8_t)(16u),  /**< sizes[7]  ==  16 bytes  */
  SIZE_NINTH_ORDER      = (uint8_t)(31u),  /**< sizes[8]  ==  31 bytes  */
  SIZE_TENTH_ORDER      = (uint8_t)(32u),  /**< sizes[9]  ==  32 bytes  */
  SIZE_ELEVENTH_ORDER   = (uint8_t)(63u),  /**< sizes[10] ==  63 bytes  */
  SIZE_TWELFTH_ORDER    = (uint8_t)(64u),  /**< sizes[11] ==  64 bytes  */
  SIZE_THIRTEENTH_ORDER = (uint8_t)(127u), /**< sizes[12] == 127 bytes  */
  SIZE_FOURTEENTH_ORDER = (uint8_t)(128u)  /**< sizes[13] == 128 bytes  */
} size_constants_t;

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_internalFragmentation
 *  @brief      Exercises allocations of varied small sizes.
 *
 *  @return     EXIT_SUCCESS on success, EXIT_ERROR on failure.
 *
 *  @retval     EXIT_SUCCESS  All allocations, writes, and frees succeeded.
 *  @retval     EXIT_ERROR   Any allocation, alignment, write, or free failed.
 * ========================================================================== */
static int TEST_internalFragmentation(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  ret = TEST_internalFragmentation( );
  CHECK(ret == EXIT_SUCCESS);

  LOG_INFO("Internal fragmentation test passed.\n");
  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_internalFragmentation
 *  @brief      Exercises allocations of varied small sizes.
 *
 *  @return     EXIT_SUCCESS on success, EXIT_ERROR on failure.
 *
 *  @retval     EXIT_SUCCESS  All allocations, writes, and frees succeeded.
 *  @retval     EXIT_ERROR   Any allocation, alignment, write, or free failed.
 * ========================================================================== */
static int TEST_internalFragmentation(void)
{
  int ret = EXIT_SUCCESS;

  uint8_t *ptr = NULL;

  const size_constants_t sizes[]
    = { [0] = SIZE_FIRST_ORDER,       [1] = SIZE_SECOND_ORDER,
        [2] = SIZE_THIRD_ORDER,       [3] = SIZE_FOURTH_ORDER,
        [4] = SIZE_FIFTH_ORDER,       [5] = SIZE_SIXTH_ORDER,
        [6] = SIZE_SEVENTH_ORDER,     [7] = SIZE_EIGHTH_ORDER,
        [8] = SIZE_NINTH_ORDER,       [9] = SIZE_TENTH_ORDER,
        [10] = SIZE_ELEVENTH_ORDER,   [11] = SIZE_TWELFTH_ORDER,
        [12] = SIZE_THIRTEENTH_ORDER, [13] = SIZE_TWELFTH_ORDER };

  size_t size     = 0u;
  size_t byte     = 0u;
  size_t iterator = 0u;
  size_t count    = 0u;

  count = (size_t)(sizeof(sizes) / sizeof(sizes[0]));

  for (iterator = 0u; iterator < count; ++iterator)
  {
    size = (size_t)sizes[iterator];
    ptr  = MEM_allocFirstFit(size);
    CHECK(ptr != NULL);

    CHECK(((uintptr_t)ptr % ARCH_ALIGNMENT) == 0u);

    for (byte = 0u; byte < size; ++byte)
      ptr[byte] = FILL_PATTERN;

    ret = MEM_free(ptr);
    CHECK(ret == EXIT_SUCCESS);
  }

  return ret;
}

/*< end of file >*/
