# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/targets.cmake
# Purpose:
#   Create the library, apply shared target policy and expose optional smoke tests.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# 1. Library interface and explicitly exported ABI.
# -----------------------------------------------------------------------------
add_library(memalloc core/mock.c)
add_library(LMA::memalloc ALIAS memalloc)
set_target_properties(
  memalloc
  PROPERTIES VERSION ${PROJECT_VERSION}
             SOVERSION 0
             C_VISIBILITY_PRESET hidden)
target_compile_features(memalloc PUBLIC c_std_99)
configure_file(core/mock.h "${PROJECT_BINARY_DIR}/include/libmemalloc/mock.h" COPYONLY)
target_include_directories(
  memalloc
  PUBLIC $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/core>
         $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/include>
         $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
if(BUILD_SHARED_LIBS)
  target_compile_definitions(
    memalloc
    PRIVATE LMA_BUILDING_SHARED
    PUBLIC LMA_SHARED_LIBRARY)
endif()
lma_compiler_flags(memalloc)
lma_linker_flags(memalloc)

# -----------------------------------------------------------------------------
# 2. An owned consumer checks the actual target; no mock-specific analysis waiver.
# -----------------------------------------------------------------------------
if(LMA_BUILD_MOCK_CONSUMER OR LMA_BUILD_TESTS)
  add_executable(memalloc_mock_consumer core/main.c)
  target_link_libraries(memalloc_mock_consumer PRIVATE LMA::memalloc)
  lma_compiler_flags(memalloc_mock_consumer)
  lma_linker_flags(memalloc_mock_consumer)
endif()
if(LMA_BUILD_TESTS)
  enable_testing()
  add_test(NAME build-interface COMMAND memalloc_mock_consumer)
  set_tests_properties(build-interface PROPERTIES TIMEOUT 30)
endif()

# -----------------------------------------------------------------------------
# 3. Documentation and coverage reuse installed tools, without configure downloads.
# -----------------------------------------------------------------------------
if(LMA_BUILD_DOCS)
  find_program(LMA_LUA_EXECUTABLE NAMES lua lua5.5 lua5.4 REQUIRED)
  add_custom_target(
    docs
    COMMENT "Build documentation with the repository Lua/Doxygen driver"
    COMMAND "${LMA_LUA_EXECUTABLE}" scripts/documentation/main.lua build
            "--output=.cache/docs/cmake"
    WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
    VERBATIM)
endif()
if(LMA_ENABLE_COVERAGE AND LMA_BUILD_TESTS)
  find_program(LMA_GCOVR_EXECUTABLE NAMES gcovr)
  if(LMA_GCOVR_EXECUTABLE)
    add_custom_target(
      coverage
      COMMENT "Run tests and collect scoped coverage"
      COMMAND "${CMAKE_CTEST_COMMAND}" --output-on-failure -C "$<CONFIG>"
      COMMAND "${LMA_GCOVR_EXECUTABLE}" --root "${PROJECT_SOURCE_DIR}" --object-directory
              "${PROJECT_BINARY_DIR}" --json "${PROJECT_BINARY_DIR}/coverage.json"
      DEPENDS memalloc_mock_consumer
      WORKING_DIRECTORY "${PROJECT_BINARY_DIR}"
      VERBATIM)
  endif()
endif()

# EOF

