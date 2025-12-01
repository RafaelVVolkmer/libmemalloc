/** ============================================================================
 *  @ingroup    Libmemalloc
 *
 *  @brief      Graph creation, manipulation, and memory management test for
 * libmemalloc.
 *
 *  @file       test_graph.c
 *  @headerfile libmemalloc.h
 *
 *  @details    This test validates the ability of libmemalloc to handle dynamic
 *              graph data structures using adjacency lists. It covers:
 *
 *              - Dynamic allocation of the graph structure and adjacency list
 *              - Dynamic creation of edges between vertices
 *              - Proper traversal and printing of the graph's adjacency list
 *              - Full deallocation of graph and edge memory without leaks
 *
 *              The test follows these steps:
 *              1. Initializes the allocator context
 *              2. Creates a graph with MAX_VERTICES vertices
 *              3. Adds directed edges between various vertex pairs
 *              4. Prints the full adjacency list of the graph
 *              5. Frees all graph-related memory
 *
 *              All runtime assertions and error checks use the CHECK() macro
 *              to ensure that test execution halts immediately on failure.
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
 *  @brief      Standard error code returned on test failure.
 *
 *  @details    Defined as uint8_t value 1. Used by all test functions
 *              to indicate assertion failures or unexpected runtime errors
 *              detected during execution.
 * ========================================================================== */
#define EXIT_ERROR  (uint8_t)(1U)

/** ============================================================================
 *  @def        MAX_VERTICES
 *  @brief      Maximum number of vertices used in graph-related tests.
 *
 *  @details    Defines the number of vertices (5) used when creating,
 *              populating, or traversing graph structures during unit tests.
 *              Represented as size_t to match array indexing and loop counters.
 * ========================================================================== */
#define MAX_VERTICES (size_t)(5U)

/** ============================================================================
 *  @def        CHECK(expr)
 *  @brief      Assertion macro to verify runtime test conditions.
 *
 *  @param [in] expr  Boolean condition to validate.
 *
 *  @details    If the expression evaluates to false, this macro logs
 *              an error message showing the file and line number,
 *              then immediately returns EXIT_ERROR from the current function.
 *              Ensures immediate termination on assertion failure.
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
 *              P U B L I C  S T R U C T U R E S  &  T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @struct     Edge
 *  @typedef    edge_t
 *  @brief      Represents an edge in an adjacency list graph.
 *
 *  @details    Each edge points to the target vertex (`to`) and
 *              to the next edge in the adjacency list. The structure
 *              is packed and aligned according to ARCH_ALIGNMENT to
 *              ensure predictable layout for memory allocation tests.
 * ========================================================================== */
typedef struct __ALIGN Edge
{
  uint64_t     to;   /**< Target vertex index for this edge */
  struct Edge *next; /**< Pointer to the next edge in the adjacency list */
} edge_t;

/** ============================================================================
 *  @struct     Graph
 *  @typedef    graph_t
 *  @brief      Represents a graph using an adjacency list.
 *
 *  @details    The graph maintains the total number of vertices
 *              (`num_vertices`) and an array of pointers to adjacency
 *              lists (`adj`), where each list contains edges for that vertex.
 *              The structure is packed and aligned for controlled memory
 * layout.
 * ========================================================================== */
typedef struct __ALIGN Graph
{
  uint64_t num_vertices; /**< Total number of vertices in the graph */
  edge_t **adj;          /**< Array of pointers to adjacency lists (edges) */
} graph_t;

/** ============================================================================
 *          P R I V A T E  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_createGraph
 *  @brief      Allocates and initializes a new graph structure.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  vertices     Total number of vertices in the graph.
 *
 *  @return     Pointer to the newly created graph on success,
 *              NULL if any allocation fails.
 *
 *  @retval     != NULL   Successfully created graph with allocated adjacency
 * list.
 *  @retval     NULL      Allocation failure for graph or adjacency array.
 * ========================================================================== */
static graph_t *TEST_createGraph(uint64_t vertices);

/** ============================================================================
 *  @fn         TEST_addEdge
 *  @brief      Adds a directed edge to the adjacency list of a graph.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  graph       Pointer to the target graph structure.
 *  @param[in]  index       Source vertex index where the edge starts.
 *  @param[in]  vertices     Target vertex index where the edge points.
 *
 *  @return     EXIT_SUCCESS if the edge is successfully added,
 *              EXIT_ERROR if allocation fails or parameters are invalid.
 *
 *  @retval     EXIT_SUCCESS  Edge allocated and added to the adjacency list.
 *  @retval     EXIT_ERROR   Invalid parameters or memory allocation failure.
 * ========================================================================== */
static int TEST_addEdge(graph_t *graph, int index, uint64_t vertices);

/** ============================================================================
 *  @fn         TEST_printGraph
 *  @brief      Prints the adjacency list representation of a graph.
 *
 *  @param[in]  graph   Pointer to the graph to be printed.
 *
 *  @return     EXIT_SUCCESS if graph was printed,
 *              EXIT_ERROR if the graph pointer is NULL.
 *
 *  @retval     EXIT_SUCCESS  Graph printed successfully.
 *  @retval     EXIT_ERROR   Graph pointer was NULL.
 * ========================================================================== */
static int TEST_printGraph(graph_t *graph);

/** ============================================================================
 *  @fn         TEST_freeGraph
 *  @brief      Frees all memory associated with a graph, including
 *              all edges and the adjacency list array.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  graph       Pointer to the graph structure to be freed.
 *
 *  @return     EXIT_SUCCESS if all memory was freed successfully,
 *              EXIT_ERROR if any deallocation step fails.
 *
 *  @retval     EXIT_SUCCESS  Graph and all edges freed without errors.
 *  @retval     EXIT_ERROR   Failure during one of the deallocations.
 * ========================================================================== */
