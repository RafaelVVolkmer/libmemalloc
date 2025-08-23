cmake_minimum_required(VERSION 3.15)
project(libmemalloc C)
include(FetchContent)
# enable_language(ASM)

# ----------------------------------------------------------------------------
# 1. Basic Project Settings
# ----------------------------------------------------------------------------
set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the build type (Debug or Release)." FORCE)
endif()

# ----------------------------------------------------------------------------
# 2. Checking dependencies
# ----------------------------------------------------------------------------
set(MIN_GCC_VERSION   "12.2.0")
set(MIN_CLANG_VERSION "11.0")
set(MIN_MSVC_VERSION  "19.20")

if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
  if (CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_GCC_VERSION})
    message(FATAL_ERROR
      "[ERROR]: GCC ${MIN_GCC_VERSION} or newer is required.\n"
      "Detected version: ${CMAKE_C_COMPILER_VERSION}."
    )
  endif()

elseif (CMAKE_C_COMPILER_ID STREQUAL "Clang")
  if (CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_CLANG_VERSION})
    message(FATAL_ERROR
      "[ERROR]: Clang ${MIN_CLANG_VERSION} or newer is required.\n"
      "Detected version: ${CMAKE_C_COMPILER_VERSION}."
    )
  endif()

elseif (CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  if (CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_MSVC_VERSION})
    message(FATAL_ERROR
      "[ERROR]: MSVC ${MIN_MSVC_VERSION} or newer is required.\n"
      "Detected version: ${CMAKE_C_COMPILER_VERSION}."
    )
  endif()

else()
  message(WARNING "[WARNING]: Unrecognized compiler (${CMAKE_C_COMPILER_ID})")
endif()

find_program(VALGRIND_EXECUTABLE NAMES valgrind)
find_package(Doxygen QUIET)

# ----------------------------------------------------------------------------
# 3. Output Directories for Binaries
#    - Archive (static libraries)
#    - Library (shared libraries)
#    - Runtime (executables)
# ----------------------------------------------------------------------------
set(OUTPUT_BIN_DIR "${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE}")
file(MAKE_DIRECTORY "${OUTPUT_BIN_DIR}")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")

# ----------------------------------------------------------------------------
# 4. Build-Type Specific Compiler Flags
# ----------------------------------------------------------------------------
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    add_compile_options(
        # --- Optimization Level ---
        -O0

        # --- Debug Symbols & Frame Pointers ---
        -g3
        -ggdb
        -fno-omit-frame-pointer
        -fvar-tracking-assignments
        -fdebug-prefix-map=${CMAKE_CURRENT_SOURCE_DIR}/src/=src/

        # --- Inlining Control ---
        -fno-inline
        -fno-inline-functions
        -fno-inline-functions-called-once

        # --- Strictness Overrides ---
        -fno-strict-aliasing
        -DDEBUG

        # --- Auxiliary Info ---
        -aux-info filename
    )

    if (CMAKE_C_COMPILER_ID STREQUAL "Clang"
        OR (CMAKE_C_COMPILER_ID STREQUAL "GNU"
            AND CMAKE_C_COMPILER_VERSION VERSION_GREATER_EQUAL "13.0"))
      set(ANALYZER_FLAGS
        -fanalyzer-verbosity=5
        -fanalyzer-fine-grained
        -fanalyzer-call-summaries
        -fanalyzer-transitivity
        -fno-analyzer-state-merge
        -fno-analyzer-state-purge
        -fno-analyzer-suppress-followups
        -fno-analyzer-undo-inlining
        -fdump-analyzer
        -fdump-analyzer-callgraph
        -fdump-analyzer-exploded-graph
        -fdump-analyzer-exploded-paths
        -fdump-analyzer-feasibility
        -fdump-analyzer-json
        -fdump-analyzer-supergraph
        -fdump-analyzer-untracked
        -fdump-analyzer-stderr
      )
      add_compile_options(${ANALYZER_FLAGS})
    endif()

    if (!VALGRIND_EXECUTABLE)
        set(SANITIZE_FLAGS
            -fsanitize=address
            -fsanitize=undefined
            -fsanitize=leak
            -fsanitize=alignment
        )

        add_compile_options(${SANITIZE_FLAGS})
        add_link_options(${SANITIZE_FLAGS})
    endif()



    set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections -flto")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -flto")
  
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(
        # --- NDEBUG & Optimization ---
        -DNDEBUG
        -Ofast
        -Os

        # --- Link Time Optimization ---
        -flto

        # --- Math & Overflow ---
        -ffast-math
        -fstrict-overflow

        # --- Frame Pointer & Inlining ---
        -fomit-frame-pointer
        -funroll-loops

        # --- Constant Merging ---
        -fmerge-all-constants

        # --- Exceptions & Unwind Tables ---
        -fno-exceptions
        -fno-unwind-tables

        # --- Stack & Data Sections ---
        -fno-stack-protector
        -fdata-sections
        -ffunction-sections

        # --- Memory Hardening ---
        -D_FORTIFY_SOURCE=2
        -fstack-clash-protection

        # --- Debug Info Removal ---
        -g0
        -fno-ident
        -fvisibility=hidden

        # --- Common Flags ---
        -fno-common
    )

    set(CMAKE_EXE_LINKER_FLAGS    "${CMAKE_EXE_LINKER_FLAGS}    -Wl,--gc-sections -Wl,-O1 -Wl,-s")
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections -Wl,-O1 -Wl,-s")
endif()

