# SPDX-FileCopyrightText: 2026 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: GPL-3.0-only

# -----------------------------------------------------------------------------
# File: cmake/linker-flags.cmake
# Purpose:
#   Select linker defenses, tested IPO, instrumentation and symbol reduction.
# Notes:
#   Policies apply to owned targets; installed consumers retain their own flags.
# -----------------------------------------------------------------------------

include_guard(GLOBAL)
include(CheckLinkerFlag)
include(CheckIPOSupported)
include(CheckPIESupported)

# -----------------------------------------------------------------------------
# 1. Linker probes use CMake's driver-independent LINKER spelling.
# -----------------------------------------------------------------------------
# lma_link_option(target, flag, configurations)
# Add an optional link flag privately after the selected toolchain accepts it.
function(lma_link_option target flag configurations)
  string(SHA256 identity "${CMAKE_C_COMPILER};${CMAKE_LINKER_TYPE};${flag}")
  check_linker_flag(C "${flag}" "LMA_LD_${identity}")
  if(LMA_LD_${identity})
    if(configurations)
      target_link_options(${target} PRIVATE "$<$<CONFIG:${configurations}>:${flag}>")
    else()
      target_link_options(${target} PRIVATE "${flag}")
    endif()
  else()
    message(STATUS "Optional linker flag unavailable: ${flag}")
  endif()
endfunction()

# -----------------------------------------------------------------------------
# 2. Instrumentation is explicit and compile/link tested as one option set.
# -----------------------------------------------------------------------------
# lma_instrumentation(target)
# Keep runtime link requirements on instrumented libraries for their consumers.
function(lma_instrumentation target)
  if(NOT LMA_SANITIZERS AND NOT LMA_ENABLE_COVERAGE)
    return()
  endif()
  if(MSVC OR NOT CMAKE_C_COMPILER_ID MATCHES "GNU|Clang")
    message(FATAL_ERROR "This instrumentation profile requires a GNU-style GCC/Clang driver")
  endif()
  if(LMA_ENABLE_COVERAGE)
    set(flag --coverage)
  else()
    foreach(sanitizer IN LISTS LMA_SANITIZERS)
      if(NOT sanitizer MATCHES "^(address|undefined|leak|thread|memory)$")
        message(FATAL_ERROR "Unsupported sanitizer contract: ${sanitizer}")
      endif()
    endforeach()
    if("thread" IN_LIST LMA_SANITIZERS AND ("address" IN_LIST LMA_SANITIZERS OR "leak" IN_LIST
                                                                                LMA_SANITIZERS))
      message(FATAL_ERROR "Thread sanitizer cannot be combined with address/leak")
    endif()
    if("memory" IN_LIST LMA_SANITIZERS AND NOT CMAKE_C_COMPILER_ID STREQUAL "Clang")
      message(FATAL_ERROR "Memory sanitizer requires Clang and an instrumented runtime")
    endif()
    list(JOIN LMA_SANITIZERS "," sanitizer_set)
    set(flag "-fsanitize=${sanitizer_set}")
  endif()
  string(SHA256 identity "${flag}")
  set(CMAKE_REQUIRED_FLAGS "${flag}")
  check_c_source_compiles("int main(void) { return 0; }" "LMA_INSTRUMENT_${identity}")
  if(NOT LMA_INSTRUMENT_${identity})
    message(FATAL_ERROR "Requested instrumentation cannot compile and link: ${flag}")
  endif()
  target_compile_options(${target} PRIVATE "${flag}" -fno-omit-frame-pointer)
  target_link_options(${target} PUBLIC "${flag}")
endfunction()

