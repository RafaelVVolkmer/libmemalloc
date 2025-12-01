# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
# File: tests/CMakeLists.txt   (or cmake/memalloc-tests.cmake)
# Purpose:
#   Build and register unit tests for libmemalloc, with optional sanitizers,
#   wrappers (Valgrind/GDB) and coverage reports (gcovr).
#
# Requirements:
#   - CMake >= 3.18
#   - CTest enabled at the top-level (include(CTest) / enable_testing())
#   - Valgrind (optional), GDB (optional)
#   - gcovr (optional; required when ENABLE_COVERAGE=ON)
#   - llvm-cov (optional; used as gcov for Clang)
#
# Inputs (cache options):
#   ENABLE_SANITIZERS           : BOOL  Build tests with ASan/UBSan (default: OFF)
#   RUN_TESTS_UNDER_VALGRIND    : BOOL  Wrap tests with valgrind via ctest (default: ON)
#   RUN_TESTS_UNDER_GDB         : BOOL  Wrap tests with GDB via ctest (default: OFF)
#   ENABLE_COVERAGE             : BOOL  Enable coverage flags + gcovr report (default: ON)
#   MEMALLOC_KEEP_TEST_ARTIFACTS: BOOL  Keep test-only lib after coverage (default: OFF)
#
# Conventions:
#   - If the test-only shared lib memalloc::test exists, only it is instrumented.
#     Otherwise we fall back to instrumenting the official libs.
#   - Coverage output is written to ${SITE_DIR}/coverage by default.
# ------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.18)

# ------------------------------------------------------------------------------
# 1. Honor BUILD_TESTING early
# ------------------------------------------------------------------------------
if(NOT BUILD_TESTING)
  return()
endif()

# ------------------------------------------------------------------------------
# 2. Options (cache)
# ------------------------------------------------------------------------------
option(ENABLE_SANITIZERS            "Enable ASan/UBSan for test executables"               OFF)
option(RUN_TESTS_UNDER_VALGRIND     "Wrap tests with Valgrind when running ctest"          ON)
option(RUN_TESTS_UNDER_GDB          "Wrap tests with GDB when running ctest"               OFF)
option(ENABLE_COVERAGE              "Enable coverage (gcovr/lcov)"                         ON)
option(MEMALLOC_KEEP_TEST_ARTIFACTS "Keep test-only lib after tests (skip cleanup step)"   OFF)

set(SITE_DIR "${CMAKE_SOURCE_DIR}/doxygen/doxygen-awesome/html" CACHE PATH
    "Doxygen site output directory (html lives here)")

if(NOT DEFINED MEMALLOC_OUTPUT_DIR)
  set(MEMALLOC_OUTPUT_DIR "${CMAKE_BINARY_DIR}")
endif()

set(MEMALLOC_TEST_LIB memalloc::shared)
if(TARGET memalloc::test)
  set(MEMALLOC_TEST_LIB memalloc::test)
endif()

set(_IS_GNU_OR_CLANG FALSE)
if(CMAKE_C_COMPILER_ID MATCHES "Clang|GNU")
  set(_IS_GNU_OR_CLANG TRUE)
endif()

set(MEMALLOC_TEST_OUTPUT_DIR "${CMAKE_BINARY_DIR}/bin/tests")

# ------------------------------------------------------------------------------
# 3. Tool discovery: Valgrind / GDB
# ------------------------------------------------------------------------------
find_program(VALGRIND_EXECUTABLE valgrind)
if(VALGRIND_EXECUTABLE)
  set(MEMORYCHECK_COMMAND           "${VALGRIND_EXECUTABLE}")
  set(MEMORYCHECK_COMMAND_OPTIONS
			"--leak-check=full"
			"--show-leak-kinds=all"
			"--track-origins=yes"
			"--error-exitcode=1"
			"--exit-on-first-error=no")
endif()

find_program(GDB_EXECUTABLE gdb)

