# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/options.cmake
# Purpose:
#   Declare build controls and reject incompatible requested policies.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

include_guard(GLOBAL)

# -----------------------------------------------------------------------------
# 1. Product scope and conventional CMake controls.
# -----------------------------------------------------------------------------
option(LMA_BUILD_MOCK "Build the distribution fixture, not an allocator" OFF)
option(LMA_ENABLE_GC "Enable the experimental garbage collector" OFF)
option(LMA_ENABLE_INTERPOSITION "Enable optional allocator interposition" OFF)
option(BUILD_SHARED_LIBS "Build a shared library" OFF)
option(LMA_BUILD_MOCK_CONSUMER "Build the fixture consumer" OFF)
option(LMA_BUILD_MATRIX "Enable capability and interoperability tests" OFF)
option(LMA_BUILD_DOCS "Expose the existing Lua/Doxygen build as a docs target" OFF)
option(LMA_BUILD_TESTS "Run owned build/install smoke tests" OFF)
option(LMA_ENABLE_ASM "Enable Assembly for explicitly selected sources" OFF)
option(LMA_WARNINGS_AS_ERRORS "Reject warnings in owned sources" ON)
option(LMA_HARDENING "Probe and enable applicable defense options" ON)
option(LMA_RELEASE_MINIMIZE "Remove release debug data and non-exported linked symbols" ON)
option(LMA_ENABLE_COVERAGE "Instrument owned targets for gcov-compatible coverage" OFF)
option(LMA_ENABLE_ANALYZER "Enable GCC's compile-time analyzer" OFF)
set(LMA_SANITIZERS
    ""
    CACHE STRING "Explicit semicolon-separated sanitizer list")
set(LMA_IPO
    AUTO
    CACHE STRING "Release IPO: AUTO, ON or OFF; AUTO preserves portable archives")
set_property(CACHE LMA_IPO PROPERTY STRINGS AUTO ON OFF)
set(LMA_CET
    AUTO
    CACHE STRING "x86 control-flow code generation: AUTO, ON or OFF")
set_property(CACHE LMA_CET PROPERTY STRINGS AUTO ON OFF)
set(LMA_AARCH64_HARDEN
    AUTO
    CACHE STRING "AArch64 branch protection: AUTO, ON or OFF")
set_property(CACHE LMA_AARCH64_HARDEN PROPERTY STRINGS AUTO ON OFF)

if(NOT LMA_BUILD_MOCK)
  message(FATAL_ERROR "Only the mock is implemented. Pass -DLMA_BUILD_MOCK=ON for qualification.")
endif()
if(LMA_ENABLE_GC OR LMA_ENABLE_INTERPOSITION)
  message(FATAL_ERROR "GC and interposition are not implemented by this fixture.")
endif()
foreach(setting IN ITEMS LMA_IPO LMA_CET LMA_AARCH64_HARDEN)
  if(NOT "${${setting}}" MATCHES "^(AUTO|ON|OFF)$")
    message(FATAL_ERROR "${setting} must be AUTO, ON or OFF")
  endif()
endforeach()
if(LMA_ENABLE_COVERAGE AND LMA_SANITIZERS)
  message(FATAL_ERROR "Coverage and sanitizers require separate evidence builds")
endif()
if(LMA_ENABLE_ANALYZER AND NOT CMAKE_C_COMPILER_ID STREQUAL "GNU")
  message(
    FATAL_ERROR "LMA_ENABLE_ANALYZER requires GCC; use the Clang analysis workflow separately")
endif()
if(LMA_ENABLE_ASM)
  enable_language(ASM)
endif()

# -----------------------------------------------------------------------------
# 2. Configuration and outputs stay inside each independent build tree.
# -----------------------------------------------------------------------------
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE
      Release
      CACHE STRING "Build configuration" FORCE)
endif()
if(NOT CMAKE_CONFIGURATION_TYPES)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
endif()
if(DEFINED CMAKE_LINKER_TYPE AND CMAKE_VERSION VERSION_LESS 3.29)
  message(FATAL_ERROR "CMAKE_LINKER_TYPE requires CMake 3.29 or newer")
endif()
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
if(NOT DEFINED CMAKE_C_STANDARD)
  set(CMAKE_C_STANDARD 99)
endif()
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/bin/$<CONFIG>")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib/$<CONFIG>")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/lib/$<CONFIG>")

# Record only declarations from CMake's toolchain; host virtualization is not proof of emulation.
if(CMAKE_CROSSCOMPILING
   AND LMA_BUILD_TESTS
   AND NOT CMAKE_CROSSCOMPILING_EMULATOR)
  message(FATAL_ERROR "Cross-target execution tests require CMAKE_CROSSCOMPILING_EMULATOR")
endif()

# -----------------------------------------------------------------------------
# 3. Verify compiler target macros when an orchestration contract supplies an arch.
# -----------------------------------------------------------------------------
if(DEFINED LMA_EXPECT_ARCH)
  include(CheckCSourceCompiles)
  set(_arch_x86_64 "defined(__x86_64__) || defined(_M_X64)")
  set(_arch_aarch64 "defined(__aarch64__) || defined(_M_ARM64)")
  set(_arch_i686 "defined(__i386__) || defined(_M_IX86)")
  set(_arch_armv7 "defined(__arm__) && defined(__ARM_ARCH) && __ARM_ARCH == 7")
  set(_arch_riscv64 "defined(__riscv) && __riscv_xlen == 64")
  set(_arch_wasm32 "defined(__wasm32__)")
  if(NOT DEFINED _arch_${LMA_EXPECT_ARCH})
    message(FATAL_ERROR "Unsupported architecture contract: ${LMA_EXPECT_ARCH}")
  endif()
  check_c_source_compiles(
    "#if !(${_arch_${LMA_EXPECT_ARCH}})
    #error Compiler target differs from requested architecture
    #endif
    int main(void) { return 0; }"
    LMA_ARCH_${LMA_EXPECT_ARCH}_MATCHES)
  if(NOT LMA_ARCH_${LMA_EXPECT_ARCH}_MATCHES)
    message(FATAL_ERROR "Compiler target does not match ${LMA_EXPECT_ARCH}")
  endif()
endif()

# Validate the compiler's OS macros as well as the toolchain's declared name.
if(DEFINED LMA_EXPECT_OS)
  include(CheckCSourceCompiles)
  set(_os_linux "defined(__linux__)")
  set(_os_windows "defined(_WIN32)")
  set(_os_macos "defined(__APPLE__) && defined(__MACH__)")
  set(_os_freebsd "defined(__FreeBSD__)")
  set(_os_emscripten "defined(__EMSCRIPTEN__)")
  if(NOT DEFINED _os_${LMA_EXPECT_OS})
    message(FATAL_ERROR "Unsupported operating-system contract: ${LMA_EXPECT_OS}")
  endif()
  check_c_source_compiles(
    "#if !(${_os_${LMA_EXPECT_OS}})
    #error Compiler OS differs from requested platform
    #endif
    int main(void) { return 0; }"
    LMA_OS_${LMA_EXPECT_OS}_MATCHES)
  if(NOT LMA_OS_${LMA_EXPECT_OS}_MATCHES)
    message(FATAL_ERROR "Compiler target does not match ${LMA_EXPECT_OS}")
  endif()
endif()

# EOF

