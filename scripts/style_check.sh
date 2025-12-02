#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ==============================================================================
# style_check.sh — style/spell/license pipeline for libmemalloc
#
# - Runs clang-tidy on src/, inc/ and tests/
# - Checks formatting with clang-format (dry-run, Werror)
# - Runs typos (spell checker) with project config
# - Runs reuse lint for SPDX/REUSE compliance
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Repository root (independent of where the script is called from)
# ------------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "${REPO_ROOT}"

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'

# ------------------------------------------------------------------------------
# C / POSIX configuration & project layout
# ------------------------------------------------------------------------------
STD_VERSION="c23"
POSIX_VERSION="200809L"

INCLUDE_DIR="inc"
SOURCE_DIR="src"
TESTS_DIR="tests"

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

need_cmd() {
  local cmd="$1" msg="$2"
  if ! have_cmd "$cmd"; then
    echo "${RED}${cmd} not found in PATH (${msg}).${RESET}"
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Banner
# ------------------------------------------------------------------------------
echo "==================================================================="
echo " libmemalloc style pipeline"
echo "   - clang-tidy"
echo "   - clang-format"
echo "   - typos (spell checker)"
echo "   - reuse lint (SPDX/REUSE)"
echo "==================================================================="

# ------------------------------------------------------------------------------
# Tool sanity checks
# ------------------------------------------------------------------------------
need_cmd clang-tidy   "required for static analysis (clang-tidy checks)"
need_cmd clang-format "required for formatting checks (clang-format)"
need_cmd typos        "required for spell checking (typos-cli)"
need_cmd reuse        "required for SPDX/REUSE compliance checks"

# ------------------------------------------------------------------------------
# clang-tidy
# ------------------------------------------------------------------------------
echo
echo "${YELLOW}[*] Running clang-tidy…${RESET}"

tidy_log="$(mktemp)"

if ! clang-tidy \
  --config-file="${REPO_ROOT}/.clang-tidy" \
  --system-headers \
  --quiet \
  "${SOURCE_DIR}"/*.c "${INCLUDE_DIR}"/*.h "${TESTS_DIR}"/*.c \
  --extra-arg="-I${INCLUDE_DIR}" \
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

# ------------------------------------------------------------------------------
# clang-format
# ------------------------------------------------------------------------------
echo
echo "${YELLOW}[*] Running clang-format…${RESET}"

fmt_log="$(mktemp)"

if ! clang-format --dry-run --Werror "${SOURCE_DIR}"/*.c "${INCLUDE_DIR}"/*.h &> "${fmt_log}"
then
  cat "${fmt_log}"
  echo "${RED}clang-format detected formatting issues!${RESET}"
  rm -f "${fmt_log}"
  exit 1
fi

rm -f "${fmt_log}"
echo "${GREEN}[OK] clang-format style checks passed.${RESET}"

# ------------------------------------------------------------------------------
# typos (spell checker)
# ------------------------------------------------------------------------------
echo
echo "${YELLOW}[*] Running typos (spell checker)…${RESET}"

typos_log="$(mktemp)"

if ! typos . --config ./typos.toml &> "${typos_log}"
then
  cat "${typos_log}"
  echo "${RED}typos detected spelling issues!${RESET}"
  rm -f "${typos_log}"
  exit 1
fi

rm -f "${typos_log}"
echo "${GREEN}[OK] typos spell-check passed.${RESET}"

# ------------------------------------------------------------------------------
# reuse lint (SPDX/REUSE compliance)
# ------------------------------------------------------------------------------
echo
echo "${YELLOW}[*] Running REUSE lint (SPDX compliance)…${RESET}"

if ! reuse lint; then
  echo "${RED}reuse lint reported licensing/SPDX compliance issues!${RESET}"
  exit 1
fi

echo "${GREEN}[OK] REUSE lint: project is compliant with the REUSE Specification.${RESET}"

# ------------------------------------------------------------------------------
# Success
# ------------------------------------------------------------------------------
echo
echo "${GREEN}All style, spelling and REUSE checks passed under ${STD_VERSION} / POSIX ${POSIX_VERSION}!${RESET}"
