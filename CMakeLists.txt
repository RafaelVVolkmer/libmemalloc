# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: CMakeLists.txt
# Purpose:
#   Orchestrate options, target policies, tests, installation and diagnostics.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.28...4.4)

# -----------------------------------------------------------------------------
# 1. Language policy: retain the public C99 baseline and explicit dialect testing.
# -----------------------------------------------------------------------------
set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT Embedded)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
project(
  libmemalloc
  VERSION 0.0.0
  LANGUAGES C)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)
include(options)

# -----------------------------------------------------------------------------
# 2. Owned targets and target-local compile/link policy.
# -----------------------------------------------------------------------------
include(compiler-flags)
include(linker-flags)
include(targets)

# -----------------------------------------------------------------------------
# 3. Optional interoperability campaign and installed package contract.
# -----------------------------------------------------------------------------
if(LMA_BUILD_MATRIX)
  include(LanguageProfiles)
endif()
include(compatibility)
include(metadata)
include(install)
include(summary)

# EOF

