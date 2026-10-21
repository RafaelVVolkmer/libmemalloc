# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/summary.cmake
# Purpose:
#   Report effective build scope without guessing emulation or conformity.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Environment and selected policies; actual probe results remain in the cache.
# -----------------------------------------------------------------------------
message(STATUS "libmemalloc ${PROJECT_VERSION}: distribution fixture only")
message(STATUS "CMake ${CMAKE_VERSION}; generator: ${CMAKE_GENERATOR}")
message(STATUS "Compiler: ${CMAKE_C_COMPILER_ID} ${CMAKE_C_COMPILER_VERSION}")
message(STATUS "Target: ${CMAKE_SYSTEM_NAME}/${CMAKE_SYSTEM_PROCESSOR}; C${CMAKE_C_STANDARD}")
message(STATUS "Configuration: ${CMAKE_BUILD_TYPE}; multi-config: ${CMAKE_CONFIGURATION_TYPES}")
message(STATUS "Shared: ${BUILD_SHARED_LIBS}; hardening: ${LMA_HARDENING}; IPO: ${LMA_IPO}")
message(STATUS "Sanitizers: ${LMA_SANITIZERS}; coverage: ${LMA_ENABLE_COVERAGE}")
message(
  STATUS "Cross compiling: ${CMAKE_CROSSCOMPILING}; emulator: ${CMAKE_CROSSCOMPILING_EMULATOR}")
message(STATUS "Artifacts: ${PROJECT_BINARY_DIR}/lib and bin by configuration")
message(STATUS "No badge, SLSA level or production qualification follows from configuration")

file(WRITE "${PROJECT_BINARY_DIR}/build-platform.txt"
     "${CMAKE_SYSTEM_NAME}\n${CMAKE_SYSTEM_PROCESSOR}\n")

file(WRITE "${PROJECT_BINARY_DIR}/build-tools.txt"
     "${CMAKE_C_COMPILER}\n${CMAKE_LINKER}\n${CMAKE_AR}\n${CMAKE_RANLIB}\n${CMAKE_MAKE_PROGRAM}\n")

# EOF

