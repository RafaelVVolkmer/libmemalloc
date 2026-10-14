/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

/** ============================================================================
 *  @file       mock.h
 *  @ingroup    PIPELINE_FIXTURE
 *
 *  @brief      Declare the public release-pipeline fixture operation.
 *  @details    This interface checks packaging and linkage during repository
 *              reorganization. It is not an allocator API or a stable product
 *              compatibility promise. No dependency headers are required.
 *
 *  @par Used By
 *    @li @ref mock.c
 *        Implements the library symbol exported by the fixture.
 *    @li @ref main.c
 *        Calls the operation to check executable-to-library linkage.
 *
 *  @par Provided Interfaces
 *    @li @ref PIPELINE_FIXTURE_CORE_API
 *        A parameterless operation returning a fixed success result.
 *
 *  @par Compatibility
 *              The declaration supports C and C++ consumers using C linkage.
 *
 *  @includedbygraph
 * ========================================================================== */

/* Include Guard */
#if !defined(LIBMEMALLOC_MOCK_H)
  #define LIBMEMALLOC_MOCK_H

  /* Public symbol visibility for installed shared-library consumers. */
  #if defined(_WIN32) && defined(LMA_SHARED_LIBRARY)
    #if defined(LMA_BUILDING_SHARED)
      #define LMA_API __declspec(dllexport)
    #else
      #define LMA_API __declspec(dllimport)
    #endif
  #elif defined(__GNUC__) || defined(__clang__)
    #define LMA_API __attribute__((visibility("default")))
  #else
    #define LMA_API
  #endif

  /* C++ Compatibility */
  #ifdef __cplusplus
extern "C"
{
  #endif

/**
 * @addtogroup PIPELINE_FIXTURE_CORE_API
 * @{
 */

/** ============================================================================
 *          P U B L I C - F U N C T I O N S - P R O T O T Y P E S
 *                Public operations provided by the owning module.
 * ========================================================================== */

/** ============================================================================
 *  @brief      Return the success result used by packaging checks.
 *  @details    This fixture supplies one linkable library symbol. It performs
 *              no allocation and implements no allocator behavior.
 *
 *  @return     The fixed fixture status; this operation has no failure path.
 *          @retval     0 The fixture completed successfully.
 *
 *  @post       No shared state or resources have changed.
 *
 *  @par Thread Safety
 *              Concurrent and recursive calls are independent; no lock is
 *              required because the operation accesses no shared state.
 *  @par Side Effects
 *              None; no allocation, callbacks, or external I/O occurs.
 *  @par Complexity
 *              Constant time and constant automatic storage per call.
 *
 *  @showrefby
 * ========================================================================== */
LMA_API int MOCK_identity(void);

  /** @} */

  /* C++ Compatibility */
  #ifdef __cplusplus
}
  #endif

#endif /* LIBMEMALLOC_MOCK_H */

/* EOF */