# ------------------------------------------------------------------------------
# 4. Test sources
# ------------------------------------------------------------------------------
file(GLOB_RECURSE TEST_SRCS CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.c")

set_property(GLOBAL PROPERTY ALL_TEST_TARGETS "")

set(_cfg "$<IF:$<BOOL:$<CONFIG>>,$<CONFIG>,.>")

# ------------------------------------------------------------------------------
# 5. Library instrumentation for coverage
# ------------------------------------------------------------------------------
if(ENABLE_COVERAGE AND _IS_GNU_OR_CLANG)
  if(TARGET memalloc::test)
    # The test-only lib should receive --coverage in src/CMakeLists.
    # Nothing to do here.
  else()
    foreach(_lib IN ITEMS libmemalloc_shared libmemalloc_static)
      if(TARGET ${_lib})
        target_compile_options(${_lib} PRIVATE -O0 -g --coverage)
        target_link_options   (${_lib} PRIVATE --coverage)
        set_target_properties(${_lib} PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE)
      endif()
    endforeach()
  endif()
endif()

# ------------------------------------------------------------------------------
# 6. Helper: add and register a single test executable
# ------------------------------------------------------------------------------
function(add_memalloc_test src)
  get_filename_component(test_name "${src}" NAME_WE)

  add_executable("${test_name}" "${src}")
  set_target_properties("${test_name}" PROPERTIES
      RUNTIME_OUTPUT_DIRECTORY                "${MEMALLOC_TEST_OUTPUT_DIR}"
			RUNTIME_OUTPUT_DIRECTORY_DEBUG          "${MEMALLOC_TEST_OUTPUT_DIR}/Debug"
			RUNTIME_OUTPUT_DIRECTORY_RELEASE        "${MEMALLOC_TEST_OUTPUT_DIR}/Release"
			RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${MEMALLOC_TEST_OUTPUT_DIR}/RelWithDebInfo"
			RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL     "${MEMALLOC_TEST_OUTPUT_DIR}/MinSizeeRel"
  )

  target_include_directories("${test_name}" PRIVATE "${CMAKE_SOURCE_DIR}/inc")
  target_link_libraries     ("${test_name}" PRIVATE ${MEMALLOC_TEST_LIB})
  target_compile_definitions("${test_name}" PRIVATE LOG_LEVEL=LOG_LEVEL_DEBUG)

  # 6.1 Sanitizers (disable if running under Valgrind, and only with GCC/Clang)
  if(ENABLE_SANITIZERS AND _IS_GNU_OR_CLANG
     AND NOT (RUN_TESTS_UNDER_VALGRIND AND VALGRIND_EXECUTABLE))
    target_compile_options("${test_name}" PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer -g)
    target_link_options   ("${test_name}" PRIVATE -fsanitize=address,undefined)
  endif()

  # 6.2 Coverage flags for test executables (GCC/Clang only)
  if(ENABLE_COVERAGE AND _IS_GNU_OR_CLANG)
    target_compile_options("${test_name}" PRIVATE -O0 -g --coverage)
    target_link_options   ("${test_name}" PRIVATE --coverage)
  endif()

  # 6.3 Choose wrapper: GDB or Valgrind (but not when collecting coverage)
    if(RUN_TESTS_UNDER_GDB AND GDB_EXECUTABLE)
      set(_USE_GDB ON)
    elseif(RUN_TESTS_UNDER_VALGRIND AND VALGRIND_EXECUTABLE)
      set(_USE_VALGRIND ON)
    endif()

  if(_USE_GDB)
    set(gdb_log "${test_name}.gdb.log")
    add_test(NAME "${test_name}"
      COMMAND ${GDB_EXECUTABLE} -q --batch --return-child-result
              -ex "set confirm off"
              -ex "set pagination off"
              -ex "set follow-fork-mode child"
              -ex "handle SIGPIPE pass nostop noprint"
              -ex "set logging file ${gdb_log}"
              -ex "set logging on"
              -ex "run"
              -ex "bt full"
              -ex "thread apply all bt full"
              -ex "set logging enabled off"
              -ex "quit"
              --args $<TARGET_FILE:${test_name}>
    )
  elseif(_USE_VALGRIND)
    set(valgrind_log "${test_name}.valgrind.log")
    add_test(NAME "${test_name}"
      COMMAND ${VALGRIND_EXECUTABLE}
              --leak-check=full --show-leak-kinds=all --track-origins=yes
              --error-exitcode=1 --exit-on-first-error=no --trace-children=yes
              --log-file=${valgrind_log}
              $<TARGET_FILE:${test_name}>
    )
  else()
    add_test(NAME "${test_name}" COMMAND $<TARGET_FILE:${test_name}>)
  endif()

  set_tests_properties("${test_name}" PROPERTIES
    ENVIRONMENT      "TZ=UTC"
    TIMEOUT          60
    PROCESSORS       1
    RUN_SERIAL       TRUE
    WORKING_DIRECTORY "$<TARGET_FILE_DIR:${test_name}>"
    LABELS           "unit"
  )

	if(_USE_VALGRIND)
		set_tests_properties("${test_name}" PROPERTIES TIMEOUT 300)
	endif()

  set_property(GLOBAL APPEND PROPERTY ALL_TEST_TARGETS "${test_name}")
endfunction()

# ------------------------------------------------------------------------------
# 7. Instantiate one test per source file
# ------------------------------------------------------------------------------
foreach(src IN LISTS TEST_SRCS)
  add_memalloc_test("${src}")
endforeach()

# ------------------------------------------------------------------------------
# 8. Coverage report (gcovr)
# ------------------------------------------------------------------------------
if(ENABLE_COVERAGE)
  find_program(GCOVR_EXECUTABLE gcovr)
  if(GCOVR_EXECUTABLE)
    set(COVERAGE_OUT_DIR "${SITE_DIR}/coverage" CACHE PATH "Where to write coverage reports")

    # 8.1For Clang, try to use llvm-cov as gcov tool
    set(_GCOV_EXEC "")
    if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
      find_program(LLVM_COV_EXECUTABLE llvm-cov)
      if(LLVM_COV_EXECUTABLE)
        set(_GCOV_EXEC "${LLVM_COV_EXECUTABLE} gcov")
      endif()
    endif()

    # 8.2 A small CMake script executes gcovr twice (XML + HTML) and normalizes the XML.
    set(_RUN_GCOVR "${CMAKE_BINARY_DIR}/run_gcovr.cmake")
    file(WRITE "${_RUN_GCOVR}" "
      file(MAKE_DIRECTORY \"${COVERAGE_OUT_DIR}\")
      set(_extra \"\")
      if(NOT \"${_GCOV_EXEC}\" STREQUAL \"\")
        set(_extra --gcov-executable \"${_GCOV_EXEC}\")
      endif()
      execute_process(COMMAND \"${GCOVR_EXECUTABLE}\" \${_extra}
        --object-directory \"${CMAKE_BINARY_DIR}\"
        --object-directory \"${MEMALLOC_OUTPUT_DIR}\"
        -r \"${CMAKE_SOURCE_DIR}\"
        --xml -o \"${COVERAGE_OUT_DIR}/coverage.xml\"
        RESULT_VARIABLE r1)
      if(NOT r1 EQUAL 0)
        message(FATAL_ERROR \"gcovr xml failed: \${r1}\")
      endif()
      file(READ \"${COVERAGE_OUT_DIR}/coverage.xml\" _c)
      string(REGEX REPLACE \"<!DOCTYPE[^>]*>\\n?\" \"\" _c \"\${_c}\")
      file(WRITE \"${COVERAGE_OUT_DIR}/coverage.xml\" \"\${_c}\")
      execute_process(COMMAND \"${GCOVR_EXECUTABLE}\" \${_extra}
        --object-directory \"${CMAKE_BINARY_DIR}\"
        --object-directory \"${MEMALLOC_OUTPUT_DIR}\"
        -r \"${CMAKE_SOURCE_DIR}\"
        --html --html-details -o \"${COVERAGE_OUT_DIR}/index.html\"
        RESULT_VARIABLE r2)
      if(NOT r2 EQUAL 0)
        message(FATAL_ERROR \"gcovr html failed: \${r2}\")
      endif()
    ")

    # 8.3 Create a synthetic test that runs gcovr after all unit tests
    get_property(ALL_TEST_TARGETS GLOBAL PROPERTY ALL_TEST_TARGETS)
    add_test(NAME __coverage_generate
      COMMAND ${CMAKE_COMMAND} -P "${_RUN_GCOVR}"
    )
    set_tests_properties(__coverage_generate PROPERTIES
      DEPENDS     "${ALL_TEST_TARGETS}"
      RUN_SERIAL  TRUE
      LABELS      "coverage"
      TIMEOUT     120
    )
  endif()
endif()

# ------------------------------------------------------------------------------
# 9. Cleanup of the test-only .so (optional)
# ------------------------------------------------------------------------------
if(TARGET libmemalloc_shared_test AND NOT MEMALLOC_KEEP_TEST_ARTIFACTS)
  set(_COVLIB_DIR "${MEMALLOC_OUTPUT_DIR}/test")
  add_test(NAME __cleanup_covlib
    COMMAND ${CMAKE_COMMAND} -E rm -rf "${_COVLIB_DIR}"
  )
  set_tests_properties(__cleanup_covlib PROPERTIES
    DEPENDS     __coverage_generate
    RUN_SERIAL  TRUE
    LABELS      "coverage"
  )
endif()
