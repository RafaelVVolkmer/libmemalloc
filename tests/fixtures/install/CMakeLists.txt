# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

cmake_minimum_required(VERSION 3.20)
project(libmemalloc_consumer LANGUAGES C)

find_package(libmemalloc CONFIG REQUIRED)
configure_file(main.c.in main.c COPYONLY)
add_executable(consumer ${CMAKE_CURRENT_BINARY_DIR}/main.c)
target_link_libraries(consumer PRIVATE LMA::memalloc)

# EOF