static int TEST_freeGraph(graph_t *graph);

/** ============================================================================
 *                          M A I N  F U N C T I O N
 * ========================================================================== */

int main(void)
{
  int ret = EXIT_SUCCESS;

  graph_t *graph = (graph_t *)NULL;

  CHECK(ret == EXIT_SUCCESS);

  graph = TEST_createGraph(MAX_VERTICES);
  CHECK(graph != NULL);

  ret = TEST_addEdge(graph, 0, 1);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 0, 4);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 1, 2);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 1, 3);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 1, 4);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 2, 3);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_addEdge(graph, 3, 4);
  CHECK(ret == EXIT_SUCCESS);

  printf("Graph adjacency list:\n");
  ret = TEST_printGraph(graph);
  CHECK(ret == EXIT_SUCCESS);

  ret = TEST_freeGraph(graph);
  CHECK(ret == EXIT_SUCCESS);

  return ret;
}

/** ============================================================================
 *                  F U N C T I O N S  D E F I N I T I O N S
 * ========================================================================== */

/** ============================================================================
 *  @fn         TEST_createGraph
 *  @brief      Allocates and initializes a new graph structure.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  vertices     Total number of vertices in the graph.
 *
 *  @return     Pointer to the newly created graph on success,
 *              NULL if any allocation fails.
 *
 *  @retval     != NULL   Successfully created graph with allocated adjacency
 * list.
 *  @retval     NULL      Allocation failure for graph or adjacency array.
 * ========================================================================== */
static graph_t *TEST_createGraph(uint64_t vertices)
{
  graph_t *graph = (graph_t *)NULL;

  size_t iterator = 0u;

  graph = MEM_allocFirstFit(sizeof(graph_t));
  if (graph == NULL)
    goto function_output;

  graph->num_vertices = vertices;

  graph->adj = MEM_allocFirstFit(((size_t)vertices * sizeof(edge_t *)));

  if (graph->adj == NULL)
    goto function_output;

  for (iterator = 0u; iterator < vertices; iterator++)
    graph->adj[iterator] = (edge_t *)NULL;

function_output:
  return graph;
}

/** ============================================================================
 *  @fn         TEST_addEdge
 *  @brief      Adds a directed edge to the adjacency list of a graph.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  graph       Pointer to the target graph structure.
 *  @param[in]  index       Source vertex index where the edge starts.
 *  @param[in]  vertices     Target vertex index where the edge points.
 *
 *  @return     EXIT_SUCCESS if the edge is successfully added,
 *              EXIT_ERROR if allocation fails or parameters are invalid.
 *
 *  @retval     EXIT_SUCCESS  Edge allocated and added to the adjacency list.
 *  @retval     EXIT_ERROR   Invalid parameters or memory allocation failure.
 * ========================================================================== */
static int TEST_addEdge(graph_t *graph, int index, uint64_t vertices)
{
  int ret = EXIT_SUCCESS;

  edge_t *edge = (edge_t *)NULL;

  CHECK(graph != NULL);

  edge = MEM_allocFirstFit(sizeof(edge_t));
  CHECK(edge != NULL);

  edge->to          = vertices;
  edge->next        = (edge_t *)graph->adj[index];
  graph->adj[index] = edge;

  return ret;
}

/** ============================================================================
 *  @fn         TEST_printGraph
 *  @brief      Prints the adjacency list representation of a graph.
 *
 *  @param[in]  graph   Pointer to the graph to be printed.
 *
 *  @return     EXIT_SUCCESS if graph was printed,
 *              EXIT_ERROR if the graph pointer is NULL.
 *
 *  @retval     EXIT_SUCCESS  Graph printed successfully.
 *  @retval     EXIT_ERROR   Graph pointer was NULL.
 * ========================================================================== */
static int TEST_printGraph(graph_t *graph)
{
  int ret = EXIT_SUCCESS;

  edge_t *edge = (edge_t *)NULL;

  size_t iterator = 0u;

  CHECK(graph != NULL);

  for (iterator = 0u; iterator < graph->num_vertices; iterator++)
  {
    printf("%lu:", (unsigned long)iterator);

    for (edge = graph->adj[iterator]; edge; edge = edge->next)
      printf(" -> %lu", (unsigned long)edge->to);

    printf("\n");
  }

  return ret;
}

/** ============================================================================
 *  @fn         TEST_freeGraph
 *  @brief      Frees all memory associated with a graph, including
 *              all edges and the adjacency list array.
 *
 *  @param[in]  allocator   Pointer to the memory allocator context.
 *  @param[in]  graph       Pointer to the graph structure to be freed.
 *
 *  @return     EXIT_SUCCESS if all memory was freed successfully,
 *              EXIT_ERROR if any deallocation step fails.
 *
 *  @retval     EXIT_SUCCESS  Graph and all edges freed without errors.
 *  @retval     EXIT_ERROR   Failure during one of the deallocations.
 * ========================================================================== */
static int TEST_freeGraph(graph_t *graph)
{
  int ret = EXIT_SUCCESS;

  edge_t *edge = (edge_t *)NULL;
  edge_t *next = (edge_t *)NULL;

  size_t iterator = 0u;

  for (iterator = 0u; iterator < graph->num_vertices; iterator++)
  {
    edge = graph->adj[iterator];
    while (edge)
    {
      next = edge->next;

      ret = MEM_free((void *)edge);
      CHECK(ret == EXIT_SUCCESS);

      edge = next;
    }
  }

  ret = MEM_free((void *)graph->adj);
  CHECK(ret == EXIT_SUCCESS);

  ret = MEM_free((void *)graph);
  CHECK(ret == EXIT_SUCCESS);

  return ret;
}

/*< end of file >*/
