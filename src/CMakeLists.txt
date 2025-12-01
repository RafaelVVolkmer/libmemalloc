# ------------------------------------------------------------------------------
# File: src/CMakeLists.txt (or cmake/memalloc-lib.cmake)
# Purpose:
#   Build the official static/shared "memalloc" libraries and, optionally,
#   a test-only shared library that can be instrumented (e.g. for coverage)
#   without touching the official artifacts.
#
# SPDX-License-Identifier: MIT
#
# Requirements:
#   - CMake >= 3.18 (generator expressions & per-config output dirs used here)
#   - Threads package
#   - GCC/Clang on Unix for version-script options (optional)
#
# Options (cache):
#   RM_CONSTRUCT                 : BOOL  -nostartfiles for shared (GNU/Clang, Linux)
#   MEMALLOC_OUTPUT_DIR          : PATH  Base dir for build outputs (default: ${CMAKE_BINARY_DIR}/bin)
#   MEMALLOC_BUILD_TEST_SHARED   : BOOL  Build a test-only shared lib (default: ON if BUILD_TESTING)
#   MEMALLOC_INSTRUMENT_TEST_SHARED: BOOL Add -O0 -g --coverage to test-only lib (default: OFF)
#
# Exports & Install:
#   - Exports official libs under "memallocTargets" (test-only lib is never installed/exported)
#
# Notes:
#   - Output directories are set to be reliable across single-config (Ninja/Make)
#     and multi-config (VS/Xcode) generators.
#   - The test-only shared lib target is called: libmemalloc_shared_test (alias memalloc::test).
# ------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.18)

include_guard(GLOBAL)
include(GNUInstallDirs)

# ------------------------------------------------------------------------------
# 1. User options & version
# ------------------------------------------------------------------------------
option(RM_CONSTRUCT "Do not link GCC/GLIBC startup files (crt*)" OFF)

set(MEMALLOC_VERSION "2.0.0" CACHE STRING "Project semantic version")
string(REPLACE "." ";" _vlist "${MEMALLOC_VERSION}")
list(GET _vlist 0 MEMALLOC_SOVERSION)

set(MEMALLOC_OUTPUT_DIR
    "${CMAKE_SOURCE_DIR}/bin"
    CACHE PATH "Base output directory for memalloc artifacts")

if(BUILD_TESTING)
  set(_default_build_test_shared ON)
else()
  set(_default_build_test_shared OFF)
endif()
option(MEMALLOC_BUILD_TEST_SHARED
       "Build a test-only shared lib for unit tests"
       ${_default_build_test_shared})

option(MEMALLOC_INSTRUMENT_TEST_SHARED
       "Instrument test-only shared lib with -O0 -g --coverage"
       ON)

if(ENABLE_COVERAGE)
  set(MEMALLOC_INSTRUMENT_TEST_SHARED ON CACHE BOOL "" FORCE)
endif()

# ------------------------------------------------------------------------------
# 2. User options & version
# ------------------------------------------------------------------------------
set(LIBMEMALLOC_SOURCES
  "${CMAKE_CURRENT_SOURCE_DIR}/libmemalloc.c"
)

set(PUBLIC_HDRS
  "${CMAKE_SOURCE_DIR}/inc/libmemalloc.h"
)

# 2.1. Optional GNU ld version script (Linux/GNU ld or LLD)
set(MEMALLOC_MAP "${CMAKE_CURRENT_SOURCE_DIR}/../libmemalloc.map")

find_package(Threads REQUIRED)

