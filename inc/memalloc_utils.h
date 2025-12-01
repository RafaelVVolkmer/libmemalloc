/** ============================================================================
 *  @addtogroup Libmemalloc
 *  @{
 *
 *  @brief      Architecture, alignment, and attribute utilities for
 * libmemalloc.
 *
 *  @file       memalloc_utils.h
 *
 *  @details    Provides architecture-aware alignment definitions, symbol
 *              visibility attributes, and compiler optimization hints used
 *              throughout libmemalloc. Ensures consistent alignment,
 *              attribute semantics, and performance annotations across
 *              multiple target architectures and toolchains.
 *
 *  @version    v1.0.00
 *  @date       29.09.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

#pragma once

/*< C++ Compatibility >*/
#ifdef __cplusplus
extern "C"
{
#endif

/** ============================================================================
 *              P U B L I C  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        ARCH_ALIGNMENT
 *  @brief      Defines architecture-specific memory alignment.
 *
 *  @details    Determines the appropriate memory alignment based
 *              on the current target architecture.
 * ========================================================================== */
#ifndef ARCH_ALIGNMENT
  /* x86_64 processor [64-bit] - Vendor: AMD/Intel */
  #if defined(__x86_64__) || defined(_M_X64) || defined(__amd64__)
    #define ARCH_ALIGNMENT (8U)

  /* i386 processor [32-bit] - Vendor: Intel */
  #elif defined(__i386__) || defined(_M_IX86) || defined(__386__)
    #define ARCH_ALIGNMENT (4U)

  /* aarch64 processor [64-bit] - Vendor: ARM */
  #elif defined(__aarch64__) || defined(_M_ARM64) || defined(__arm64__)
    #define ARCH_ALIGNMENT (8U)

  /* arm processor [32-bit] - Vendor: ARM (v7/v6) */
  #elif defined(__ARM_ARCH_7__) || defined(__ARM_ARCH_6__) || defined(__arm__) \
    || defined(_M_ARM)
    #define ARCH_ALIGNMENT (4U)

  /* riscv processor [64-bit] - Vendor: RISC-V */
  #elif defined(__riscv) && (__riscv_xlen == 64)
    #define ARCH_ALIGNMENT (8U)
  /* riscv processor [32-bit] - Vendor: RISC-V */
  #elif defined(__riscv) && (__riscv_xlen == 32)
    #define ARCH_ALIGNMENT (4U)

  /* powerpc processor [64-bit] - Vendor: IBM */
  #elif defined(__powerpc64__) || defined(__PPC64__)
    #define ARCH_ALIGNMENT (8U)
  /* powerpc processor [32-bit] - Vendor: IBM */
  #elif defined(__powerpc__) || defined(__PPC__)
    #define ARCH_ALIGNMENT (4U)

  /* s390x processor [64-bit] - Vendor: IBM */
  #elif defined(__s390x__) || defined(__s390__)
    #define ARCH_ALIGNMENT (8U)

  /* mips processor [64-bit] - Vendor: MIPS */
  #elif defined(__mips64) || defined(__mips64el__)
    #define ARCH_ALIGNMENT (8U)
  /* mips processor [32-bit] - Vendor: MIPS */
  #elif defined(__mips__)
    #define ARCH_ALIGNMENT (4U)

  /* loongarch processor [64-bit] - Vendor: Loongson */
  #elif defined(__loongarch__)
    #define ARCH_ALIGNMENT (8U)

  /* avr processor [8-bit] - Vendor: Microchip */
  #elif defined(__AVR__)
    #define ARCH_ALIGNMENT (2U)
  /* avr32 processor [32-bit] - Vendor: Microchip */
  #elif defined(__avr32__)
    #define ARCH_ALIGNMENT (4U)

  /* microblaze processor [32-bit] - Vendor: Xilinx */
  #elif defined(__MICROBLAZE__)
    #define ARCH_ALIGNMENT (4U)

  /* sh processor [32-bit] - Vendor: Renesas */
  #elif defined(__sh__)
    #define ARCH_ALIGNMENT (4U)

  /* arc processor [32-bit] - Vendor: Synopsys */
  #elif defined(__arc__)
    #define ARCH_ALIGNMENT (4U)

  /* bfin processor [32-bit] - Vendor: Analog Devices */
  #elif defined(__bfin__)
    #define ARCH_ALIGNMENT (4U)

  /* wasm processor [32-bit] - Vendor: WebAssembly/Emscripten */
  #elif defined(__EMSCRIPTEN__) || defined(__wasm__)
    #define ARCH_ALIGNMENT (4U)

  /* sparc processor [32-bit] - Vendor: Oracle */
  #elif defined(__sparc__) || defined(__sparc)
    #define ARCH_ALIGNMENT (4U)
  /* sparc processor [64-bit] - Vendor: Oracle (V9) */
  #elif defined(__sparcv9__)
    #define ARCH_ALIGNMENT (8U)

  /* ia64 processor [64-bit] - Vendor: Intel Itanium */
  #elif defined(__ia64__)
    #define ARCH_ALIGNMENT (8U)

  /* alpha processor [64-bit] - Vendor: DEC */
  #elif defined(__alpha__)
    #define ARCH_ALIGNMENT (8U)

  /* pru processor [32-bit] - Vendor: TI */
  #elif defined(__TI_PRU__) || defined(__PRU__)
    #define ARCH_ALIGNMENT (4U)
  /* PA-RISC [32-bit] – Vendor: HP PA-RISC */
  #elif defined(__hppa__)
    #define ARCH_ALIGNMENT (4U)

  /* z/Arch [64-bit] – Vendor: IBM Z */
  #elif defined(__zarch__)
    #define ARCH_ALIGNMENT (8U)

  /* SPU [32-bit] – Vendor: Cell Broadband */
  #elif defined(__cell_spu__)
    #define ARCH_ALIGNMENT (16U) /* SPU natural aligns to 16 bytes */

  /* NVPTX [64-bit] – Vendor: NVIDIA PTX */
  #elif defined(__NVPTX__) || defined(__PTX__)
    #define ARCH_ALIGNMENT (8U)

  /* eBPF [64-bit] – in-kernel VM */
  #elif defined(__bpf__)
    #define ARCH_ALIGNMENT (8U)

  /* Elbrus E2K [64-bit] – Vendor: MCST */
  #elif defined(__e2k__)
    #define ARCH_ALIGNMENT (8U)

  /* CRIS [32-bit] – Vendor: Axis Communications */
  #elif defined(__CRIS__)
    #define ARCH_ALIGNMENT (4U)

  /* TILEGX [64-bit] – Vendor: Tilera */
  #elif defined(__tilegx__)
    #define ARCH_ALIGNMENT (8U)

  /* Generic fallback */
  #else
    #error "[ERROR] Unknow Architecture: check 'ARCH_ALIGNMENT'"
  #endif
#endif

/** ============================================================================
 *  @def        ALIGN(x)
 *  @brief      Aligns a given value to the nearest memory boundary.
 *
 *  @param [in] val_  Value to be aligned.
 *
 *  @details    Uses bitwise operations to align the value to the
 *              nearest multiple of the current architecture's alignment.
 * ========================================================================== */
#define ALIGN(val_)   (((val_) + (ARCH_ALIGNMENT - 1U)) & ~(ARCH_ALIGNMENT - 1U))

/** ============================================================================
 *  @def        PTR_ERR
 *  @brief      Encodes a negative error code as an error pointer.
 *
 *  @param[in]  ptr_   Integer error code (negative errno value).
 *
 *  @return     A pointer whose value encodes the error code.
 *              To test and extract the code, use IS_ERR() and
 *              (intptr_t)ptr respectively.
 * ========================================================================== */
#define PTR_ERR(ptr_) ((void *)((intptr_t)(ptr_)))

/** ============================================================================
 *             P R I V A T E  A T T R I B U T E  W R A P P E R S
 * ========================================================================== */

/** ============================================================================
 *  @def        __LIBMEMALLOC_API
 *  @brief      Defines the default visibility attribute
 *              for exported symbols.
 *
 *  @details    When using GCC or compatible compilers, this macro
 *              expands to __attribute__((visibility("default")))
 *              to ensure that symbols are exported (visible)
 *              in the resulting shared library (.so).
 *              For compilers that do not support this attribute,
 *              it expands to nothing.
 * ========================================================================== */
#ifndef __LIBMEMALLOC_API
  #if defined(_WIN32)
    #ifdef BUILDING_LIBMEMALLOC
      #define __LIBMEMALLOC_API __declspec(dllexport)
    #else
      #define __LIBMEMALLOC_API __declspec(dllimport)
    #endif
  #else
    #if defined(__GNUC__) || defined(__clang__)
      #define __LIBMEMALLOC_API __attribute__((visibility("default")))
    #else
      #define __LIBMEMALLOC_API
    #endif
  #endif
#endif

/** ============================================================================
 *  @def        __ALIGN
 *  @brief      Defines structure alignment and enforces the target byte
 * order.
 *
 *  @details    When using GCC or Clang, expands to
 *              __attribute__((scalar_storage_order("<host-endian>"),
 *                                 aligned(ARCH_ALIGNMENT)))
 *              where <host-endian> fica automaticamente ajustado para
 *              "little-endian" ou "big-endian" conforme o compilador.
 *              Em compiladores sem suporte a esse atributo, expande para
 * nada.
 * ========================================================================== */
#ifndef __ALIGN
  #if defined(__GNUC__) || defined(__clang__)
    #if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
      #define __ALIGN                                      \
        __attribute__((scalar_storage_order("big-endian"), \
                       aligned(ARCH_ALIGNMENT)))
    #elif __BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__
      #define __ALIGN                                         \
        __attribute__((scalar_storage_order("little-endian"), \
                       aligned(ARCH_ALIGNMENT)))
    #else
      #error "[ERROR] Unknow Endianness: check '__BYTE_ORDER__'"
    #endif
  #else
    #define __ALIGN
  #endif
#endif

/** ===========================================================================
 *  @def        __UNUSED
 *  @brief      Marks a symbol as potentially unused.
 *
 *  @details    When supported by the compiler (GCC/Clang), expands to
 *              __attribute__((unused)), suppressing “unused variable”
 *              warnings. On other compilers it expands to nothing.
 * ========================================================================== */
#ifndef __UNUSED
  #if defined(__GNUC__) || defined(__clang__)
    #define __UNUSED __attribute__((unused))
  #else
    #define __UNUSED
  #endif
#endif

/** ============================================================================
 *  @def        __GC_HOT
 *  @brief      Marks garbage-collector functions as “hot” (performance
 * critical).
 *
 *  @details    When supported by the compiler (GCC/Clang), expands to
 *              __attribute__((hot)), informing the optimizer that the
 *              annotated function is on a performance-critical path and
 *              should be optimized accordingly. Otherwise, expands to nothing.
 * ========================================================================== */
#ifndef __GC_HOT
  #if defined(__GNUC__) || defined(__clang__)
    #define __GC_HOT __attribute__((hot))
  #else
    #define __GC_HOT
  #endif
#endif

/** ============================================================================
 *  @def        __GC_COLD
 *  @brief      Marks garbage-collector functions as “cold” (infrequently used).
 *
 *  @details    When supported by the compiler (GCC/Clang), expands to
 *              __attribute__((cold)), informing the optimizer that the
 *              annotated function is unlikely to execute frequently and
 *              may be placed out-of-line to reduce code size in hot paths.
 *              Otherwise, expands to nothing.
 * ========================================================================== */
#ifndef __GC_COLD
  #if defined(__GNUC__) || defined(__clang__)
    #define __GC_COLD __attribute__((cold))
  #else
    #define __GC_COLD
  #endif
#endif

/** ============================================================================
 *  @def        __LIBMEMALLOC_INTERNAL_MALLOC
 *  @brief      Annotates allocator functions that return
 *              newly allocated memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((malloc, alloc_size(2),
 *              warn_unused_result)) which tells the compiler
 *              the function behaves like malloc, that the 2nd
 *              parameter is the allocation size, and that the
 *              return value should not be ignored. Otherwise,
 *              expands to nothing.
 * ========================================================================== */
#ifndef __LIBMEMALLOC_INTERNAL_MALLOC
  #if defined(__GNUC__) || defined(__clang__)
    #define __LIBMEMALLOC_INTERNAL_MALLOC \
      __attribute__((malloc,              \
                     alloc_size(2),       \
                     warn_unused_result,  \
                     returns_nonnull,     \
                     zero_call_used_regs("all")))
  #else
    #define __LIBMEMALLOC_INTERNAL_MALLOC
  #endif
#endif

/** ============================================================================
 *  @def        __LIBMEMALLOC_MALLOC
 *  @brief      Annotates allocator functions that return
 *              newly allocated memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((malloc, alloc_size(1),
 *              warn_unused_result)) which tells the compiler
 *              the function behaves like malloc, that the 2nd
 *              parameter is the allocation size, and that the
 *              return value should not be ignored. Otherwise,
 *              expands to nothing.
 * ========================================================================== */
#ifndef __LIBMEMALLOC_MALLOC
  #if defined(__GNUC__) || defined(__clang__)
    #define __LIBMEMALLOC_MALLOC         \
      __attribute__((malloc,             \
                     alloc_size(1),      \
                     warn_unused_result, \
                     returns_nonnull,    \
                     zero_call_used_regs("all")))
  #else
    #define __LIBMEMALLOC_MALLOC
  #endif
#endif

/** ============================================================================
 *  @def        __LIBMEMALLOC_REALLOC
 *  @brief      Annotates reallocator functions that may return
 *              a pointer to resized memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((alloc_size(2),
 *              warn_unused_result)) which tells the compiler
 *              that the 3rd parameter specifies the new size
 *              of the allocation and that the return value
 *              should not be ignored. Otherwise, expands to nothing.
 * ========================================================================== */
#ifndef __LIBMEMALLOC_REALLOC
  #if defined(__GNUC__) || defined(__clang__)
    #define __LIBMEMALLOC_REALLOC        \
      __attribute__((malloc,             \
                     alloc_size(2),      \
                     warn_unused_result, \
                     returns_nonnull,    \
                     zero_call_used_regs("all")))
  #else
    #define __LIBMEMALLOC_REALLOC
  #endif
#endif

/** ============================================================================
 *  @def        __LIBMEMALLOC_INTERNAL_REALLOC
 *  @brief      Annotates reallocator functions that may return
 *              a pointer to resized memory.
 *
 *  @details    When supported by the compiler (GCC/Clang),
 *              expands to __attribute__((alloc_size(3),
 *              warn_unused_result)) which tells the compiler
 *              that the 3rd parameter specifies the new size
 *              of the allocation and that the return value
 *              should not be ignored. Otherwise, expands to nothing.
 * ========================================================================== */
#ifndef __LIBMEMALLOC_INTERNAL_REALLOC
  #if defined(__GNUC__) || defined(__clang__)
    #define __LIBMEMALLOC_INTERNAL_REALLOC \
      __attribute__((malloc,               \
                     alloc_size(3),        \
                     warn_unused_result,   \
                     returns_nonnull,      \
                     zero_call_used_regs("all")))
  #else
    #define __LIBMEMALLOC_INTERNAL_REALLOC
  #endif
#endif

/** ============================================================================
 *             	P R I V A T E  B U I L T I N  W R A P P E R S
 * ========================================================================== */

/** ============================================================================
 *  @def        LIKELY(cond_)
 *  @brief      Compiler hint for likely branch prediction.
 *
 *  @param [in] cond_   Condition that is likely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be true.
 * ========================================================================== */
#ifndef LIKELY
  #if (defined(__has_builtin) && __has_builtin(__builtin_expect)) \
    || defined(__GNUC__) || defined(__clang__)
    #define LIKELY(cond_) (__builtin_expect(!!(cond_), 1))
  #else
    #define LIKELY(cond_) (!!(cond_))
  #endif
#endif

/** ============================================================================
 *  @def        UNLIKELY(cond_)
 *  @brief      Compiler hint for unlikely branch prediction.
 *
 *  @param [in] cond_   Condition that is unlikely to be true.
 *
 *  @details    Helps the compiler optimize branch prediction by
 *              indicating the condition is expected to be false.
 * ========================================================================== */
#ifndef UNLIKELY
  #if (defined(__has_builtin) && __has_builtin(__builtin_expect)) \
    || defined(__GNUC__) || defined(__clang__)
    #define UNLIKELY(cond_) (__builtin_expect(!!(cond_), 0))
  #else
    #define UNLIKELY(cond_) (!!(x))
  #endif
#endif

/** ============================================================================
 *  @def        PREFETCH_R(addr_)
 *  @brief      Read prefetch hint.
 *
 *  @param[in]  addr_  Address expected to be read soon (may be NULL).
 *
 *  @details    Wraps __builtin_prefetch when available; otherwise a no-op.
 *              Uses default locality level 1.
 * ========================================================================== */
#ifndef PREFETCH_R
  #if (defined(__has_builtin) && __has_builtin(__builtin_prefetch)) \
    || defined(__GNUC__) || defined(__clang__)
    #define PREFETCH_R(addr_) __builtin_prefetch((addr_), 0, 1)
  #else
    #define PREFETCH_R(addr_) ((void)0)
  #endif
#endif

/** ============================================================================
 *  @def        PREFETCH_W(addr_)
 *  @brief      Write prefetch hint.
 *
 *  @param[in]  addr_  Address expected to be written soon (may be NULL).
 *
 *  @details    Wraps __builtin_prefetch when available; otherwise a no-op.
 *              Uses default locality level 1.
 * ========================================================================== */
#ifndef PREFETCH_W
  #if (defined(__has_builtin) && __has_builtin(__builtin_prefetch)) \
    || defined(__GNUC__) || defined(__clang__)
    #define PREFETCH_W(addr_) __builtin_prefetch((addr_), 1, 1)
  #else
    #define PREFETCH_W(addr_) ((void)0)
  #endif
#endif

/** ============================================================================
 *  @def        ASSUME_ALIGNED(ptr_, align_)
 *  @brief      Tell the compiler the pointer has a fixed alignment.
 *
 *  @param[in]  ptr_     Pointer value.
 *  @param[in]  align_   Alignment in bytes (power of two).
 *
 *  @return     The same pointer, possibly carrying alignment/aliasing info.
 *
 *  @details    Uses __builtin_assume_aligned() when available; otherwise
 *              returns @p ptr unchanged. Passing a wrong alignment is UB.
 * ========================================================================== */
#ifndef ASSUME_ALIGNED
  #if (defined(__has_builtin) && __has_builtin(__builtin_assume_aligned)) \
    || defined(__GNUC__) || defined(__clang__)
    #define ASSUME_ALIGNED(ptr_, align_) \
      __builtin_assume_aligned((ptr_), (align_))
  #else
    #define ASSUME_ALIGNED(ptr_, align_) (align_)
  #endif
#endif

/*< C++ Compatibility >*/
#ifdef __cplusplus
}
#endif

/** @} */

/*< end of header file >*/
