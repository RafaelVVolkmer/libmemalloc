#!/usr/bin/env bash
set -euo pipefail

# ───────────────────────────────────────────────────────
# 1) Static analysis: clang-tidy
#    - Load naming rules from .clang-tidy
#    - Include system headers in diagnostics
#    - Pass project include path and C23 flags
# ───────────────────────────────────────────────────────
clang-tidy \
  --config-file=.clang-tidy \
  --system-headers \
  -warnings-as-errors=* \
  src/*.c inc/*.h \
  --extra-arg=-Iinc \
  --extra-arg=-std=c23 \
  --extra-arg=-D_POSIX_C_SOURCE=200809L

# ───────────────────────────────────────────────────────
# 2) Formatting check: clang-format (dry run)
#    - Verify that files match .clang-format rules
#    - Exit with error if any diffs are found
# ───────────────────────────────────────────────────────
clang-format --dry-run --Werror src/*.c inc/*.h
