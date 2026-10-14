# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/compiler-flags.cmake
# Purpose:
#   Probe compiler-specific diagnostics, instrumentation and hardening.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

include_guard(GLOBAL)
include(CheckCCompilerFlag)
include(CheckCSourceCompiles)

# -----------------------------------------------------------------------------
# 1. Capability probes: unsupported optional flags are reported and omitted.
# -----------------------------------------------------------------------------
# lma_compile_option(target, flag, configurations)
# Add a supported C-only option privately; an empty configuration means all.
function(lma_compile_option target flag configurations)
  string(SHA256 identity "${CMAKE_C_COMPILER};${CMAKE_C_COMPILER_VERSION};${flag}")
  if(MSVC)
    set(CMAKE_REQUIRED_FLAGS "/WX")
  else()
    set(CMAKE_REQUIRED_FLAGS "-Werror")
  endif()
  check_c_compiler_flag("${flag}" "LMA_CC_${identity}")
  if(LMA_CC_${identity})
    if(configurations)
      target_compile_options(
        ${target} PRIVATE "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:${configurations}>>:${flag}>")
    else()
      target_compile_options(${target} PRIVATE "$<$<COMPILE_LANGUAGE:C>:${flag}>")
    endif()
  else()
    message(STATUS "Optional compiler flag unavailable: ${flag}")
  endif()
endfunction()

# Probe compatible diagnostic groups together, splitting only rejected groups.
# Results remain in this configuration's cache; dialect/link checks stay separate.
function(lma_warning_group target)
  set(flags ${ARGN})
  list(LENGTH flags count)
  if(count EQUAL 1)
    lma_compile_option(${target} "${flags}" "")
    return()
  endif()
  string(SHA256 identity "${CMAKE_C_COMPILER};${CMAKE_C_COMPILER_VERSION};${flags}")
  if(MSVC)
    set(CMAKE_REQUIRED_FLAGS "/WX")
  else()
    set(CMAKE_REQUIRED_FLAGS "-Werror")
  endif()
  check_c_compiler_flag("${flags}" "LMA_WARNINGS_${identity}")
  if(LMA_WARNINGS_${identity})
    foreach(flag IN LISTS flags)
      target_compile_options(${target} PRIVATE "$<$<COMPILE_LANGUAGE:C>:${flag}>")
    endforeach()
  else()
    math(EXPR middle "${count} / 2")
    list(SUBLIST flags 0 ${middle} first)
    list(SUBLIST flags ${middle} -1 second)
    lma_warning_group(${target} ${first})
    lma_warning_group(${target} ${second})
  endif()
endfunction()

