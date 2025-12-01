#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

set -euo pipefail

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
RESET=$'\033[0m'

STD_VERSION="c23"
POSIX_VERSION="200809L"

INCLUDE_DIR="inc"
SOURCE_DIR="src"
TESTS_DIR="tests"

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

echo "==================================================================="
echo " libmemalloc style pipeline"
echo "   - clang-tidy"
echo "   - clang-format"
echo "   - typos (spell checker)"
echo "   - reuse lint (SPDX/REUSE)"
echo "==================================================================="

# ---------------------------------------------------------------------------
# clang-tidy
# ---------------------------------------------------------------------------
echo
echo "[*] Running clang-tidy…"

tidy_log=$(mktemp)

if ! clang-tidy \
  --config-file=.clang-tidy \
  --system-headers \
  --quiet \
  "${SOURCE_DIR}"/*.c "${INCLUDE_DIR}"/*.h "${TESTS_DIR}"/*.c \
  --extra-arg=-Iinc \
  --extra-arg="-std=${STD_VERSION}" \
  --extra-arg="-D_POSIX_C_SOURCE=${POSIX_VERSION}" \
  &> "${tidy_log}"
then
  cat "${tidy_log}"
  echo "${RED}clang-tidy found issues!${RESET}"
  rm -f "${tidy_log}"
  exit 1
fi

rm -f "${tidy_log}"
echo "${GREEN}[OK] clang-tidy checks passed.${RESET}"

# ---------------------------------------------------------------------------
# clang-format
# ---------------------------------------------------------------------------
echo
echo "[*] Running clang-format…"

fmt_log=$(mktemp)

if ! clang-format --dry-run --Werror src/*.c "${INCLUDE_DIR}"/*.h &> "${fmt_log}"
then
  cat "${fmt_log}"
  echo "${RED}Clang-format detected formatting issues!${RESET}"
  rm -f "${fmt_log}"
  exit 1
fi

rm -f "${fmt_log}"
echo "${GREEN}[OK] clang-format style checks passed.${RESET}"

# ---------------------------------------------------------------------------
# typos (spell checker)
# ---------------------------------------------------------------------------
echo
echo "[*] Running typos (spell checker)…"

if ! have_cmd typos; then
  echo "${RED}typos not found in PATH (required for spell checking).${RESET}"
  echo "Make sure it is installed (e.g., 'cargo install typos-cli')."
  exit 1
fi

typos_log=$(mktemp)

# Use typos.toml if present for project-specific configuration
if ! typos . --config ./typos.toml &> "${typos_log}"
then
  cat "${typos_log}"
  echo "${RED}typos detected spelling issues!${RESET}"
  rm -f "${typos_log}"
  exit 1
fi

rm -f "${typos_log}"
echo "${GREEN}[OK] typos spell-check passed.${RESET}"

# ---------------------------------------------------------------------------
# reuse lint (SPDX/REUSE compliance)
# ---------------------------------------------------------------------------
echo
echo "[*] Running REUSE lint (SPDX compliance)…"

if ! have_cmd reuse; then
  echo "${RED}reuse not found in PATH (required for SPDX/REUSE compliance checks).${RESET}"
  echo "Install it with, for example: 'pip install --user reuse'."
  exit 1
fi

if ! reuse lint; then
  echo "${RED}reuse lint reported licensing/SPDX compliance issues!${RESET}"
  exit 1
fi

echo "${GREEN}[OK] REUSE lint: project is compliant with the REUSE Specification.${RESET}"

# ---------------------------------------------------------------------------
# Success
# ---------------------------------------------------------------------------
echo
echo "${GREEN}All style, spelling and REUSE checks passed under ${STD_VERSION} / POSIX ${POSIX_VERSION}!${RESET}"
