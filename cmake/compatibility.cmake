# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/compatibility.cmake
# Purpose:
#   Compile explicit foreign-language consumers of the C ABI.
# Notes:
#   Requested tools are required. Cross compilation does not imply execution.
# -----------------------------------------------------------------------------
set(LMA_COMPATIBILITY_LANGUAGES
    ""
    CACHE STRING "Consumers: c;cpp;rust;zig;c3;wasm;baremetal")
if(LMA_COMPATIBILITY_LANGUAGES)
  enable_testing()
endif()
foreach(language IN LISTS LMA_COMPATIBILITY_LANGUAGES)
  set(_directory "${PROJECT_BINARY_DIR}/compatibility/${language}")
  file(MAKE_DIRECTORY "${_directory}")
  if(language STREQUAL "c" OR language STREQUAL "cpp")
    if(language STREQUAL "cpp")
      enable_language(CXX)
    endif()
    if(language STREQUAL "cpp")
      set(_template "tests/fixtures/compatibility/cpp/consumer.cpp.in")
    else()
      set(_template "tests/fixtures/compatibility/ffi/consumer.c.in")
    endif()
    configure_file("${_template}" "${_directory}/consumer.${language}" COPYONLY)
    add_executable(compat-${language} "${_directory}/consumer.${language}")
    target_link_libraries(compat-${language} PRIVATE LMA::memalloc)
    if(NOT CMAKE_CROSSCOMPILING OR CMAKE_CROSSCOMPILING_EMULATOR)
      add_test(NAME compatibility-${language} COMMAND compat-${language})
    endif()
  elseif(language STREQUAL "wasm")
    if(NOT CMAKE_SYSTEM_PROCESSOR STREQUAL "wasm32")
      message(FATAL_ERROR "wasm consumer requires the wasm32 toolchain")
    endif()
    configure_file(tests/fixtures/compatibility/ffi/consumer.wasm.in "${_directory}/consumer.c"
                   COPYONLY)
    add_executable(compat-wasm "${_directory}/consumer.c")
    target_link_libraries(compat-wasm PRIVATE LMA::memalloc)
    set_target_properties(compat-wasm PROPERTIES SUFFIX .wasm)
    find_program(LMA_NODE_EXECUTABLE NAMES node REQUIRED)
    add_test(
      NAME compatibility-wasm
      COMMAND "${LMA_NODE_EXECUTABLE}" "${PROJECT_SOURCE_DIR}/tests/automation/build/wasm_test.cjs"
              "$<TARGET_FILE:compat-wasm>")
  elseif(language STREQUAL "baremetal")
    if(NOT CMAKE_SYSTEM_NAME STREQUAL "Generic")
      message(FATAL_ERROR "baremetal requires an explicit Generic toolchain")
    endif()
    configure_file(tests/fixtures/compatibility/ffi/consumer.baremetal.in
                   "${_directory}/consumer.c" COPYONLY)
    add_library(compat-baremetal OBJECT "${_directory}/consumer.c")
    target_link_libraries(compat-baremetal PRIVATE LMA::memalloc)
    message(STATUS "Bare-metal consumer: compile only; board/startup/linker script remain external")
  elseif(language MATCHES "^(rust|zig|c3)$")
    if(BUILD_SHARED_LIBS OR CMAKE_CROSSCOMPILING)
      message(FATAL_ERROR "Foreign native consumers currently require a native static C library")
    endif()
    if(language STREQUAL "rust")
      find_program(LMA_RUSTC_EXECUTABLE NAMES rustc REQUIRED)
      set(_extension rs)
      set(_command
          "${LMA_RUSTC_EXECUTABLE}" --edition=2024 "${_directory}/consumer.rs" -L
          "native=$<TARGET_FILE_DIR:memalloc>" -l static=memalloc -o "${_directory}/consumer")
    elseif(language STREQUAL "zig")
      find_program(LMA_ZIG_EXECUTABLE NAMES zig REQUIRED)
      set(_extension zig)
      set(_command
          "${LMA_ZIG_EXECUTABLE}" build-exe "${_directory}/consumer.zig" "$<TARGET_FILE:memalloc>"
          --cache-dir "${_directory}/cache" --global-cache-dir "${_directory}/global-cache" -lc
          "-femit-bin=${_directory}/consumer")
    else()
      find_program(LMA_C3_EXECUTABLE NAMES c3c REQUIRED)
      set(_extension c3)
      set(_command "${LMA_C3_EXECUTABLE}" compile "${_directory}/consumer.c3" -L
                   "$<TARGET_FILE_DIR:memalloc>" -l memalloc -o "${_directory}/consumer")
    endif()
    configure_file("tests/fixtures/compatibility/ffi/consumer.${_extension}.in"
                   "${_directory}/consumer.${_extension}" COPYONLY)
    add_custom_command(
      OUTPUT "${_directory}/consumer"
      COMMENT "Compile the ${language} consumer of the C ABI"
      COMMAND ${_command}
      DEPENDS memalloc "${_directory}/consumer.${_extension}"
      VERBATIM)
    add_custom_target(
      compat-${language} ALL
      DEPENDS "${_directory}/consumer"
      COMMENT "Build the ${language} interoperability artifact")
    add_test(NAME compatibility-${language} COMMAND "${_directory}/consumer")
  else()
    message(FATAL_ERROR "Unknown compatibility language: ${language}")
  endif()
endforeach()

# EOF

