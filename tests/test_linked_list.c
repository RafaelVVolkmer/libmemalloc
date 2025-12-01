/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Linked list reversal and memory management test for libmemalloc.
 *
 *  @file       test_linked_list.c
 *  @headerfile libmemalloc.h
 *
 *  @details    This test validates the correct behavior of libmemalloc when
 *              dynamically allocating and freeing a singly linked list.
 *              It specifically tests:
 *
 *              - Allocation of multiple linked list nodes
 *              - Correct population of node data and next pointers
 *              - Reversal of the linked list using pointer manipulation
 *              - Printing the list before and after reversal
 *              - Deallocation of all nodes using MEM_allocFree
 *
 *              All operations are checked using the CHECK() macro to ensure
 *              proper error handling and runtime safety. The allocator
 *              context is initialized at the start and all memory is
 *              freed before program termination.
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
 *  @def        EXIT_ERRROR
 *  @brief      Standard error code for test failure scenarios.
 *
 *  @details    Defined as uint8_t value 1. Used as the return code
 *              from test functions when a CHECK() macro detects
 *              a failed assertion or runtime error condition.
 * ========================================================================== */
#define EXIT_ERRROR (uint8_t)(1U)

/** ============================================================================
 *  @def        MAX_NODES
 *  @brief      Maximum number of nodes used in linked list tests.
 *
 *  @details    Defines the total number of nodes (5) to be allocated,
 *              initialized, and manipulated during linked list unit tests.
 * ========================================================================== */
#define MAX_NODES   (uint8_t)(5U)

/** ============================================================================
 *  @def        CHECK(expr)
 *  @brief      Runtime assertion macro for validating test conditions.
 *
 *  @param [in] expr  Boolean expression to evaluate.
 *
 *  @details    Evaluates the given expression, and if the condition fails,
 *              logs an error message with file and line number context,
 *              then returns EXIT_ERRROR to indicate test failure.
 *              Halts further execution of the current test function.
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
 *              P U B L I C  S T R U C T U R E S  &  T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @struct     Node
 *  @typedef    node_t
 *  @brief      Represents a node in a singly linked list.
 *
 *  @details    Each node contains a 64-bit data field and a pointer
 *              to the next node in the list. The structure is packed
 *              and aligned according to ARCH_ALIGNMENT to ensure
 *              predictable memory layout for testing and performance.
 * ========================================================================== */
typedef struct __ALIGN Node
{
  uint64_t     data; /**< Data stored in the node (64-bit value) */
  struct Node *next; /**< Pointer to the next node in the list */
} node_t;

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_reverseList
 *  @brief      Reverses the order of nodes in a singly linked list.
 *
 *  @param[in]  head    Pointer to the head node of the original list.
 *
 *  @return     Pointer to the new head node after reversal.
 *              NULL if the input list is empty.
 *
 *  @retval     != NULL   New head node of the reversed list.
 *  @retval     NULL      If the input list was empty (head == NULL).
 * ========================================================================== */
static int TEST_printList(node_t *head);

/** ============================================================================
 *  @fn         TEST_printList
 *  @brief      Prints the contents of a singly linked list to stdout.
 *
 *  @param[in]  head    Pointer to the head node of the list to print.
 *
 *  @return     EXIT_SUCCESS if the list was printed successfully.
 *              EXIT_ERRROR if the input list is empty.
 *
 *  @retval     EXIT_SUCCESS  List printed correctly (non-empty list).
 *  @retval     EXIT_ERRROR   Input list was empty (head == NULL).
 * ========================================================================== */
static node_t *TEST_reverseList(node_t *head);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  node_t *head = (node_t *)NULL;
  node_t *node = (node_t *)NULL;
  node_t *iter = (node_t *)NULL;
  node_t *next = (node_t *)NULL;

  size_t iterator = 0u;

  for (iterator = 1u; iterator <= MAX_NODES; ++iterator)
  {
    node = MEM_allocFirstFit(sizeof(node_t));
    CHECK(node != NULL);

    node->data = iterator;
    node->next = head;
    head       = node;
  }

  printf("Original list: ");
  ret = TEST_printList(head);
  CHECK(ret == EXIT_SUCCESS);

  head = TEST_reverseList(head);
  CHECK(head != NULL);

  printf("Reversed list: ");
  ret = TEST_printList(head);
  CHECK(ret == EXIT_SUCCESS);

  for (iter = head; iter;)
  {
    next = iter->next;
    ret  = MEM_free((void *)iter);
    CHECK(ret == EXIT_SUCCESS);
    iter = next;
  }

  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_reverseList
 *  @brief      Reverses the order of nodes in a singly linked list.
 *
 *  @param[in]  head    Pointer to the head node of the original list.
 *
 *  @return     Pointer to the new head node after reversal.
 *              NULL if the input list is empty.
 *
 *  @retval     != NULL   New head node of the reversed list.
 *  @retval     NULL      If the input list was empty (head == NULL).
 * ========================================================================== */
static node_t *TEST_reverseList(node_t *head)
{
  node_t *prev    = (node_t *)NULL;
  node_t *current = (node_t *)NULL;
  node_t *next    = (node_t *)NULL;

  if (head == NULL)
    goto function_output;

  current = head;

  while (current)
  {
    next          = current->next;
    current->next = prev;
    prev          = current;
    current       = next;
  }

function_output:
  return prev;
}

/** ============================================================================
 *  @fn         TEST_printList
 *  @brief      Prints the contents of a singly linked list to stdout.
 *
 *  @param[in]  head    Pointer to the head node of the list to print.
 *
 *  @return     EXIT_SUCCESS if the list was printed successfully.
 *              EXIT_ERRROR if the input list is empty.
 *
 *  @retval     EXIT_SUCCESS  List printed correctly (non-empty list).
 *  @retval     EXIT_ERRROR   Input list was empty (head == NULL).
 * ========================================================================== */
static int TEST_printList(node_t *head)
{
  int ret = EXIT_SUCCESS;

  node_t *iter = (node_t *)NULL;

  if (head == NULL)
  {
    ret = EXIT_ERRROR;
    goto function_output;
  }

  iter = head;

  while (iter)
  {
    printf("%lu -> ", (unsigned long)iter->data);
    iter = iter->next;
  }

  printf("NULL\n");

function_output:
  return ret;
}

/*< end of file >*/
