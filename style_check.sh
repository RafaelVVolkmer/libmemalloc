#!/usr/bin/env bash

set -euo pipefail

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

STD_VERSION="c23"
POSIX_VERSION="200809L"

INCLUDE_DIR="inc"
SOURCE_DIR="src"
TESTS_DIR="tests"

tidy_log=$(mktemp)
if ! clang-tidy \
  --config-file=.clang-tidy \
  --system-headers \
  --quiet \
  "${SOURCE_DIR}"/*.c "${INCLUDE_DIR}"/*.h "${TESTS_DIR}"/*.c\
  --extra-arg=-Iinc \
  --extra-arg="-std=${STD_VERSION}" \
  --extra-arg="-D_POSIX_C_SOURCE=${POSIX_VERSION}" \
     &> "${tidy_log}"
then
  cat "${tidy_log}"
  echo "${RED}Clang-tidy found naming errors!${RESET}"
  rm -f "${tidy_log}"
  exit 1
fi

rm -f "${tidy_log}"

fmt_log=$(mktemp)
if ! clang-format --dry-run --Werror src/*.c "${INCLUDE_DIR}"/*.h &> "${fmt_log}"
then
  cat "${fmt_log}"
  echo "${RED}Clang-format detected formatting issues!${RESET}"
  rm -f "${fmt_log}"
  exit 1
fi
rm -f "${fmt_log}"

echo "${GREEN}All style checks passed under ${STD_VERSION} / POSIX ${POSIX_VERSION}!${RESET}" 