# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/toolchains/zig.cmake
# Purpose:
#   Adapt the reviewed Zig target and compiler driver to CMake.
# Notes:
#   Target declarations are inputs; they do not establish runtime qualification.
# -----------------------------------------------------------------------------

# Zig 0.14.1 rejects the linker's dependency-file flag emitted by newer CMake.
# Keep CMake's target dependency graph and the compiler-generated depfiles.
set(CMAKE_LINK_DEPENDS_USE_LINKER FALSE)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER "zig;cc;-target;x86_64-linux-musl")
set(CMAKE_CXX_COMPILER "zig;c++;-target;x86_64-linux-musl")
set(CMAKE_AR zig)
set(CMAKE_C_ARCHIVE_CREATE "<CMAKE_AR> ar qc <TARGET> <LINK_FLAGS> <OBJECTS>")
set(CMAKE_C_ARCHIVE_FINISH "")

# EOF