# -----------------------------------------------------------------------------
# 3. IPO belongs to CMake; AUTO avoids compiler-specific portable static archives.
# -----------------------------------------------------------------------------
# lma_ipo(target)
# Enable tested release IPO without instrumented or portable static archives.
function(lma_ipo target)
  get_target_property(kind ${target} TYPE)
  set(ipo FALSE)
  if(NOT LMA_IPO STREQUAL "OFF"
     AND NOT LMA_SANITIZERS
     AND NOT LMA_ENABLE_COVERAGE)
    if(LMA_IPO STREQUAL "ON" OR NOT kind STREQUAL "STATIC_LIBRARY")
      check_ipo_supported(
        RESULT ipo
        OUTPUT detail
        LANGUAGES C)
      if(NOT ipo AND LMA_IPO STREQUAL "ON")
        message(FATAL_ERROR "Requested IPO is unavailable: ${detail}")
      endif()
    endif()
  endif()
  set_target_properties(
    ${target}
    PROPERTIES INTERPROCEDURAL_OPTIMIZATION FALSE
               INTERPROCEDURAL_OPTIMIZATION_DEBUG FALSE
               INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO FALSE
               INTERPROCEDURAL_OPTIMIZATION_RELEASE "${ipo}"
               INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL "${ipo}")
endfunction()

# Configure target linkage after capability-checked optimization and instrumentation.
function(lma_linker_flags target)
  get_target_property(kind ${target} TYPE)
  lma_ipo(${target})
  lma_instrumentation(${target})

  if(kind STREQUAL "EXECUTABLE")
    check_pie_supported(LANGUAGES C)
    set_property(TARGET ${target} PROPERTY POSITION_INDEPENDENT_CODE TRUE)
  endif()
  if(kind STREQUAL "STATIC_LIBRARY")
    return()
  endif()

  if(MSVC)
    foreach(flag IN ITEMS /INCREMENTAL:NO /Brepro)
      lma_link_option(${target} "${flag}" "")
    endforeach()
    if(LMA_HARDENING)
      foreach(flag IN ITEMS /NXCOMPAT /DYNAMICBASE /guard:cf)
        lma_link_option(${target} "${flag}" "")
      endforeach()
      if(CMAKE_SIZEOF_VOID_P EQUAL 8)
        lma_link_option(${target} /HIGHENTROPYVA "")
      endif()
    endif()
    foreach(flag IN ITEMS /OPT:REF /OPT:ICF)
      lma_link_option(${target} "${flag}" "Release,MinSizeRel")
    endforeach()
  elseif(WIN32)
    foreach(flag IN ITEMS "LINKER:--dynamicbase" "LINKER:--nxcompat" "LINKER:--no-insert-timestamp")
      lma_link_option(${target} "${flag}" "")
    endforeach()
  elseif(APPLE)
    lma_link_option(${target} "LINKER:-dead_strip" "Release,MinSizeRel")
    if(LMA_RELEASE_MINIMIZE
       AND NOT LMA_SANITIZERS
       AND NOT LMA_ENABLE_COVERAGE)
      lma_link_option(${target} "LINKER:-S,-x" "Release,MinSizeRel")
    endif()
  elseif(CMAKE_EXECUTABLE_FORMAT STREQUAL "ELF")
    lma_link_option(${target} "LINKER:--build-id=sha1" "")
    lma_link_option(${target} "LINKER:--gc-sections" "Release,MinSizeRel")
    if(LMA_HARDENING)
      foreach(flag IN ITEMS "LINKER:-z,relro" "LINKER:-z,now" "LINKER:-z,noexecstack"
                            "LINKER:-z,separate-code" "LINKER:--as-needed")
        lma_link_option(${target} "${flag}" "")
      endforeach()
      if(NOT LMA_SANITIZERS)
        lma_link_option(${target} "LINKER:-z,defs" "")
      endif()
    endif()
    if(LMA_RELEASE_MINIMIZE
       AND NOT LMA_SANITIZERS
       AND NOT LMA_ENABLE_COVERAGE)
      lma_link_option(${target} "LINKER:--strip-all" "Release,MinSizeRel")
    endif()
  endif()
endfunction()

# EOF