# ----------------------------------------------------------------------------
# 5. Global Warning and Strictness Options
#    (Applied to all build types)
# ----------------------------------------------------------------------------
add_compile_options(
    # --- Hardening / Security ---
    -fstack-protector-strong
    -D_FORTIFY_SOURCE=2
    -fpack-struct=1
    -Wpacked-bitfield-compat
    -Wpacked-not-aligned
    -Waddress-of-packed-member
    -Wpadded
    -Wno-packed-bitfield-compat
    -Wformat-security
    -Werror=format-security

    # --- Disable any Inline asm ---
    -fno-asm

    # --- Link Time Optimization & Linker Flags ---
    -flto
    -fuse-linker-plugin
    -Wl,--as-needed

    # --- ABI, Data Layout & Conventions ---
    -fsso-struct=little-endian
    -fsigned-bitfields
    -fsigned-char
    -fcond-mismatch
    -fno-common
    -fwrapv

    # --- Optimization & Static Analysis ---
    -fstrict-aliasing
    -fanalyzer

    # --- Basic Code Quality Warnings ---
    -Wall
    -Wextra
    -Wpedantic
    -Werror
    -Wshadow
    -Wshadow=global
    -Wshadow=local

    # --- Casting & Type Safety ---
    -Wbad-function-cast
    -Wcast-function-type
    -Wcast-align
    -Wcast-qual

    # --- Numeric Conversions ---
    -Wconversion
    -Warith-conversion
    -Wsign-conversion

    # --- Initialization & Variable Usage ---
    -Wuninitialized
    -Wmaybe-uninitialized
    -Wno-uninitialized
    -Winit-self
    -Wclobbered
    -Wunused-parameter
    -Wunused-result

    # --- Prototypes, Declarations & Linking ---
    -Wstrict-prototypes
    -Wmissing-prototypes
    -Wmissing-declarations
    -Wnested-externs
    -Wunused-function
    -Wno-unused-function

    # --- Pointers & Pointer Arithmetic ---
    -Wpointer-arith
    -Waddress
    -Walloca
    -Wfree-nonheap-object
    -Wrestrict
    -Wnonnull

    # --- Format String Checks (printf/scanf) ---
    -Wformat=2
    -Wformat-overflow=2
    -Wformat-truncation=2
    -Wformat-signedness
    -Wformat-y2k
    -Wmissing-format-attribute

    # --- Control Flow & Resource Usage ---
    -Wunreachable-code
    -Wsequence-point
    -Wjump-misses-init
    -Wstack-usage=8192
    -Wfloat-equal
    -Wdouble-promotion
    -Wwrite-strings

    # --- Redundancies & Unused Declarations ---
    -Wredundant-decls

    # --- Switch Statements & Case Coverage ---
    -Wswitch-default
    -Wswitch-enum
    -Wno-switch-default

    # --- Duplicate Code & Logical Checks ---
    -Wduplicated-cond
    -Wduplicated-branches
    -Wlogical-op

    # --- Performance & Vectorization Warnings ---
    -Wunsafe-loop-optimizations
    -Wvector-operation-performance

    # --- Other Useful Warnings ---
    -Wvla
    -Wempty-body
    -Wdate-time
    -Winvalid-pch
    -Wtrigraphs
    -Wundef
    -Wsuggest-attribute=format
    -Wsuggest-attribute=noreturn
    -Wdeprecated
    -Wno-deprecated-declarations
)

