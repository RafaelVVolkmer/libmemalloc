#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ==============================================================================
# build.sh — one-touch build/test/docs helper
#
# - Local or Docker build (Release/Debug)
# - Runs CTest
# - Generates Doxygen site (quiet by default) and moves it to ./docs
# - Quiet mode only for the Doxygen step (toggle with --verbose)
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Absolute paths (independent of where the script is called from)
# ------------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BUILD_DIR="${REPO_ROOT}/build"
DOCS_DIR="${REPO_ROOT}/docs"
DOXYGEN_DIR="${REPO_ROOT}/doxygen/doxygen-awesome"
BIN_DIR=""

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RESET=$'\033[0m'

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 [release|debug] [--docker] [--platform <platform>] [--clear] [--verbose|-v]
  release       Build Release (default)
  debug         Build Debug
  --docker      Build with Docker instead of locally
  --platform    Platforms for Docker buildx (default: linux/amd64)
  --clear       Remove ./bin ./build ./docs ./doxygen/doxygen-awesome and exit
  --verbose,-v  Show full Doxygen output (otherwise only Doxygen is silenced)
EOF
  exit 2
}

# ------------------------------------------------------------------------------
# Defaults & arg parsing
# ------------------------------------------------------------------------------
MODE="release"
DOCKER=false
PLATFORMS="linux/amd64"
CLEAR=false
VERBOSE=false
DOC_LOG=""

while [ $# -gt 0 ]; do
  case "${1,,}" in
    release|debug) MODE="${1,,}"; shift;;
    --docker)      DOCKER=true; shift;;
    --platform)    [ -n "${2:-}" ] || usage; PLATFORMS="$2"; shift 2;;
    --clear)       CLEAR=true; shift;;
    --verbose|-v)  VERBOSE=true; shift;;
    *)             usage;;
  esac
done

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------
clear_all() {
  echo "${GREEN}→ Clearing ${REPO_ROOT}/{bin,build,docs,doxygen/doxygen-awesome} …${RESET}"
  sudo rm -rf "${REPO_ROOT}/bin" "${BUILD_DIR}" "${DOCS_DIR}" "${DOXYGEN_DIR}" || true
  echo "${GREEN}✓ Clear completed${RESET}"
}

cleanup() {
  sudo rm -rf "${BUILD_DIR}" "${DOCS_DIR}" "${BIN_DIR}" "${DOXYGEN_DIR}" || true
}

copy_tree() {
  local src="$1" dst="$2"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "${src%/}/" "${dst%/}/"
  else
    mkdir -p "${dst}"
    # shellcheck disable=SC2115
    rm -rf "${dst:?}/"* || true
    cp -a "${src%/}/." "${dst%/}/"
  fi
}

run_doxygen_step() {
  local cmd=( "$@" )
  if $VERBOSE; then
    "${cmd[@]}"
  else
    DOC_LOG="${BUILD_DIR}/doc.log"
    : > "$DOC_LOG"
    # If a Doxyfile is already present, force QUIET=YES
    if [ -f "${BUILD_DIR}/Doxyfile" ]; then
      sed -i 's/^\s*QUIET\s*=.*/QUIET = YES/' "${BUILD_DIR}/Doxyfile" || true
    fi
    if ! "${cmd[@]}" >"$DOC_LOG" 2>&1; then
      echo "${RED}✗ Doxygen failed (quiet). See ${DOC_LOG}${RESET}"
      tail -n 40 "$DOC_LOG" || true
      return 1
    fi
  fi
}

# ------------------------------------------------------------------------------
# Short-circuit: --clear
# ------------------------------------------------------------------------------
$CLEAR && { clear_all; exit 0; }

# ------------------------------------------------------------------------------
# Tool sanity checks
# ------------------------------------------------------------------------------
BUILD_TYPE=$([ "${MODE}" = "release" ] && echo "Release" || echo "Debug")
BIN_DIR="${REPO_ROOT}/bin/${BUILD_TYPE}"

if $DOCKER; then
  command -v docker >/dev/null 2>&1 || { echo "${RED}Docker not found!${RESET}"; exit 1; }
else
  command -v cmake  >/dev/null 2>&1 || { echo "${RED}CMake not found!${RESET}"; exit 1; }
fi

