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
 *              and return EXIT_SUCCESS or EXIT_ERROR.
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
 *  @def        EXIT_ERROR
 *  @brief      Standard error return code for test failures.
 *
 *  @details    Defined as a uint8_t value of 1 to indicate any
 *              assertion or test step failure within the test suite.
 *              Returned by test functions when a CHECK() fails.
 * ========================================================================== */
#define EXIT_ERROR (uint8_t)(1U)

/** ============================================================================
 *  @def        FILL_VALUE
 *  @brief      Byte pattern used to initialize allocated memory.
 *
 *  @details    Defined as 0xFF to fill newly allocated blocks
 *              with a recognizable non-zero pattern. Useful for
 *              validating that memory writes and clears occur correctly.
 * ========================================================================== */
#define FILL_VALUE  (uint8_t)(0xFFU)

/** ============================================================================
 *  @def        ARR_LEN
 *  @brief      Default length for array-based allocation tests.
 *
 *  @details    Specifies the number of elements (10) used by
 *              TEST_testCalloc and other tests that allocate arrays.
 * ========================================================================== */
#define ARR_LEN     (uint8_t)(10U)

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
      return EXIT_ERROR;                                                    \
    }                                                                        \
  } while (0)

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_mallocFree
 *  @brief      Tests allocation and deallocation of a single pointer
 *              using MEM_allocMallocFirstFit and MEM_allocFree.
 *
 *  @return     EXIT_SUCCESS on successful alloc + free
 *              EXIT_ERROR on any failure during test
 *
 *  @retval     EXIT_SUCCESS  Pointer allocated, memset applied, and freed
 *  @retval     EXIT_ERROR   Allocation or free operation failed
 * ========================================================================== */
static int TEST_mallocFree(void);

/** ============================================================================
 *  @fn         TEST_testCalloc
 *  @brief      Verifies that MEM_allocCalloc zero-initializes an array of ints.
 *
 *  @return     EXIT_SUCCESS if all elements are zero and free succeeds
 *              EXIT_ERROR if any element is non-zero or free fails
 *
 *  @retval     EXIT_SUCCESS  All array elements zero and memory freed
 *  @retval     EXIT_ERROR   Allocation, zero-check or free operation failed
 * ========================================================================== */
static int TEST_testCalloc(void);

/** ============================================================================
 *  @fn         TEST_testRealloc
 *  @brief      Tests MEM_allocRealloc grows the block and preserves contents.
 *
 *  @return     EXIT_SUCCESS on successful realloc and content check
 *              EXIT_ERROR on any failure during realloc or strcmp
 *
 *  @retval     EXIT_SUCCESS  Realloc succeeded and original data intact
 *  @retval     EXIT_ERROR   Reallocation or data verification failed
 * ========================================================================== */
static int TEST_testRealloc(void);

/** ============================================================================
 *  @fn         TEST_testAlign
 *  @brief      Checks that MEM_allocMallocFirstFit returns pointers aligned
 *              on ARCH_ALIGNMENT boundary.
 *
 *  @return     EXIT_SUCCESS when pointer is properly aligned and freed
 *              EXIT_ERROR when alignment or free operation fails
 *
 *  @retval     EXIT_SUCCESS  Pointer aligned and free succeeded
 *  @retval     EXIT_ERROR   Alignment check or free operation failed
 * ========================================================================== */
static int TEST_testAlign(void);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  ret = TEST_mallocFree( );
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_testCalloc( );
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_testRealloc( );
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_testAlign( );
  CHECK(ret == EXIT_SUCCESS);

  LOG_INFO("All tests passed. ret = %d\n", ret);

  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_mallocFree
 *  @brief      Tests allocation and deallocation of a single pointer
 *              using MEM_allocMallocFirstFit and MEM_allocFree.
 *
 *  @return     EXIT_SUCCESS on successful alloc + free
 *              EXIT_ERROR on any failure during test
 *
 *  @retval     EXIT_SUCCESS  Pointer allocated, memset applied, and freed
 *  @retval     EXIT_ERROR   Allocation or free operation failed
 * ========================================================================== */
static int TEST_mallocFree(void)
{
  int ret = EXIT_SUCCESS;

  void *ptr = NULL;

  ptr = MEM_allocFirstFit(sizeof(void *));
  CHECK(ptr != NULL);

  memset(ptr, FILL_VALUE, sizeof(void *));

  ret = MEM_free(ptr);
  CHECK(ret == EXIT_SUCCESS);

  return ret;
}

/** ============================================================================
 *  @fn         TEST_testCalloc
 *  @brief      Verifies that MEM_allocCalloc zero-initializes an array of ints.
 *
 *  @return     EXIT_SUCCESS if all elements are zero and free succeeds
 *              EXIT_ERROR if any element is non-zero or free fails
 *
 *  @retval     EXIT_SUCCESS  All array elements zero and memory freed
 *  @retval     EXIT_ERROR   Allocation, zero-check or free operation failed
 * ========================================================================== */
static int TEST_testCalloc(void)
{
  int ret = EXIT_SUCCESS;

  int *arr = NULL;

  size_t iterator = 0u;

  arr = MEM_calloc((ARR_LEN * sizeof(int)), FIRST_FIT);
  CHECK(arr != NULL);

  for (iterator = 0u; iterator < ARR_LEN; iterator++)
  {
    CHECK(arr[iterator] == 0);
  }

  ret = MEM_free(arr);
  CHECK(ret == EXIT_SUCCESS);

  return ret;
}

/** ============================================================================
 *  @fn         TEST_testRealloc
 *  @brief      Tests MEM_allocRealloc grows the block and preserves contents.
 *
 *  @return     EXIT_SUCCESS on successful realloc and content check
 *              EXIT_ERROR on any failure during realloc or strcmp
 *
 *  @retval     EXIT_SUCCESS  Realloc succeeded and original data intact
 *  @retval     EXIT_ERROR   Reallocation or data verification failed
 * ========================================================================== */
static int TEST_testRealloc(void)
{
  int ret = EXIT_SUCCESS;

  char *ptr_0 = NULL;
  char *ptr_1 = NULL;

  ptr_0 = MEM_allocFirstFit(ARR_LEN);
  CHECK(ptr_0 != NULL);

  strcpy(ptr_0, "hi");

  ptr_1 = MEM_realloc(ptr_0, (2u * ARR_LEN), FIRST_FIT);
  CHECK(ptr_1 != NULL);

  CHECK(strcmp(ptr_1, "hi") == EXIT_SUCCESS);

  ret = MEM_free(ptr_1);
  CHECK(ret == EXIT_SUCCESS);

  return ret;
}

/** ============================================================================
 *  @fn         TEST_testAlign
 *  @brief      Checks that MEM_allocMallocFirstFit returns pointers aligned
 *              on ARCH_ALIGNMENT boundary.
 *
 *  @return     EXIT_SUCCESS when pointer is properly aligned and freed
 *              EXIT_ERROR when alignment or free operation fails
 *
 *  @retval     EXIT_SUCCESS  Pointer aligned and free succeeded
 *  @retval     EXIT_ERROR   Alignment check or free operation failed
 * ========================================================================== */
static int TEST_testAlign(void)
{
  void *ptr = NULL;

  ptr = MEM_allocFirstFit(sizeof(void *));
  CHECK(ptr != NULL);

  CHECK(((uintptr_t)ptr % ARCH_ALIGNMENT) == 0u);

  return MEM_free(ptr);
}

/*< end of file >*/