# ----------------------------------------------------------------------------
# 6. Include Subdirectories and Enable Testing
# ----------------------------------------------------------------------------
add_subdirectory(src)
add_subdirectory(doxygen)

enable_testing()
add_subdirectory(tests)

# ----------------------------------------------------------------------------
# 7. Informational Output
# ----------------------------------------------------------------------------
get_filename_component(COMPILER_NAME ${CMAKE_C_COMPILER} NAME)

include(ProcessorCount)
ProcessorCount(NPROC)

if (NOT WIN32)
  string(ASCII 27 ESC)

  set(ANSI_RESET   "${ESC}[0m")
  set(ANSI_RED     "${ESC}[31m")
  set(ANSI_GREEN   "${ESC}[32m")
  set(ANSI_BLUE    "${ESC}[34m")
  set(ANSI_MAGENTA "${ESC}[35m")
endif()

message(STATUS "")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Project:        ${ANSI_MAGENTA}${PROJECT_NAME}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Build type:     ${ANSI_GREEN}${CMAKE_BUILD_TYPE}${ANSI_RESET}")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Compiler:       ${ANSI_GREEN}${CMAKE_C_COMPILER_ID} ${COMPILER_NAME} V${CMAKE_C_COMPILER_VERSION}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  C Standard:     ${ANSI_GREEN}C${CMAKE_C_STANDARD}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  CMake Version:  ${ANSI_GREEN}${CMAKE_VERSION}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Generator:      ${ANSI_GREEN}${CMAKE_GENERATOR}${ANSI_RESET}")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  System arch:    ${ANSI_GREEN}${CMAKE_SYSTEM_PROCESSOR}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Host arch:      ${ANSI_GREEN}${CMAKE_HOST_SYSTEM_PROCESSOR}${ANSI_RESET}")

if (CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  execute_process(
    COMMAND ${CMAKE_C_COMPILER} -dumpmachine
    OUTPUT_VARIABLE _TARGET_TRIPLE
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  message(STATUS "${ANSI_RESET}  Target triple:  ${ANSI_GREEN}${_TARGET_TRIPLE}${ANSI_RESET}")
endif()

message(STATUS "${ANSI_RESET}  OS:             ${ANSI_GREEN}${CMAKE_SYSTEM_NAME} (${CMAKE_SYSTEM_VERSION})${ANSI_RESET}")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")

if (VALGRIND_EXECUTABLE)
    message(STATUS "${ANSI_RESET}  Valgrind:       ${ANSI_GREEN}${VALGRIND_EXECUTABLE}${ANSI_RESET}")
else()
    message(STATUS "${ANSI_RESET}  Valgrind:       ${ANSI_RED}<not found>  (running tests without memcheck)${ANSI_RESET}")
endif()
if (DOXYGEN_EXECUTABLE)
    message(STATUS "${ANSI_RESET}  Doxygen:        ${ANSI_GREEN}${DOXYGEN_EXECUTABLE}${ANSI_RESET}")
else()
    message(STATUS "${ANSI_RESET}  Doxygen:        ${ANSI_RED}<not found>  (skip docs)${ANSI_RESET}")
endif()

message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Parallel Jobs:  ${ANSI_GREEN}${NPROC}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Binaries in:    ${ANSI_GREEN}${OUTPUT_BIN_DIR}${ANSI_RESET}")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "")