# -----------------------------------------------------------------------------
# 2. Wide diagnostics without ABI changes or weakened language semantics.
# -----------------------------------------------------------------------------
# lma_compiler_flags(target)
# Apply owned-source warnings and configuration-specific defenses to one target.
function(lma_warning_flags target)
  if(MSVC)
    set(warnings /W4 /sdl /Zc:preprocessor /utf-8)
    if(LMA_WARNINGS_AS_ERRORS)
      list(APPEND warnings /WX)
    endif()
  elseif(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    set(warnings
        -Wall
        -Wextra
        -Wpedantic
        -Wformat=2
        -Wformat-security
        -Werror=format-security
        -Wshadow
        -Wconversion
        -Wsign-conversion
        -Wcast-align
        -Wcast-qual
        -Wcast-function-type
        -Wbad-function-cast
        -Wstrict-prototypes
        -Wmissing-prototypes
        -Wmissing-declarations
        -Wnested-externs
        -Wpointer-arith
        -Wwrite-strings
        -Wundef
        -Wvla
        -Wdouble-promotion
        -Wfloat-equal
        -Wswitch-enum
        -Wswitch-default
        -Wredundant-decls
        -Wdate-time
        -Wuninitialized
        -Winit-self
        -Walloca
        -Wnull-dereference
        -Waddress-of-packed-member)
    if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
      list(
        APPEND
        warnings
        -Warith-conversion
        -Wduplicated-cond
        -Wduplicated-branches
        -Wlogical-op
        -Wformat-overflow=2
        -Wformat-truncation=2
        -Wformat-signedness
        -Wrestrict
        -Walloc-zero
        -Walloc-size
        -Warray-bounds=2
        -Wstringop-overflow=4
        -Wstringop-overread
        -Wbidi-chars=any
        -Wtrampolines
        -Wstack-usage=8192)
    else()
      list(
        APPEND
        warnings
        -Wcomma
        -Wconditional-uninitialized
        -Wdocumentation
        -Wimplicit-fallthrough
        -Wshorten-64-to-32)
    endif()
    if(LMA_WARNINGS_AS_ERRORS)
      list(APPEND warnings -Werror)
    endif()
  endif()
  if(warnings)
    lma_warning_group(${target} ${warnings})
  endif()

endfunction()

# Apply build-type diagnostics and remove absolute source/build paths.
function(lma_configuration_flags target)
  # ---------------------------------------------------------------------------
  # 3. Debug retains evidence; Release minimizes metadata without unsafe math.
  # ---------------------------------------------------------------------------
  if(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang" AND NOT MSVC)
    lma_compile_option(${target} -g3 "Debug")
    lma_compile_option(${target} -fno-omit-frame-pointer "Debug,RelWithDebInfo")
    lma_compile_option(${target} -fno-plt "Release,RelWithDebInfo")
    foreach(flag IN ITEMS -fno-common -ffunction-sections -fdata-sections)
      lma_compile_option(${target} "${flag}" "")
    endforeach()
    foreach(
      flag IN
      ITEMS "-ffile-prefix-map=${PROJECT_SOURCE_DIR}=."
            "-ffile-prefix-map=${PROJECT_BINARY_DIR}=./build"
            "-fdebug-prefix-map=${PROJECT_SOURCE_DIR}=."
            "-fdebug-prefix-map=${PROJECT_BINARY_DIR}=./build")
      lma_compile_option(${target} "${flag}" "")
    endforeach()
    if(LMA_RELEASE_MINIMIZE
       AND NOT LMA_SANITIZERS
       AND NOT LMA_ENABLE_COVERAGE)
      lma_compile_option(${target} -g0 "Release,MinSizeRel")
      lma_compile_option(${target} -fno-ident "Release,MinSizeRel")
    endif()
  elseif(MSVC)
    lma_compile_option(${target} "/pathmap:${PROJECT_SOURCE_DIR}=." "")
    lma_compile_option(${target} "/pathmap:${PROJECT_BINARY_DIR}=./build" "")
  endif()

endfunction()

# Apply target-compatible stack and initialization defenses.
function(lma_runtime_defenses target)
  # ---------------------------------------------------------------------------
  # 4. Runtime defenses: never infer CPU features from the build host.
  # ---------------------------------------------------------------------------
  if(LMA_HARDENING)
    if(MSVC)
      foreach(flag IN ITEMS /GS /guard:cf /Qspectre)
        lma_compile_option(${target} "${flag}" "")
      endforeach()
    elseif(CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
      foreach(flag IN ITEMS -fstack-protector-strong -fstack-clash-protection
                            -fstrict-flex-arrays=3 -ftrivial-auto-var-init=zero)
        lma_compile_option(${target} "${flag}" "")
      endforeach()
      lma_compile_option(${target} -fzero-call-used-regs=used-gpr "Release,RelWithDebInfo")
      check_c_source_compiles(
        "#include <features.h>
        #if !defined(__GLIBC__) || (__GLIBC__ * 100 + __GLIBC_MINOR__) < 235
        #error Requires glibc 2.35
        #endif
        int main(void) { return 0; }"
        LMA_HAVE_FORTIFY3)
      if(LMA_HAVE_FORTIFY3)
        set(fortify 3)
      else()
        set(fortify 2)
      endif()
      # Respect a caller-owned FORTIFY definition and require an optimized build.
      if(NOT CMAKE_C_FLAGS MATCHES "_FORTIFY_SOURCE")
        target_compile_definitions(
          ${target}
          PRIVATE "$<$<CONFIG:Release,RelWithDebInfo,MinSizeRel>:_FORTIFY_SOURCE=${fortify}>")
      endif()
    endif()
  endif()

endfunction()

# Select branch protection from the target architecture and explicit policy.
function(lma_branch_defenses target)
  # Architecture controls describe target code generation, not detected host CPUs.
  set(branch_flag "")
  set(branch_policy OFF)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64|i.86)$")
    set(branch_policy "${LMA_CET}")
    set(branch_flag -fcf-protection=full)
  elseif(LMA_CET STREQUAL "ON")
    message(FATAL_ERROR "CET requires an x86 target")
  endif()
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
    set(branch_policy "${LMA_AARCH64_HARDEN}")
    set(branch_flag -mbranch-protection=standard)
  elseif(LMA_AARCH64_HARDEN STREQUAL "ON")
    message(FATAL_ERROR "AArch64 branch protection requires an AArch64 target")
  endif()
  if(NOT branch_policy STREQUAL "OFF"
     AND LMA_HARDENING
     AND NOT MSVC)
    string(SHA256 branch_identity "${branch_flag}")
    check_c_compiler_flag("${branch_flag}" "LMA_BRANCH_${branch_identity}")
    if(LMA_BRANCH_${branch_identity})
      target_compile_options(${target} PRIVATE "${branch_flag}")
    elseif(branch_policy STREQUAL "ON")
      message(FATAL_ERROR "Requested branch protection is unavailable: ${branch_flag}")
    endif()
  elseif(branch_policy STREQUAL "ON")
    message(FATAL_ERROR "Explicit branch protection requires hardening and a GNU-style driver")
  endif()

endfunction()

# Apply composed compiler policy and the explicitly requested static analyzer.
function(lma_compiler_flags target)
  lma_warning_flags(${target})
  lma_configuration_flags(${target})
  lma_runtime_defenses(${target})
  lma_branch_defenses(${target})

  if(LMA_ENABLE_ANALYZER)
    check_c_compiler_flag(-fanalyzer LMA_HAVE_ANALYZER)
    if(NOT LMA_HAVE_ANALYZER)
      message(FATAL_ERROR "Requested GCC analyzer is unavailable")
    endif()
    target_compile_options(${target} PRIVATE -fanalyzer)
  endif()
endfunction()

# EOF

