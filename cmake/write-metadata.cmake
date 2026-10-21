# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/write-metadata.cmake
# Purpose:
#   Normalize checkout roots and bind compilation metadata to the built binary.
# Notes:
#   Virtual roots preserve reproducibility; the raw replayable database stays local.
# -----------------------------------------------------------------------------
file(READ "${COMPILE_DATABASE}" _input)
# The compilation database belongs to the outer build. Retain only this project's entries.
string(JSON _count LENGTH "${_input}")
set(_database "[]")
set(_kept 0)
if(_count GREATER 0)
  math(EXPR _last "${_count} - 1")
  foreach(index RANGE 0 ${_last} 1)
    string(JSON _entry GET "${_input}" ${index})
    string(JSON _directory GET "${_entry}" directory)
    string(JSON _output GET "${_entry}" output)
    cmake_path(ABSOLUTE_PATH _output BASE_DIRECTORY "${_directory}" NORMALIZE)
    cmake_path(IS_PREFIX BUILD_ROOT "${_output}" NORMALIZE _owned)
    if(_owned AND MULTI_CONFIG)
      if(NOT _output MATCHES "/CMakeFiles/[^/]+[.]dir/([^/]+)/")
        message(FATAL_ERROR "Cannot identify compilation configuration: ${_output}")
      endif()
      if(NOT CMAKE_MATCH_1 STREQUAL CONFIGURATION)
        set(_owned FALSE)
      endif()
    endif()
    if(_owned)
      string(JSON _database SET "${_database}" ${_kept} "${_entry}")
      math(EXPR _kept "${_kept} + 1")
    endif()
  endforeach()
endif()
if(_kept EQUAL 0)
  message(FATAL_ERROR "No compilation commands found for ${CONFIGURATION}")
endif()
# Replace the longer build root first, since build trees commonly live in source.
string(REPLACE "${BUILD_ROOT}" "/libmemalloc/build" _database "${_database}")
get_filename_component(_outer_build "${COMPILE_DATABASE}" DIRECTORY)
string(REPLACE "${_outer_build}" "/libmemalloc/outer-build" _database "${_database}")
string(REPLACE "${SOURCE_ROOT}" "/libmemalloc/source" _database "${_database}")
string(JSON _database GET "${_database}")
set(_destination "${BUILD_ROOT}/metadata/${CONFIGURATION}")
file(MAKE_DIRECTORY "${_destination}")
file(WRITE "${_destination}/compile_commands.json" "${_database}\n")
file(SHA256 "${BINARY}" _binary_hash)
file(SHA256 "${_destination}/compile_commands.json" _database_hash)
get_filename_component(_binary_name "${BINARY}" NAME)
file(
  WRITE "${_destination}/build.json"
  "{\n  \"schema\": 1,\n  \"binary\": \"${_binary_name}\",\n"
  "  \"binary_sha256\": \"${_binary_hash}\",\n"
  "  \"compile_commands_sha256\": \"${_database_hash}\",\n"
  "  \"configuration\": \"${CONFIGURATION}\",\n"
  "  \"source_root\": \"/libmemalloc/source\",\n"
  "  \"build_root\": \"/libmemalloc/build\"\n}\n")

# EOF

