cmake_minimum_required(VERSION 3.10)
project(libmemalloc C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(
    -Wall
    -Werror
    -Wextra
    -Wpedantic
    -Wshadow
    -Wconversion
    -Wstrict-prototypes
    -Wformat=2
    -Wunreachable-code
    -Wunused-parameter
    -fstrict-aliasing
    -fwrapv
    -fno-common
    -Wno-unused-function
)

if(CMAKE_BUILD_TYPE STREQUAL "Debug")

    add_compile_options(
        -O0
        -g
        -D_DEBUG_=1
    )

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -flto")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -flto")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")

    add_compile_options(
        -Ofast
        -Os
        -flto
        -ffast-math
        -fomit-frame-pointer
        -funroll-loops
        -fno-exceptions
        -fno-unwind-tables
        -fno-stack-protector
        -fvisibility=hidden
        -fdata-sections
        -ffunction-sections
    )

    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -flto")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -flto")
endif()

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bin")

include_directories(${PROJECT_SOURCE_DIR}/inc)

add_library(libmemalloc_objects OBJECT
    ${PROJECT_SOURCE_DIR}/src/libmemalloc.c
)

add_custom_target(copy_object ALL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_OBJECTS:libmemalloc_objects>
        ${CMAKE_CURRENT_SOURCE_DIR}/bin/libmemalloc.o
    DEPENDS libmemalloc_objects
)

add_library(libmemalloc_static STATIC
    $<TARGET_OBJECTS:libmemalloc_objects>
)
set_target_properties(libmemalloc_static PROPERTIES OUTPUT_NAME "memalloc")

add_library(libmemalloc_shared SHARED
    $<TARGET_OBJECTS:libmemalloc_objects>
)
set_target_properties(libmemalloc_shared PROPERTIES OUTPUT_NAME "memalloc")
