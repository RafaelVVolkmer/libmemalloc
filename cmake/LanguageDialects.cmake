# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/LanguageDialects.cmake
# Purpose:
#   Map requested C++ dialects to expected feature macros and flags.
# Notes:
#   Target declarations are inputs; they do not establish runtime qualification.
# -----------------------------------------------------------------------------

# Language selection is checked against the compiler's advertised version.
# C++26 is a development mode, not a claim of complete standard conformance.
set(LMA_CPP_VERSION_98 199711)
set(LMA_CPP_VERSION_03 199711)
set(LMA_CPP_VERSION_11 201103)
set(LMA_CPP_VERSION_14 201402)
set(LMA_CPP_VERSION_17 201703)
set(LMA_CPP_VERSION_20 202002)
set(LMA_CPP_VERSION_23 202302)
set(LMA_CPP_VERSION_26 202400)

foreach(
  dialect IN
  ITEMS 98
        03
        11
        14
        17
        20
        23)
  set(LMA_CPP_FLAG_${dialect} "-std=c++${dialect}")
endforeach()
set(LMA_CPP_FLAG_26 "-std=c++2c")

# EOF

