/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Heap exhaustion stress test for libmemalloc.
 *
 *  @file       test_heap.c
 *  @headerfile libmemalloc.h
 *
 *  @details    This test performs a stress allocation loop to repeatedly
 *              allocate fixed-size memory blocks until the heap space is
 *              exhausted. After reaching the allocation limit or failure,
 *              it logs the number of successfully allocated blocks and
 *              then frees all allocated memory to validate that
 *              deallocations work properly after high allocation pressure.
 *
 *              The test covers:
 *              - Consecutive allocations up to MAX_BLOCKS or until failure
 *              - Tracking allocated pointers in a local array
 *              - Logging the number of successful allocations
 *              - Full cleanup and free verification
 *
 *              Each allocation uses MEM_allocMallocFirstFit, and all
 *              deallocations use MEM_allocFree. Runtime assertions are
 *              checked via the CHECK() macro.
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
 *  @def        EXIT_ERROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1. Used by test
 *              functions to indicate failure when a CHECK() macro
 *              assertion fails.
 * ========================================================================== */
#define EXIT_ERROR (uint8_t)(1U)

/** ============================================================================
 *  @def        BLOCK_SIZE
 *  @brief      Defines the default block size for allocation tests.
 *
 *  @details    Specifies the size (in bytes or elements, context-dependent)
 *              for memory blocks used during testing. Set to 10UL
 *              as a uint64_t constant to avoid implicit type conversions.
 * ========================================================================== */
#define BLOCK_SIZE (uint64_t)(1024U)

/** ============================================================================
 *  @def        MAX_BLOCKS
 *  @brief      Alias for BLOCK_SIZE used when representing the
 *              maximum number of blocks in tests.
 *
 *  @details    Provides semantic clarity when using BLOCK_SIZE
 *              as a block count limit instead of a byte size.
 * ========================================================================== */
#define MAX_BLOCKS 1000

/** ============================================================================
 *  @def        CHECK(expr)
 *  @brief      Assertion macro to validate test expressions at runtime.
 *
 *  @param [in] expr  Boolean condition to evaluate.
 *
 *  @details    Checks the given condition and, if false, logs an error
 *              including file and line number, then immediately returns
 *              EXIT_ERROR from the current function. Prevents further
 *              execution of failing tests.
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
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  void *ptr = NULL;

  void *ptrs[MAX_BLOCKS];

  size_t count    = 0u;
  size_t iterator = 0u;

  while (count < MAX_BLOCKS)
  {
    ptr = MEM_allocFirstFit(BLOCK_SIZE);
    if (ptr == NULL)
      break;

    ptrs[count++] = ptr;
  }

  LOG_INFO("Allocated %zu blocks of %lu bytes until heap exhaustion",
           count,
           (unsigned long)BLOCK_SIZE);

  for (iterator = 0; iterator < count; ++iterator)
  {
    ret = MEM_free(ptrs[iterator]);
    CHECK(ret == EXIT_SUCCESS);
  }

  return ret;
}

/*< end of file >*/