# ------------------------------------------------------------------------------
# Docker build path
# ------------------------------------------------------------------------------
if $DOCKER; then
  echo
  echo "${GREEN}→  Build Docker image (${BUILD_TYPE}) for ${PLATFORMS}${RESET}"
  echo

  IMAGE_TAG="libmemalloc:${BUILD_TYPE,,}"
  TARGET=$([ "$BUILD_TYPE" = "Release" ] && echo "docs-export" || echo "export")

  docker buildx create --use --name multiarch-builder >/dev/null 2>&1 || true
  docker buildx inspect --bootstrap

  if echo "$PLATFORMS" | grep -q "linux/riscv64"; then
    BASE_ARG="debian:trixie-slim"
  elif echo "$PLATFORMS" | grep -q "linux/loong64"; then
    BASE_ARG="loongarch64/debian-base-loong64:bullseye-v1.4.3"
  elif echo "$PLATFORMS" | grep -q "linux/mips64"; then
    BASE_ARG="polyarch/debian-ports:latest-linux-mips64le"
  elif echo "$PLATFORMS" | grep -q "linux/mips64le"; then
    BASE_ARG="debian:bookworm-slim"
  else
    BASE_ARG="debian:bookworm-slim"
  fi

  docker buildx build \
    --build-arg BUILD_MODE="$BUILD_TYPE" \
    --target "$TARGET" \
    --build-arg BASE_IMG="$BASE_ARG" \
    --platform "$PLATFORMS" \
    --load \
    --tag "$IMAGE_TAG" \
    "$REPO_ROOT"

  CONTAINER_ID=$(docker create "$IMAGE_TAG")

  cleanup
  mkdir -p "$BIN_DIR"
  docker cp "$CONTAINER_ID":/out/libmemalloc.so "$BIN_DIR/" || true
  docker cp "$CONTAINER_ID":/out/libmemalloc.a  "$BIN_DIR/" || true

  if [ "$BUILD_TYPE" = "Release" ]; then
    docker cp "$CONTAINER_ID":/out/docs "$REPO_ROOT" || true
  fi

  docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# Local build path
# ------------------------------------------------------------------------------
else
  echo
  echo "${GREEN}→  Local build (${BUILD_TYPE})${RESET}"
  echo

  cleanup
  mkdir -p "${BUILD_DIR}"

	cmake -S "${REPO_ROOT}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
	cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}"

	if $VERBOSE; then
		ctest --test-dir "${BUILD_DIR}" --output-on-failure -C "${BUILD_TYPE}" -LE coverage
		ctest --test-dir "${BUILD_DIR}" --output-on-failure -C "${BUILD_TYPE}" -L coverage
	else
		ctest --test-dir "${BUILD_DIR}" --output-on-failure -C "${BUILD_TYPE}" -LE coverage || exit $?
		ctest --test-dir "${BUILD_DIR}" -C "${BUILD_TYPE}" -L coverage -Q
	fi

  if [ "${BUILD_TYPE}" = "Release" ]; then
    echo -e "\n${GREEN}→ Generating Doxygen documentation…${RESET}"
    run_doxygen_step cmake --build "${BUILD_DIR}" --config "${BUILD_TYPE}" --target doc

    if [ ! -f "${DOXYGEN_DIR}/html/index.html" ]; then
      echo "${RED}✗ Doxygen did not produce ${DOXYGEN_DIR}/html/index.html${RESET}"
      $VERBOSE || { echo "  See ${BUILD_DIR}/doc.log or run with --verbose"; }
      echo "  doxygen ${BUILD_DIR}/Doxyfile"
      exit 1
    fi

    echo -e "${GREEN}→ Moving Doxygen site to ${DOCS_DIR} …${RESET}"
    mkdir -p "${DOCS_DIR}"
    copy_tree "${DOXYGEN_DIR}" "${DOCS_DIR}"
    # optional: remove the theme folder after copy
    rm -rf "${DOXYGEN_DIR}" || true

    echo "${GREEN}✓ Site moved to ${DOCS_DIR}${RESET}"
  fi
fi

# ------------------------------------------------------------------------------
# Final summary
# ------------------------------------------------------------------------------
echo
echo "${GREEN}✓ Build and testing '${BUILD_TYPE}' completed successfully!${RESET}"
echo "${GREEN}→ Binaries are in: ${BIN_DIR}${RESET}"
[ "${BUILD_TYPE}" = "Release" ] && echo "${GREEN}→ Doxygen docs are in: ${DOCS_DIR}${RESET}"
echo
