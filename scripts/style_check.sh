#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

set -euo pipefail

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

STD_VERSION="c23"
POSIX_VERSION="200809L"

INCLUDE_DIR="inc"
SOURCE_DIR="src"
TESTS_DIR="tests"

# ---------------------------------------------------------------------------
# clang-tidy
# ---------------------------------------------------------------------------
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
  echo "${RED}Clang-tidy found naming or style errors!${RESET}"
  rm -f "${tidy_log}"
  exit 1
fi
rm -f "${tidy_log}"

# ---------------------------------------------------------------------------
# clang-format
# ---------------------------------------------------------------------------
fmt_log=$(mktemp)
if ! clang-format --dry-run --Werror "${SOURCE_DIR}"/*.c "${INCLUDE_DIR}"/*.h &> "${fmt_log}"
then
  cat "${fmt_log}"
  echo "${RED}Clang-format detected formatting issues!${RESET}"
  rm -f "${fmt_log}"
  exit 1
fi
rm -f "${fmt_log}"

# ---------------------------------------------------------------------------
# typos (spell checker)
# ---------------------------------------------------------------------------
typos_log=$(mktemp)
if ! command -v typos >/dev/null 2>&1; then
  echo "${RED}typos: command not found. Install it (cargo install typos-cli) to run spell checks.${RESET}"
  rm -f "${typos_log}"
  exit 1
fi

if ! typos &> "${typos_log}"; then
  cat "${typos_log}"
  echo "${RED}typos detected spelling issues!${RESET}"
  rm -f "${typos_log}"
  exit 1
fi
rm -f "${typos_log}"

echo "${GREEN}All style checks (clang-tidy, clang-format, typos) passed under ${STD_VERSION} / POSIX ${POSIX_VERSION}!${RESET}"
