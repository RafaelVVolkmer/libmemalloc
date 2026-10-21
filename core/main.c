/*
 * SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: GPL-3.0-only
 */

/** ============================================================================
 *  @file       main.c
 *  @ingroup    PIPELINE_FIXTURE
 *
 *  @brief      Exercise the library fixture from a hosted executable.
 *  @details    This application checks executable-to-library linkage. It
 *              accepts no arguments and configures no allocator or services.
 *
 *  @par Direct Module Dependencies
 *    @li @ref PIPELINE_FIXTURE_CORE_API
 *        Calls the public operation declared in mock.h.
 *
 *  @par Provided Interfaces
 *    @li @ref main
 *        The hosted process entry point returns the fixture status.
 *
 *  @par Visibility
 *              Application-owned declarations are private. Only the hosted
 *              entry point retains the external linkage required by C.
 * ========================================================================== */

/** ============================================================================
 *                     P R I V A T E - I N C L U D E S
 * ========================================================================== */

/* Module Public Header Files */
#include "mock.h"

/**
 * @addtogroup PIPELINE_FIXTURE_CORE_ENTRY
 * @{
 */

/** ============================================================================
 *               A P P L I C A T I O N - E N T R Y - P O I N T
 *     Hosted C entry point; retain the name and signature required by C.
 * ========================================================================== */

/** ============================================================================
 *  @brief      Call the library fixture and return its status to the host.
 *  @details    Calls MOCK_identity() once. The fixture currently always
 *              succeeds; the forwarding path preserves a nonzero result if
 *              the fixture contract is changed in a future revision.
 *
 *  @return     The fixture status as the hosted process exit status.
 *          @retval     0 Successful completion of the linkage check.
 *
 *  @post       No application-owned resources remain to be released.
 *
 *  @par Side Effects
 *              Process termination only; the application performs no I/O.
 *  @par Complexity
 *              Constant time and constant automatic storage.
 *
 *  @see        MOCK_identity
 *  @showrefs
 * ========================================================================== */
int main(void)
{
	int ret = 0;

	ret = MOCK_identity();
	if (ret != 0)
		goto function_output;

function_output:
	return ret;
}

/** @} */

/* EOF */

