# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/toolchains/linux-cross.cmake
# Purpose:
#   Configure an explicit Linux cross compiler, sysroot and emulator.
# Notes:
#   Target declarations are inputs; they do not establish runtime qualification.
# -----------------------------------------------------------------------------

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR "${LMA_TARGET_PROCESSOR}")
set(CMAKE_CROSSCOMPILING_EMULATOR "${LMA_EMULATOR}")
set(CMAKE_FIND_ROOT_PATH "${LMA_SYSROOT}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES LMA_TARGET_PROCESSOR LMA_EMULATOR LMA_SYSROOT)

# EOF

