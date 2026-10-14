/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

/** ============================================================================
 *  @file       mock.c
 *  @ingroup    PIPELINE_FIXTURE
 *
 *  @brief      Implement the public release-pipeline fixture operation.
 *  @details    The translation unit supplies a deterministic success result
 *              for build, link, install, and packaging checks. It owns no
 *              allocator state, runtime ports, or private storage objects.
 *
 *  @par Used By
 *    @li @ref main.c
 *        Exercises the library symbol through its public declaration.
 *
 *  @par Provided Interfaces
 *    @li @ref mock.h
 *        Declares the fixture operation implemented by this file.
 * ========================================================================== */

/** ============================================================================
 *                     P R I V A T E - I N C L U D E S
 * ========================================================================== */

/* Module Public Header */
#include "mock.h"

/**
 * @addtogroup PIPELINE_FIXTURE_CORE_API
 * @{
 */

/** ============================================================================
 *          P U B L I C - F U N C T I O N S - D E F I N I T I O N S
 *        Definitions of functions declared in the module public header.
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
int MOCK_identity(void)
{
	int ret = 0;

	goto function_output;

function_output:
	return ret;
}

/** @} */

/* EOF */

