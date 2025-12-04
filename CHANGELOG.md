<!--
SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
SPDX-License-Identifier: MIT
-->

# Changelog

All notable changes to this project will be documented in this file.

The format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(adapted to the `vX.Y.ZZ` scheme used by the project).

## [Unreleased]

### Added
- _(to be filled for the next release)_

### Changed
- _(to be filled for the next release)_

### Fixed
- _(to be filled for the next release)_

---

## [3.0.00] – 2025-12-04

### Added
- **Complete build pipeline overhaul**  
  - Added `CMakePresets.json` for multi-toolchain workflows.  
  - Added coverage, sanitizer, QEMU/emulation-aware configurations.  
  - Added unified test harness with wrappers and coverage backends.  
  - Added compiler/arch hardening flags (CET, BTI, MTE, MEMTAG, FORTIFY, IPO).  
- **Full Docker security and multi-arch tooling**  
  - Introduced `docker-check.sh` with SAFE MODE:  
    - Hadolint  
    - Trivy (config + image scan)  
    - Syft (CycloneDX SBOM generation)  
    - Grype (vuln scanning from SBOM)  
    - Dockle (CIS benchmark)  
    - Dive (layer efficiency)  
    - Cosign (sign/verify support)  
  - Added tool configuration files:  
    `.hadolint.yaml`, `trivy.yaml`, `.trivyignore`, `syft.yaml`, `grype.yaml`, `dockle.toml`.  
  - Added Docker cleanup utilities and multi-stage fixes.  
- **Repository governance & tooling improvements**  
  - Added SPDX headers across the project and full REUSE compliance via `REUSE.toml`.  
  - Added spell-check tooling (`typos`) and integrated into style pipeline.  
  - Added local git hooks for commit/merge/push validation.  
  - Added CODEOWNERS, issue/PR templates, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`.  
  - Added `CITATION.cff` metadata for academic indexing.  
- **Documentation improvements**  
  - Overhauled Doxygen configuration with multi-format output.  
  - Added coverage pill support and modularized theme configuration.  
  - Updated README to reflect new workflows.

### Changed
- **Reorganized Docker directory structure** into `~/docker/` and updated `build.sh` to reference the new layout.  
- **Modernized CMake structure**:  
  - Unified build summary output, improved diagnostics, cleaned version guards.  
  - Updated minimum required versions for core modules.  
  - Improved install/export logic with version scripts.  
- **Allocator correctness refactors**:  
  - Improved free-list behavior, correct wraparound logic in NEXT_FIT.  
  - More robust merge/split paths with better canary re-arm behavior.  
  - Improved alignment handling and use of PREFETCH + ASSUME_ALIGNED hints.  
  - Clarified internal header layouts and reduced UB in pointer arithmetic.  
- **Improved logging, error messages, and summary output** across scripts and CMake.

### Fixed
- Fixed multi-stage Dockerfile issues, including scratch export and docs build steps.  
- Fixed robustness of allocator block merging, splitting, and shrink conditions.  
- Fixed incorrect PREFETCH multiplier for `ARCH_ALIGNMENT == 1`.  
- Fixed free-list handling to avoid double insertion/removal churn.  
- Fixed next-fit block selection when wrapping to first user block.  
- Fixed UB in block size computations during split.  
- Fixed Valgrind, gcovr, llvm-cov version detection issues.  
- Fixed mismatched formatting, typos, and SPDX inconsistencies across the project.

### Tooling / CI
- Fully modernized CI workflows with multi-arch Docker builds, style checks, REUSE verification, and typos spell-checking.  
- Updated pipeline to run on `main` + `develop`.  
- Added pre-push, pre-merge, and pre-commit hooks for enforceable developer hygiene.

---

## [2.0.00] – 2025-09-28

### Added
- Hardened block validation gates to detect and reject corrupt or implausible headers.
- Clear distinction between real corruption (logged as **ERROR**) and “not a memalloc block” cases (logged as **WARNING**).
- Portable performance helpers: `PREFETCH_R/W`, `ASSUME_ALIGNED`, `LIKELY/UNLIKELY` with safe fallbacks across compilers.

### Changed
- Improved heap shrinking logic: only shrink when the free block fully spans the last `sbrk` lease and `sbrk(0)` matches the tracked heap end.
- Tail-shrinking now restores the free block if the shrink operation fails, preventing accidental leaks.
- NEXT_FIT strategy now wraps to the first **user** block, not allocator metadata, reducing fragmentation edge cases.

### Fixed
- More robust free-list merge/split paths, avoiding double remove/insert issues.
- Trailing canary computation now uses `sizeof(uintptr_t)`, fixing layout issues on some architectures.
- Corrected `ARCH_ALIGNMENT == 1` path, including `PREFETCH_MULT` definition and layout assumptions.
- Various robustness fixes across allocation/free paths, improving safety under heavy stress and fuzzing.

### Tooling / Docs
- New `--clear` build flag to wipe artifacts (`bin/`, `build/`, `docs/`).
- Vendored Doxygen theme excluded from version control.
- Documentation updated to reflect the hardened allocator behavior.

---

## [1.0.00] – 2025-08-23

### Added
- Initial public release of **libmemalloc**:
  - Multiple allocation strategies: `FIRST_FIT`, `NEXT_FIT`, `BEST_FIT`.
  - Segregated free lists for O(1) operations on small blocks.
  - Large-block allocation via `mmap` (for blocks ≥ 128 KiB).
  - Heap growth/shrink management via `sbrk` for regular blocks.
  - Optional background mark-and-sweep garbage collector (runtime configurable).
  - Header magic and footer canaries for detecting corruption and overflows.
  - Internal locking for thread safety.
  - Configurable logging levels (ERROR/WARN/INFO/DEBUG).
  - Valgrind MemPool annotations for precise leak reporting.

### Notes
- This release establishes the core API surface of libmemalloc and sets the baseline
  for future compatibility and hardening improvements.

---
