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
