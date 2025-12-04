# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
# File: doxygen/CMakeLists.txt (cmake/docs.cmake)
# Purpose: Generate Doxygen site styled with doxygen-awesome and optionally
#          inject a "Tests Coverage" link/pill into the pages.
#
# Requirements:
#   - CMake >= 3.20 (FetchContent); prefer 3.24+ for CMP0135
#   - Doxygen available in PATH
#   - Optional: gcovr (and llvm-cov for Clang) when GCOVR_DOCS is ON
#
# Inputs (cache options / variables):
#   GCOVR_DOCS           : BOOL  Enable coverage link injection (default: OFF)
#   DOXYGEN_OUTPUT_DIR   : PATH  Override Doxygen OUTPUT_DIRECTORY (optional)
#   DOXYGEN_THEME_DIR    : PATH  Where to place the doxygen-awesome site root.
#                               Default: ${CMAKE_SOURCE_DIR}/doxygen/doxygen-awesome
#   COVERAGE_LINK_DIR    : PATH  Folder with footer.html.in / JS / CSS assets
#                               Default: ${CMAKE_SOURCE_DIR}/doxygen/coverage_link
#   COVERAGE_URL         : STR   Target URL opened by the coverage button
#                               Default: coverage/index.html
#
# Outputs / Targets:
#   doc                  : Runs Doxygen with the theme (and coverage pill if enabled).
#
# Generated files (in ${CMAKE_BINARY_DIR}):
#   - Doxyfile
#   - doxy_footer.html           (when GCOVR_DOCS=ON)
#   - coverage-link.js           (when GCOVR_DOCS=ON)
#   - coverage-pill.css          (when GCOVR_DOCS=ON)
#
# Website output (by default):
#   ${CMAKE_SOURCE_DIR}/doxygen/doxygen-awesome
#   └── html/
#       └── (full doxygen site; may include coverage/index.html you generate)
#
# Usage:
#   - include(cmake/docs.cmake)
#   - cmake --build <build_dir> --target doc
#
# Maintainers:
#   - Rafael V. Volkmer (rafael.v.volkmer@gmail.com)
# ------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.24)

# ------------------------------------------------------------------------------
# 1. Discover Doxygen early
# ------------------------------------------------------------------------------
find_package(Doxygen QUIET)
if(NOT DOXYGEN_FOUND)
  message(STATUS "Doxygen not found! 'doc' target will be skipped.")
  return()
endif()

# ------------------------------------------------------------------------------
# 2. Policy for FetchContent
# ------------------------------------------------------------------------------
if(POLICY CMP0135)
  cmake_policy(SET CMP0135 NEW)
endif()

# ------------------------------------------------------------------------------
# 3. Initial Settings
# ------------------------------------------------------------------------------
set(doxygen_theme_repo_url
    "https://github.com/jothepro/doxygen-awesome-css/archive/refs/heads/main.zip")

set(doxygen_site_dir
    "${CMAKE_SOURCE_DIR}/doxygen/doxygen-awesome")

set(coverage_link_dir
    "${CMAKE_SOURCE_DIR}/doxygen/coverage_link")

set(coverage_url
    "coverage/index.html")

include(FetchContent)

# ------------------------------------------------------------------------------
# 4. Fetch Doxygen-Awesome Theme
# ------------------------------------------------------------------------------
if(NOT TARGET doxygen-awesome-css)
  FetchContent_Declare(
    doxygen-awesome-css
    URL                        "${doxygen_theme_repo_url}"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SOURCE_DIR                 "${doxygen_site_dir}"
  )
  FetchContent_MakeAvailable(doxygen-awesome-css)
endif()

# ------------------------------------------------------------------------------
# 5. Generate the Effective Doxyfile From the Template .in
# ------------------------------------------------------------------------------
set(doxyfile_in  "${CMAKE_SOURCE_DIR}/doxygen/Doxyfile.in")
set(doxyfile_out "${CMAKE_BINARY_DIR}/Doxyfile")

configure_file("${doxyfile_in}" "${doxyfile_out}" @ONLY)

file(APPEND "${doxyfile_out}" "\n# ---- injected by CMake (site dir) ----\n")
file(APPEND "${doxyfile_out}" "OUTPUT_DIRECTORY = \"${doxygen_site_dir}\"\n")

# ------------------------------------------------------------------------------
# 6.  Inject Coverage Link Assets Into the Final Site
# ------------------------------------------------------------------------------
if(GCOVR_DOCS)
  # 6.1. Produce the footer and JS from templates; copy the CSS
  configure_file("${coverage_link_dir}/footer.html"
                 "${CMAKE_BINARY_DIR}/doxy_footer.html" @ONLY)
  configure_file("${coverage_link_dir}/coverage-link.js"
                 "${CMAKE_BINARY_DIR}/coverage-link.js" @ONLY)
  file(COPY "${coverage_link_dir}/coverage-pill.css"
       DESTINATION "${CMAKE_BINARY_DIR}")

  # 6.2. Append minimal overrides to the generated Doxyfile
  file(APPEND "${doxyfile_out}" "\n# ---- injected by CMake (coverage link) ----\n")
  file(APPEND "${doxyfile_out}" "OUTPUT_DIRECTORY = \"${doxygen_site_dir}\"\n")
  file(APPEND "${doxyfile_out}" "HTML_FOOTER = \"${CMAKE_BINARY_DIR}/doxy_footer.html\"\n")
  file(APPEND "${doxyfile_out}" "HTML_EXTRA_FILES += \"${CMAKE_BINARY_DIR}/coverage-link.js\"\n")
  file(APPEND "${doxyfile_out}" "HTML_EXTRA_STYLESHEET += \"${CMAKE_BINARY_DIR}/coverage-pill.css\"\n")
endif()

# ------------------------------------------------------------------------------
# 7.  Add a Dedicated 'doc' Target that Runs Doxygen
# ------------------------------------------------------------------------------
add_custom_target(doc
  COMMAND "${DOXYGEN_EXECUTABLE}" "${doxyfile_out}"
  WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
  COMMENT "Generating Doxygen docs with doxygen-awesome (and coverage link if enabled)"
  VERBATIM
)
