# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/metadata.cmake
# Purpose:
#   Attach readable, path-mapped compilation evidence to each built library.
# Notes:
#   Ninja/Makefiles provide the raw database. Other generators fail when requested.
# -----------------------------------------------------------------------------
option(LMA_BUILD_METADATA "Generate and install compilation metadata" ON)
set(LMA_METADATA_INSTALL_DIR
    "${CMAKE_INSTALL_DATADIR}/libmemalloc/metadata"
    CACHE STRING "Installation directory for compilation evidence")
if(LMA_BUILD_METADATA)
  get_property(_lma_multi_config GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
  if(NOT CMAKE_GENERATOR MATCHES "Ninja|Makefiles")
    message(FATAL_ERROR "Compilation metadata requires Ninja or Makefiles. "
                        "Other generators require -DLMA_BUILD_METADATA=OFF.")
  endif()
  add_custom_target(
    build-metadata ALL
    COMMAND
      "${CMAKE_COMMAND}" "-DSOURCE_ROOT=${PROJECT_SOURCE_DIR}" "-DBUILD_ROOT=${PROJECT_BINARY_DIR}"
      "-DCOMPILE_DATABASE=${CMAKE_BINARY_DIR}/compile_commands.json" "-DCONFIGURATION=$<CONFIG>"
      "-DMULTI_CONFIG=${_lma_multi_config}" "-DBINARY=$<TARGET_FILE:memalloc>" -P
      "${CMAKE_CURRENT_LIST_DIR}/write-metadata.cmake"
    DEPENDS memalloc
    COMMENT "Record readable compilation commands and binary identity"
    VERBATIM)
  install(DIRECTORY "${PROJECT_BINARY_DIR}/metadata/$<CONFIG>/"
          DESTINATION "${LMA_METADATA_INSTALL_DIR}")
endif()

# EOF

