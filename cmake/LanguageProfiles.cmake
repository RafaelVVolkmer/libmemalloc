# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/LanguageProfiles.cmake
# Purpose:
#   Build the existing language/ABI interoperability campaign.
# Notes:
#   Target declarations are inputs; they do not establish runtime qualification.
# -----------------------------------------------------------------------------

enable_testing()

if(LMA_CORE_FLAGS)
  target_compile_options(memalloc PRIVATE ${LMA_CORE_FLAGS})
endif()

if(DEFINED LMA_FLAG_PROBE)
  include(CheckCCompilerFlag)
  if(MSVC)
    set(CMAKE_REQUIRED_FLAGS /WX)
  else()
    set(CMAKE_REQUIRED_FLAGS "-Werror -pedantic-errors")
  endif()
  check_c_compiler_flag("${LMA_FLAG_PROBE}" LMA_FLAGS_SUPPORTED)
  unset(CMAKE_REQUIRED_FLAGS)
  if(NOT LMA_FLAGS_SUPPORTED)
    message(FATAL_ERROR "LMA_UNSUPPORTED_PROFILE: ${LMA_FLAG_PROBE}")
  endif()

endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set_target_properties(memalloc PROPERTIES ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
if(MSVC)
  add_compile_options(/W4 /WX /Zc:__cplusplus)
  set_property(TARGET memalloc PROPERTY MSVC_RUNTIME_LIBRARY
                                        "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
else()
  add_compile_options(-Wall -Wextra -Werror -pedantic-errors)
endif()

foreach(key IN ITEMS LMA_C_VERSION LMA_POINTER_BYTES LMA_LONG_BYTES LMA_BIG_ENDIAN LMA_ARCH LMA_OS)
  if(NOT DEFINED ${key})
    message(FATAL_ERROR "Missing profile property: ${key}")
  endif()

endforeach()

configure_file(tests/fixtures/compatibility/c/api.c.in "${CMAKE_BINARY_DIR}/api.c" COPYONLY)
configure_file(tests/fixtures/compatibility/c/target.c.in "${CMAKE_BINARY_DIR}/target.c" COPYONLY)
configure_file(tests/fixtures/compatibility/cpp/consumer.cpp.in "${CMAKE_BINARY_DIR}/consumer.cpp"
               COPYONLY)
add_executable(c-api "${CMAKE_BINARY_DIR}/api.c")
target_link_libraries(c-api PRIVATE LMA::memalloc)
target_compile_definitions(c-api PRIVATE LMA_EXPECT_C=${LMA_C_VERSION})
add_executable(target-model "${CMAKE_BINARY_DIR}/target.c")
target_compile_definitions(
  target-model PRIVATE LMA_POINTER_BYTES=${LMA_POINTER_BYTES} LMA_LONG_BYTES=${LMA_LONG_BYTES}
                       LMA_BIG_ENDIAN=${LMA_BIG_ENDIAN} LMA_ARCH_${LMA_ARCH}=1 LMA_OS_${LMA_OS}=1)
add_test(NAME c-api COMMAND c-api)
add_test(NAME target-model COMMAND target-model)
set(_test_targets c-api target-model)

# Probe each requested mode independently. Missing optional dialects remain
# explicit evidence; failures in modes promised by the profile stop the build.
file(WRITE "${CMAKE_BINARY_DIR}/unsupported-cpp.txt" "")
if(LMA_CPP_STANDARDS)
  # These consumers use headers, not C++ modules. SDK compiler drivers such as
  # Zig do not ship clang-scan-deps; neither probes nor targets need that tool.
  set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
  enable_language(CXX)
  include(CheckCXXSourceCompiles)
  include("${CMAKE_CURRENT_LIST_DIR}/LanguageDialects.cmake")

  set(_saved_cpp_standard "${CMAKE_CXX_STANDARD}")
  foreach(dialect IN LISTS LMA_CPP_STANDARDS)
    # CMake represents C++98/03 with the same standard property. Explicit
    # properties prevent CMP0128 from appending the compiler default dialect.
    set(_cmake_dialect "${dialect}")
    if(dialect STREQUAL "03")
      set(_cmake_dialect 98)
    endif()
    set(CMAKE_CXX_STANDARD "${_cmake_dialect}")
    set(_expected "${LMA_CPP_VERSION_${dialect}}")
    set(_dialect_flag "${LMA_CPP_FLAG_${dialect}}")
    if(MSVC)
      set(_dialect_flag "/std:c++${dialect}")
      if(dialect STREQUAL "23")
        set(_dialect_flag /std:c++23preview)
      elseif(dialect STREQUAL "26")
        set(_dialect_flag /std:c++latest)
      endif()
      set(CMAKE_REQUIRED_FLAGS "${_dialect_flag} /WX /Zc:__cplusplus")
    else()
      set(CMAKE_REQUIRED_FLAGS "${_dialect_flag} -Werror -pedantic-errors")
    endif()

    if(DEFINED CMAKE_CXX${_cmake_dialect}_STANDARD_COMPILE_OPTION)
      check_cxx_source_compiles(
        "
      #if __cplusplus != ${_expected}L
      #error Requested language version was not selected
      #endif
      int main() { return 0; }
    "
        LMA_CPP_${dialect}_SUPPORTED)
    else()
      set(LMA_CPP_${dialect}_SUPPORTED FALSE)
    endif()
    unset(CMAKE_REQUIRED_FLAGS)

    if(NOT LMA_CPP_${dialect}_SUPPORTED)
      if(dialect IN_LIST LMA_CPP_REQUIRED)
        message(FATAL_ERROR "Required C++${dialect} mode is unavailable")
      endif()
      file(APPEND "${CMAKE_BINARY_DIR}/unsupported-cpp.txt" "${dialect}\n")
      message(STATUS "UNSUPPORTED: C++${dialect}; see compiler probe evidence")
      continue()
    endif()

    set(_target "cpp-${dialect}")
    add_executable(${_target} "${CMAKE_BINARY_DIR}/consumer.cpp")
    target_link_libraries(${_target} PRIVATE LMA::memalloc)
    set_target_properties(
      ${_target}
      PROPERTIES CXX_STANDARD "${_cmake_dialect}"
                 CXX_STANDARD_REQUIRED ON
                 CXX_EXTENSIONS OFF)
    target_compile_definitions(${_target} PRIVATE LMA_EXPECT_CPP=${_expected})
    add_test(NAME ${_target} COMMAND ${_target})
    list(APPEND _test_targets ${_target})
  endforeach()
  if(_saved_cpp_standard)
    set(CMAKE_CXX_STANDARD "${_saved_cpp_standard}")
  else()
    unset(CMAKE_CXX_STANDARD)
  endif()
endif()

set_tests_properties(${_test_targets} PROPERTIES TIMEOUT 30)
set(_artifacts "$<TARGET_FILE:memalloc>\n")
foreach(artifact_target IN LISTS _test_targets)
  string(APPEND _artifacts "$<TARGET_FILE:${artifact_target}>\n")
endforeach()

file(
  GENERATE
  OUTPUT "${CMAKE_BINARY_DIR}/artifacts.txt"
  CONTENT "${_artifacts}")
file(
  WRITE "${CMAKE_BINARY_DIR}/compiler.txt"
  "${CMAKE_C_COMPILER_ID}\n${CMAKE_C_COMPILER_VERSION}\n"
  "${CMAKE_C_COMPILER}\n${CMAKE_CXX_COMPILER}\n"
  "${CMAKE_SYSTEM_NAME}\n${CMAKE_SYSTEM_PROCESSOR}\n${CMAKE_SYSROOT}\n")

# EOF

