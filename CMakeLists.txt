cmake_minimum_required(VERSION 3.24)
project(libmemalloc C)

# -----------------------------------------------------------------------------
# 1) User Options
# -----------------------------------------------------------------------------
option(DOCS_EN     "Generate Doxygen site (subdir doxygen/)"           ON)
option(GCOVR_DOCS  "Publish coverage (gcovr) inside the Doxygen site"  ON)
option(TESTS_EN    "Enable test tree (ctest)"                          ON)
option(ASM_EN      "Enable Assembly language"                          OFF)

# ----------------------------------------------------------------------------
# 2) Basic Project Settings
# ----------------------------------------------------------------------------
include(FetchContent)
include(CheckCCompilerFlag)
include(CheckCSourceCompiles)
include(ProcessorCount)

if(TESTS_EN)
	include(CTest)
endif()

if(ASM_EN)
  enable_language(ASM)
endif()

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Let CMake drive IPO/LTO in Release
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# Default build type for single-config generators
if(NOT CMAKE_CONFIGURATION_TYPES AND NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Build type" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release RelWithDebInfo MinSizeRel)
endif()

# ----------------------------------------------------------------------------
# 3) Checking dependencies
# ----------------------------------------------------------------------------
set(MIN_GCC_VERSION   "12.2.0")
set(MIN_CLANG_VERSION "11.0")
set(MIN_MSVC_VERSION  "19.20")

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  if(CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_GCC_VERSION})
    message(FATAL_ERROR "GCC >= ${MIN_GCC_VERSION}"
						"required (found ${CMAKE_C_COMPILER_VERSION}).")
  endif()
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
  if(CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_CLANG_VERSION})
    message(FATAL_ERROR "Clang >= ${MIN_CLANG_VERSION}"
						"required (found ${CMAKE_C_COMPILER_VERSION}).")
  endif()
elseif(MSVC)
  if(CMAKE_C_COMPILER_VERSION VERSION_LESS ${MIN_MSVC_VERSION})
    message(FATAL_ERROR "MSVC >= ${MIN_MSVC_VERSION}"
						"required (found ${CMAKE_C_COMPILER_VERSION}).")
  endif()
else()
  message(WARNING "Unrecognized compiler: ${CMAKE_C_COMPILER_ID}")
endif()

find_program(VALGRIND_EXECUTABLE NAMES valgrind)
find_program(GCOVR_EXECUTABLE    NAMES gcovr)
find_package(Doxygen QUIET)

# ----------------------------------------------------------------------------
# 4) Output Directories for Binaries
#    - Archive (static libraries)
#    - Library (shared libraries)
#    - Runtime (executables)
# ----------------------------------------------------------------------------
set(OUTPUT_BIN_DIR "${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE}")
file(MAKE_DIRECTORY "${OUTPUT_BIN_DIR}")

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${OUTPUT_BIN_DIR}")

# -----------------------------------------------------------------------------
# 5) Build-Type Flags (safe per-compiler)
# -----------------------------------------------------------------------------