# ------------------------------------------------------------------------------
# 3. Helper: output directories
# ------------------------------------------------------------------------------
function(_memalloc_set_output_dirs tgt)
  # 3.1. Single-config (Makefiles/Ninja): set base folder
  set_target_properties("${tgt}" PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${MEMALLOC_OUTPUT_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${MEMALLOC_OUTPUT_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${MEMALLOC_OUTPUT_DIR}"
  )

  # 3.2. Multi-config (VS/Xcode): add per-config subfolders
  foreach(cfg Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER "${cfg}" CFGU)
    set_target_properties("${tgt}" PROPERTIES
      "ARCHIVE_OUTPUT_DIRECTORY_${CFGU}" "${MEMALLOC_OUTPUT_DIR}/${cfg}"
      "LIBRARY_OUTPUT_DIRECTORY_${CFGU}" "${MEMALLOC_OUTPUT_DIR}/${cfg}"
      "RUNTIME_OUTPUT_DIRECTORY_${CFGU}" "${MEMALLOC_OUTPUT_DIR}/${cfg}"
    )
  endforeach()
endfunction()

# ------------------------------------------------------------------------------
# 4. Object library (common)
# ------------------------------------------------------------------------------
add_library(libmemalloc_obj OBJECT ${LIBMEMALLOC_SOURCES})

target_include_directories(libmemalloc_obj
  PRIVATE
    $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/inc>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

set_target_properties(libmemalloc_obj PROPERTIES
  C_STANDARD 23
  C_STANDARD_REQUIRED YES
  C_EXTENSIONS OFF
  POSITION_INDEPENDENT_CODE ON
  C_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN YES
  COMPILE_WARNING_AS_ERROR ON
)

target_compile_definitions(libmemalloc_obj
  PRIVATE
    $<$<CONFIG:Debug>:LOG_LEVEL=LOG_LEVEL_DEBUG>
)

# ------------------------------------------------------------------------------
# 5. Static library (official)
# ------------------------------------------------------------------------------
add_library(libmemalloc_static STATIC
  $<TARGET_OBJECTS:libmemalloc_obj>
)

set_target_properties(libmemalloc_static PROPERTIES
  OUTPUT_NAME memalloc
  EXPORT_NAME memalloc_static
  INTERPROCEDURAL_OPTIMIZATION $<STREQUAL:$<CONFIG>,Release>
)

# 5.1. ut outputs in consistent folders
_memalloc_set_output_dirs(libmemalloc_static)

#  5.2. Hide this archive when linked into other targets (GNU ld)
target_link_options(libmemalloc_static INTERFACE
  "-Wl,--exclude-libs,memalloc"
)

target_link_libraries(libmemalloc_static
  PRIVATE Threads::Threads
)

# ------------------------------------------------------------------------------
# 6. Shared library (official)
# ------------------------------------------------------------------------------
add_library(libmemalloc_shared SHARED
  $<TARGET_OBJECTS:libmemalloc_obj>
)

set_target_properties(libmemalloc_shared PROPERTIES
  OUTPUT_NAME memalloc
  EXPORT_NAME memalloc
  VERSION   ${MEMALLOC_VERSION}
  SOVERSION ${MEMALLOC_SOVERSION}
  INTERPROCEDURAL_OPTIMIZATION $<STREQUAL:$<CONFIG>,Release>
  LINK_DEPENDS "${MEMALLOC_MAP}"
  LINK_WHAT_YOU_USE ON
  INSTALL_RPATH "$ORIGIN"
  PUBLIC_HEADER "${PUBLIC_HDRS}"
)

# 6.1. Put outputs in consistent folders
_memalloc_set_output_dirs(libmemalloc_shared)

# 6.2. Platform-specific link options (Linux/GNU/Clang)
if(UNIX AND NOT APPLE AND CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  if (NOT EXISTS "${MEMALLOC_MAP}")
    message(FATAL_ERROR "Version script not found: ${MEMALLOC_MAP}")
  endif()
  target_link_options(libmemalloc_shared PRIVATE
    "-Wl,--version-script=${MEMALLOC_MAP}"
    "-Wl,--exclude-libs,ALL"
    "-Wl,--no-undefined-version"
    "-Wl,-z,defs"
    "-Wl,--as-needed"
    "-Wl,--gc-sections"
  )
endif()

if (RM_CONSTRUCT AND UNIX AND NOT APPLE AND CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  target_link_options(libmemalloc_shared PRIVATE -nostartfiles)
endif()

target_link_libraries(libmemalloc_shared
  PUBLIC Threads::Threads
)

# ------------------------------------------------------------------------------
# 7. Namespaced ALIAS targets
# ------------------------------------------------------------------------------
add_library(memalloc::static  ALIAS libmemalloc_static)
add_library(memalloc::shared  ALIAS libmemalloc_shared)

# ------------------------------------------------------------------------------
# 8. Install & Export (official only)
# ------------------------------------------------------------------------------
install(TARGETS libmemalloc_static libmemalloc_shared
  EXPORT memallocTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

install(EXPORT memallocTargets
  NAMESPACE memalloc::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/memalloc
)

# ------------------------------------------------------------------------------
# 9. Test-only shared library
# ------------------------------------------------------------------------------

# Build a separate shared library just for tests, without altering official libs.
# Can be instrumented independently (e.g. for coverage).

if(MEMALLOC_BUILD_TEST_SHARED)
  add_library(libmemalloc_obj_test OBJECT ${LIBMEMALLOC_SOURCES})
  target_include_directories(libmemalloc_obj_test PRIVATE ${CMAKE_SOURCE_DIR}/inc)
  set_target_properties(libmemalloc_obj_test PROPERTIES
    POSITION_INDEPENDENT_CODE ON
    C_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
  )

  if(MEMALLOC_INSTRUMENT_TEST_SHARED)
    target_compile_options(libmemalloc_obj_test PRIVATE -O0 -g --coverage)
    target_compile_definitions(libmemalloc_obj_test PRIVATE LOG_LEVEL=LOG_LEVEL_DEBUG)
  endif()

  add_library(libmemalloc_shared_test SHARED
    $<TARGET_OBJECTS:libmemalloc_obj_test>
  )
  add_library(memalloc::test ALIAS libmemalloc_shared_test)

  target_link_libraries(libmemalloc_shared_test PUBLIC Threads::Threads)

  if(MEMALLOC_INSTRUMENT_TEST_SHARED)
    target_link_options(libmemalloc_shared_test PRIVATE --coverage)
  endif()

  set_target_properties(libmemalloc_shared_test PROPERTIES
    OUTPUT_NAME memalloc_cov
    INTERPROCEDURAL_OPTIMIZATION FALSE
  )

  # 9.1. Put outputs in a dedicated folder under ${MEMALLOC_OUTPUT_DIR}/test
  set(_test_out "${MEMALLOC_OUTPUT_DIR}/test")
  set_target_properties(libmemalloc_shared_test PROPERTIES
    ARCHIVE_OUTPUT_DIRECTORY "${_test_out}"
    LIBRARY_OUTPUT_DIRECTORY "${_test_out}"
    RUNTIME_OUTPUT_DIRECTORY "${_test_out}"
  )
  foreach(cfg Debug Release RelWithDebInfo MinSizeRel)
    string(TOUPPER "${cfg}" CFGU)
    set_target_properties(libmemalloc_shared_test PROPERTIES
      "ARCHIVE_OUTPUT_DIRECTORY_${CFGU}" "${_test_out}/${cfg}"
      "LIBRARY_OUTPUT_DIRECTORY_${CFGU}" "${_test_out}/${cfg}"
      "RUNTIME_OUTPUT_DIRECTORY_${CFGU}" "${_test_out}/${cfg}"
    )
  endforeach()

  # 9.2. Never install/export the test-only lib
  set_target_properties(libmemalloc_shared_test PROPERTIES
    EXCLUDE_FROM_ALL FALSE
    EXCLUDE_FROM_DEFAULT_BUILD FALSE
  )
endif()