# -- Debug ---------------------------------------------------------------------
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
				-frecord-gcc-switches

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
			option(ENABLE_ANALYZER_DUMPS "Write GCC analyzer dumps to files (not stderr)" OFF)

			set(ANALYZER_FLAGS
				-fanalyzer
				-fanalyzer-verbosity=3
			)

			if (ENABLE_ANALYZER_DUMPS)
				list(APPEND ANALYZER_FLAG
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
			endif()

      add_compile_options(${ANALYZER_FLAGS})

    endif()

    if (NOT VALGRIND_EXECUTABLE)
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

# -- Release -------------------------------------------------------------------
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_options(
        # --- NDEBUG & Optimization ---
        -DNDEBUG
        -Ofast
        -Os

        # --- Math & Overflow ---
				-fno-strict-overflow

        # --- Frame Pointer & Inlining ---
        -fomit-frame-pointer
        -funroll-loops

        # --- Exceptions & Unwind Tables ---
        -fno-exceptions
        -fno-unwind-tables

        # --- Stack & Data Sections ---
        -fdata-sections
        -ffunction-sections

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

# -----------------------------------------------------------------------------
# 6) Global Hardening & Warnings (per-compiler) + Platform Linker Settings
# ----------------------------------------------------------------------------

set(_FORTIFY_LVL 2)
check_c_source_compiles("
  #include <features.h>
  #if !defined(__GLIBC__) || (__GLIBC__*100 + __GLIBC_MINOR__) < 235
		#error FORTIFY3 not available
  #endif
  int main(void){return 0;}
" LIBMEMALLOC_HAVE_GLIBC_235)
if(LIBMEMALLOC_HAVE_GLIBC_235)
  set(_FORTIFY_LVL 3)
endif()

add_compile_options(-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=${_FORTIFY_LVL})

add_compile_options(
    # --- Hardening / Security ---
    -fstack-protector-strong
		-fstack-clash-protection
		-fno-delete-null-pointer-checks
		-fwrapv
    -Wpacked-bitfield-compat
    -Wpacked-not-aligned
    -Waddress-of-packed-member
    -Wpadded
    -Wformat-security
    -Werror=format-security

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

    # --- Optimization & Static Analysis ---
    -fstrict-aliasing
    -fanalyzer

    # --- Basic Code Quality Warnings ---
    -Wall
    -Wextra
    -Wpedantic
    -Werror
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

if (MSVC)
  add_compile_options(
    /GS
    /sdl
    /guard:cf
    /Qspectre
    /W4
    $<$<COMPILE_LANGUAGE:CXX>:/GR->
  )
  add_link_options(
    /NXCOMPAT
    /DYNAMICBASE
  )
  if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    add_link_options(/HIGHENTROPYVA)
  endif()
endif()

# ELF linker hardening (non-Apple, non-MSVC)
if (UNIX AND NOT APPLE AND NOT MSVC AND CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
  add_link_options(
    -Wl,-z,relro
    -Wl,-z,now
    -Wl,-z,noexecstack
    -Wl,-z,separate-code
    -Wl,--as-needed
    -Wl,-z,defs
		-Wl,--build-id=sha1
  )
endif()

# CET (x86_64) when supported
check_c_compiler_flag("-fcf-protection=full" HAVE_CET)
if(HAVE_CET AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|amd64")
  add_compile_options(
		-fcf-protection=full
		-fno-plt
	)
  add_link_options(
		-Wl,-z,cet-report=error
		-Wl,-z,shstk
	)
endif()

# AArch64 MTE/BTI
check_c_compiler_flag("-mbranch-protection=standard" HAVE_BPROT)
check_c_compiler_flag("-march=armv8.5-a+memtag"      HAVE_ARM_MEMTAG)
check_c_compiler_flag("-march=armv8.5-a+mte"         HAVE_ARM_MTE)
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|AARCH64")
  if(HAVE_BPROT)
    if(HAVE_ARM_MEMTAG)
      add_compile_options(-mbranch-protection=standard -march=armv8.5-a+memtag)
    elseif(HAVE_ARM_MTE)
      add_compile_options(-mbranch-protection=standard -march=armv8.5-a+mte)
    else()
      add_compile_options(-mbranch-protection=standard)
    endif()
  endif()
endif()

check_c_compiler_flag("-ftrivial-auto-var-init=pattern" HAVE_TRIVIAL_AUTO_VAR_INIT_PATTERN)
if (HAVE_TRIVIAL_AUTO_VAR_INIT_PATTERN)
  add_compile_options($<$<CONFIG:Debug,RelWithDebInfo>:-ftrivial-auto-var-init=pattern>)
endif()

check_c_compiler_flag("-fzero-call-used-regs=used" HAVE_ZERO_CALL_USED_REGS_USED)
if (HAVE_ZERO_CALL_USED_REGS_USED)
  add_compile_options($<$<CONFIG:Debug,RelWithDebInfo>:-fzero-call-used-regs=used>)
endif()

# PIE for executables (libs are PIC via POSITION_INDEPENDENT_CODE)
add_compile_options($<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-fPIE>)
add_link_options($<$<STREQUAL:$<TARGET_PROPERTY:TYPE>,EXECUTABLE>:-pie>)

# ----------------------------------------------------------------------------
# 7) Include Subdirectories and Enable Testing
# ----------------------------------------------------------------------------
add_subdirectory(src)

if (TESTS_EN)
	if (BUILD_TESTING)
		enable_testing()
		add_subdirectory(tests)
	endif()
endif()

if (DOCS_EN)
	add_subdirectory(doxygen)
endif()

# ----------------------------------------------------------------------------
# 8) Informational Output
# ----------------------------------------------------------------------------
get_filename_component(COMPILER_NAME ${CMAKE_C_COMPILER} NAME)

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

# Valgrind
if (VALGRIND_EXECUTABLE)

  set(_VALGRIND_VER "unknown")
  execute_process(
    COMMAND "${VALGRIND_EXECUTABLE}" --version
    OUTPUT_VARIABLE _vout
    ERROR_VARIABLE  _verr
    RESULT_VARIABLE _vres
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  if(_vres EQUAL 0)
    set(_vtext "${_vout}${_verr}")
    string(REGEX MATCH "[0-9]+(\\.[0-9]+)+" _VALGRIND_VER "${_vtext}")
    if(_VALGRIND_VER STREQUAL "")
      set(_VALGRIND_VER "unknown")
    endif()
  endif()

  message(STATUS "${ANSI_RESET}  Valgrind:       ${ANSI_GREEN}${VALGRIND_EXECUTABLE}${ANSI_RESET}  ${ANSI_GREEN}(v${_VALGRIND_VER})${ANSI_RESET}")
else()
    message(STATUS "${ANSI_RESET}  Valgrind:       ${ANSI_RED}<not found>  (running tests without memcheck)${ANSI_RESET}")
endif()

# Doxygen
if (DOXYGEN_EXECUTABLE)

 set(_DOXY_VER "unknown")
  execute_process(
    COMMAND "${DOXYGEN_EXECUTABLE}" --version
    OUTPUT_VARIABLE _dout
    ERROR_VARIABLE  _derr
    RESULT_VARIABLE _dres
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  if(_dres EQUAL 0)
    set(_dtext "${_dout}${_derr}")
    string(REGEX MATCH "[0-9]+(\\.[0-9]+)+" _DOXY_VER "${_dtext}")
    if(_DOXY_VER STREQUAL "")
      set(_DOXY_VER "unknown")
    endif()
  endif()

  message(STATUS "${ANSI_RESET}  Doxygen:        ${ANSI_GREEN}${DOXYGEN_EXECUTABLE}${ANSI_RESET}  ${ANSI_GREEN}(v${_DOXY_VER})${ANSI_RESET}")
else()
    message(STATUS "${ANSI_RESET}  Doxygen:        ${ANSI_RED}<not found>  (skip docs)${ANSI_RESET}")
endif()

# Gcovr (llvm-cov backend when using Clang)
if (GCOVR_EXECUTABLE)

  set(_GCOVR_VER "unknown")
  execute_process(
    COMMAND "${GCOVR_EXECUTABLE}" --version
    OUTPUT_VARIABLE _gout
    ERROR_VARIABLE  _gerr
    RESULT_VARIABLE _gres
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_STRIP_TRAILING_WHITESPACE
  )
  if(_gres EQUAL 0)
    set(_gtext "${_gout}${_gerr}")
    string(REGEX MATCH "[0-9]+(\\.[0-9]+)+" _GCOVR_VER "${_gtext}")
    if(_GCOVR_VER STREQUAL "")
      set(_GCOVR_VER "unknown")
    endif()
  endif()

  set(_GCOV_BACKEND_STR "")
  if(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    find_program(LLVM_COV_EXECUTABLE NAMES llvm-cov)
    if(LLVM_COV_EXECUTABLE)
      set(_LLVM_COV_VER "unknown")
      execute_process(
        COMMAND "${LLVM_COV_EXECUTABLE}" --version
        OUTPUT_VARIABLE _lc_out
        ERROR_VARIABLE  _lc_err
        RESULT_VARIABLE _lc_res
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_STRIP_TRAILING_WHITESPACE
      )
      if(_lc_res EQUAL 0)
        set(_lctext "${_lc_out}${_lc_err}")
        string(REGEX MATCH "[0-9]+(\\.[0-9]+)+" _LLVM_COV_VER "${_lctext}")
        if(_LLVM_COV_VER STREQUAL "")
          set(_LLVM_COV_VER "unknown")
        endif()
      endif()
      set(_GCOV_BACKEND_STR "  ${ANSI_RESET}[backend: ${ANSI_GREEN}llvm-cov gcov v${_LLVM_COV_VER}${ANSI_RESET}]")
    endif()
  endif()

  message(STATUS "${ANSI_RESET}  Gcovr:          ${ANSI_GREEN}${GCOVR_EXECUTABLE}${ANSI_RESET}  ${ANSI_GREEN}(v${_GCOVR_VER})${ANSI_RESET}${_GCOV_BACKEND_STR}")
else()
  message(STATUS "${ANSI_RESET}  Gcovr:          ${ANSI_RED}<not found>${ANSI_RESET}")
endif()

message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Parallel Jobs:  ${ANSI_GREEN}${NPROC}${ANSI_RESET}")
message(STATUS "${ANSI_RESET}  Binaries in:    ${ANSI_GREEN}${OUTPUT_BIN_DIR}${ANSI_RESET}")
message(STATUS "${ANSI_BLUE}=====================================================================${ANSI_RESET}")
message(STATUS "")