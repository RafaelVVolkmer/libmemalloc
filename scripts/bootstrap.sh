#!/usr/bin/env bash

# ==============================================================================
# bootstrap.sh — one-touch dev environment helper for libmemalloc
#
# - Detects OS (Linux/macOS) and package manager (apt/dnf/pacman/brew)
# - Checks versions of core tools (cmake, gcc/gcov, clang, valgrind, docker…)
# - Checks for Rust toolchain (rustc, cargo) and typos (spell checker)
# - Checks for GitHub CLI (gh) used by repo automation scripts
# - If something is missing or too old, tries to install/upgrade it
# - At the end, prints a concise summary of detected versions
#
# Usage:
#   ./scripts/bootstrap.sh [--check-only]
#
#   --check-only  Only check tools/versions, do not install anything
#
# SPDX-License-Identifier: MIT
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Absolute paths (independent of where the script is called from)
# ------------------------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
RESET=$'\033[0m'

# ------------------------------------------------------------------------------
# Usage
# ------------------------------------------------------------------------------
usage() {
  cat <<EOF
Usage: $0 [--check-only]

  --check-only   Only check tools and versions, do not install anything.

This script is intended to prepare a development environment for libmemalloc.

Supported:
  - Linux: apt (Debian/Ubuntu), dnf (Fedora/RHEL), pacman (Arch/Manjaro)
  - macOS: Homebrew (Docker must be installed manually)

It checks for and optionally installs:
  - C/C++ toolchain: cmake, ninja, gcc/gcov, clang, valgrind, docker
  - Rust toolchain: rustc, cargo
  - Spell checker: typos (installed via 'cargo install typos-cli')
  - GitHub CLI: gh (used by scripts like scripts/labels.sh)
EOF
  exit 2
}

# ------------------------------------------------------------------------------
# Defaults & arg parsing
# ------------------------------------------------------------------------------
CHECK_ONLY=false

while [ $# -gt 0 ]; do
  case "${1,,}" in
    --check-only) CHECK_ONLY=true; shift;;
    -h|--help)    usage;;
    *)            usage;;
  esac
done

# ------------------------------------------------------------------------------
# Minimum versions (adjust as needed)
# ------------------------------------------------------------------------------
MIN_CMAKE="3.20.0"
MIN_GCC="10.0.0"
MIN_CLANG="14.0.0"
MIN_VALGRIND="3.18.0"
MIN_DOCKER="20.10.0"
MIN_RUSTC="1.80.0"
MIN_CARGO="1.80.0"
# typos and gh are required for full tooling, but we don't enforce a specific
# minimum version here.

# ------------------------------------------------------------------------------
# Package lists (per package manager)
# ------------------------------------------------------------------------------
# Debian/Ubuntu
APT_PACKAGES=(
  cmake
  ninja-build
  gcc
  g++
  clang
  clang-tidy
  clang-format
  doxygen
  graphviz
  git
  valgrind
  docker.io
  rustc
  cargo
  gh
)

# Fedora / RHEL
DNF_PACKAGES=(
  cmake
  ninja-build
  gcc
  gcc-c++
  clang
  clang-tools-extra
  doxygen
  graphviz
  git
  valgrind
  docker
  rust
  cargo
  gh
)

# Arch / Manjaro
PACMAN_PACKAGES=(
  cmake
  ninja
  gcc
  clang
  doxygen
  graphviz
  git
  valgrind
  docker
  rust
  cargo
  github-cli
)

# ------------------------------------------------------------------------------
# Utility helpers
# ------------------------------------------------------------------------------
have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

# Return 0 if $1 >= $2 (version-wise), else 1
ver_ge() {
  local current="$1"
  local min="$2"

  # sort -V sorts versions naturally (e.g. 3.9 < 3.20)
  local smallest
  smallest="$(printf '%s\n' "$current" "$min" | sort -V | head -n1)"

  [[ "$smallest" == "$min" ]]
}

# Global flag to track if everything is OK
ALL_OK=1

check_version() {
  local name="$1"
  local min="$2"
  local current="$3"

  if [[ -z "$current" ]]; then
    echo "${RED}[-] $name: not found or could not detect version${RESET}"
    ALL_OK=0
    return 1
  fi

  if ver_ge "$current" "$min"; then
    echo "${GREEN}[+] $name $current (>= $min)${RESET}"
    return 0
  else
    echo "${YELLOW}[!] $name $current (< $min, require >= $min)${RESET}"
    ALL_OK=0
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Version checks for each tool
# ------------------------------------------------------------------------------
check_all_versions() {
  ALL_OK=1

  echo "${BLUE}=== Checking tool versions ===${RESET}"

  # CMake
  if have_cmd cmake; then
    local cmake_ver
    cmake_ver="$(cmake --version | head -n1 | awk '{print $3}')"
    check_version "cmake" "$MIN_CMAKE" "$cmake_ver"
  else
    echo "${RED}[-] cmake: not installed${RESET}"
    ALL_OK=0
  fi

  # GCC / gcov
  if have_cmd gcc; then
    local gcc_ver
    gcc_ver="$(gcc -dumpfullversion -dumpversion 2>/dev/null || gcc -dumpversion)"
    check_version "gcc" "$MIN_GCC" "$gcc_ver"
  else
    echo "${RED}[-] gcc: not installed${RESET}"
    ALL_OK=0
  fi

  if have_cmd gcov; then
    local gcov_ver
    gcov_ver="$(gcov --version | head -n1 | awk '{print $NF}')"
    check_version "gcov" "$MIN_GCC" "$gcov_ver"
  else
    echo "${RED}[-] gcov: not installed (usually comes with gcc)${RESET}"
    ALL_OK=0
  fi

  # Clang (try clang, then clang-XX fallback)
  local clang_cmd="clang"
  if ! have_cmd "$clang_cmd"; then
    clang_cmd=""
    # Try some common versioned clang binaries (newest first)
    for c in clang-19 clang-18 clang-17 clang-16 clang-15 clang-14; do
      if have_cmd "$c"; then
        clang_cmd="$c"
        break
      fi
    done
  fi

  if [[ -n "$clang_cmd" ]] && have_cmd "$clang_cmd"; then
    local clang_ver
    # Examples:
    #   Ubuntu clang version 18.1.3-1ubuntu1
    #   clang version 17.0.0
    clang_ver="$("$clang_cmd" --version | head -n1 | sed -E 's/.*clang version ([0-9.]+).*/\1/')"
    check_version "clang" "$MIN_CLANG" "$clang_ver"
  else
    echo "${RED}[-] clang: not installed${RESET}"
    ALL_OK=0
  fi

  # clang-tidy
  if have_cmd clang-tidy; then
    local tidy_ver
    tidy_ver="$(clang-tidy --version | head -n1 | awk '{print $NF}')"
    check_version "clang-tidy" "$MIN_CLANG" "$tidy_ver"
  else
    echo "${RED}[-] clang-tidy: not installed (or named clang-tidy-XX)${RESET}"
    ALL_OK=0
  fi

  # clang-format
  if have_cmd clang-format; then
    local format_ver
    format_ver="$(clang-format --version | awk '{print $NF}')"
    check_version "clang-format" "$MIN_CLANG" "$format_ver"
  else
    echo "${RED}[-] clang-format: not installed (or named clang-format-XX)${RESET}"
    ALL_OK=0
  fi

  # Doxygen
  if have_cmd doxygen; then
    local doxygen_ver
    doxygen_ver="$(doxygen --version 2>/dev/null || true)"
    [[ -z "$doxygen_ver" ]] && doxygen_ver="unknown"
    echo "${GREEN}[+] doxygen $doxygen_ver${RESET}"
  else
    echo "${RED}[-] doxygen: not installed${RESET}"
    ALL_OK=0
  fi

  # Graphviz (dot)
  if have_cmd dot; then
    local dot_ver
    dot_ver="$(dot -V 2>&1 | awk '{print $5}' | tr -d '()')"
    [[ -z "$dot_ver" ]] && dot_ver="unknown"
    echo "${GREEN}[+] graphviz (dot) $dot_ver${RESET}"
  else
    echo "${RED}[-] graphviz (dot): not installed${RESET}"
    ALL_OK=0
  fi

  # Git
  if have_cmd git; then
    local git_ver
    git_ver="$(git --version | awk '{print $3}')"
    echo "${GREEN}[+] git $git_ver${RESET}"
  else
    echo "${RED}[-] git: not installed${RESET}"
    ALL_OK=0
  fi

  # GitHub CLI (optional but recommended)
  if have_cmd gh; then
    local gh_ver
    # Example: gh version 2.61.0 (2024-10-01)
    gh_ver="$(gh --version | head -n1 | awk '{print $3}')"
    [[ -z "$gh_ver" ]] && gh_ver="unknown"
    echo "${GREEN}[+] gh $gh_ver (GitHub CLI)${RESET}"
  else
    echo "${YELLOW}[!] gh (GitHub CLI) not installed — scripts/labels.sh and other GitHub automation will be unavailable${RESET}"
    # NOTE: we intentionally do NOT flip ALL_OK here; gh is recommended, not mandatory.
  fi

  # Valgrind
  if have_cmd valgrind; then
    local valgrind_ver_raw
    local valgrind_ver
    # Example: "valgrind-3.23.0" or "valgrind-3.21.0.GIT"
    valgrind_ver_raw="$(valgrind --version 2>/dev/null || true)"
    valgrind_ver="$(printf '%s\n' "$valgrind_ver_raw" | sed -E 's/.*valgrind-([0-9.]+).*/\1/')"
    check_version "valgrind" "$MIN_VALGRIND" "$valgrind_ver"
  else
    echo "${RED}[-] valgrind: not installed${RESET}"
    ALL_OK=0
  fi

  # Docker
  if have_cmd docker; then
    local docker_ver
    docker_ver="$(docker --version | awk '{print $3}' | tr -d ',')"
    check_version "docker" "$MIN_DOCKER" "$docker_ver"

    if [[ "${DOCKER_BUILDKIT:-0}" != "1" ]]; then
      echo "${YELLOW}[!] DOCKER_BUILDKIT is not enabled (export DOCKER_BUILDKIT=1 for BuildKit-based builds)${RESET}"
      ALL_OK=0
    else
      echo "${GREEN}[+] DOCKER_BUILDKIT=1${RESET}"
    fi
  else
    echo "${RED}[-] docker: not installed${RESET}"
    ALL_OK=0
  fi

  # Rust (rustc)
  if have_cmd rustc; then
    local rustc_ver
    rustc_ver="$(rustc --version | awk '{print $2}')"
    check_version "rustc" "$MIN_RUSTC" "$rustc_ver"
  else
    echo "${RED}[-] rustc: not installed${RESET}"
    ALL_OK=0
  fi

  # Cargo
  if have_cmd cargo; then
    local cargo_ver
    cargo_ver="$(cargo --version | awk '{print $2}')"
    check_version "cargo" "$MIN_CARGO" "$cargo_ver"
  else
    echo "${RED}[-] cargo: not installed${RESET}"
    ALL_OK=0
  fi

  # typos (spell checker) — required for style pipeline
  if have_cmd typos; then
    local typos_ver
    typos_ver="$(typos --version 2>/dev/null | awk '{print $2}')"
    [[ -z "$typos_ver" ]] && typos_ver="unknown"
    echo "${GREEN}[+] typos $typos_ver${RESET}"
  else
    echo "${RED}[-] typos: not installed (required for spell checking and style checks)${RESET}"
    ALL_OK=0
  fi

  echo "${BLUE}=== Version check complete ===${RESET}"
}

# ------------------------------------------------------------------------------
# Install helpers per package manager
# ------------------------------------------------------------------------------
install_apt() {
  echo "${GREEN}→ Using apt (Debian/Ubuntu)…${RESET}"
  sudo apt-get update
  sudo apt-get install -y "${APT_PACKAGES[@]}"
}

install_dnf() {
  echo "${GREEN}→ Using dnf (Fedora/RHEL)…${RESET}"
  sudo dnf install -y "${DNF_PACKAGES[@]}"
}

install_pacman() {
  echo "${GREEN}→ Using pacman (Arch/Manjaro)…${RESET}"
  sudo pacman -Syu --needed "${PACMAN_PACKAGES[@]}"
}

install_brew() {
  echo "${GREEN}→ Using Homebrew (macOS)…${RESET}"
  brew update
  # llvm brings clang/clang-tidy/clang-format; rust includes cargo
  brew install cmake ninja llvm doxygen graphviz git valgrind rust gh || true

  echo "${YELLOW}[!] Docker is not installed automatically on macOS.${RESET}"
  echo "${YELLOW}    Please install Docker Desktop manually from https://www.docker.com/ if you need docker/buildkit.${RESET}"
}

detect_linux_distro_and_install() {
  if have_cmd apt-get; then
    install_apt
  elif have_cmd dnf; then
    install_dnf
  elif have_cmd pacman; then
    install_pacman
  else
    echo "${RED}Unsupported Linux distribution (no apt, dnf or pacman found).${RESET}"
    echo "Please install the following tools manually:"
    printf '  %s\n' "cmake, ninja, gcc, g++, clang, clang-tidy, clang-format, doxygen, graphviz, git, gh, valgrind, docker, rustc, cargo, typos"
    exit 1
  fi
}

# ------------------------------------------------------------------------------
# Install typos via cargo (required)
# ------------------------------------------------------------------------------
install_typos_with_cargo() {
  # If typos is already present, nothing to do.
  if have_cmd typos; then
    echo "${GREEN}[+] typos already installed.${RESET}"
    return 0
  fi

  # Without cargo we cannot install typos.
  if ! have_cmd cargo; then
    echo "${RED}[-] cargo not found; cannot install typos.${RESET}"
    echo "    Rust and cargo are required to build and run the spell checker."
    ALL_OK=0
    return 1
  fi

  echo "${GREEN}→ Installing typos (spell checker) via cargo…${RESET}"
  # Use a version compatible with older rustc toolchains (e.g., 1.80+)
  if cargo install typos-cli --version 1.39.0; then
    echo "${GREEN}[+] typos successfully installed.${RESET}"
  else
    echo "${RED}[-] Failed to install typos via cargo (typos-cli 1.39.0).${RESET}"
    echo "    Please check your Rust toolchain and try manually with:"
    echo "      cargo install typos-cli --version 1.39.0"
    ALL_OK=0
    return 1
  fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
  echo
  echo "${BLUE}======================================================================${RESET}"
  echo "${GREEN}libmemalloc bootstrap — dependency setup${RESET}"
  echo "${BLUE}======================================================================${RESET}"
  echo "  Repo root: ${REPO_ROOT}"
  echo

  echo "${GREEN}→ Step 1: Checking current toolchain…${RESET}"
  check_all_versions

  if [[ "$ALL_OK" -eq 1 ]]; then
    echo
    echo "${GREEN}✓ All required tools are present with acceptable versions.${RESET}"
    echo "${GREEN}→ You can now build libmemalloc:${RESET}"
    echo "   ./build.sh debug   # or: ./build.sh release"
    exit 0
  fi

  if $CHECK_ONLY; then
    echo
    echo "${YELLOW}Some tools are missing or below the minimum required version.${RESET}"
    echo "${YELLOW}--check-only is set, so no installation was attempted.${RESET}"
    exit 1
  fi

  echo
  echo "${YELLOW}Some tools are missing or outdated.${RESET}"
  echo "${GREEN}→ Step 2: Attempting to install/upgrade dependencies…${RESET}"
  echo

  local uname_out
  uname_out="$(uname -s)"

  case "$uname_out" in
    Linux*)
      echo "${GREEN}Detected Linux.${RESET}"
      detect_linux_distro_and_install
      ;;
    Darwin*)
      echo "${GREEN}Detected macOS.${RESET}"
      if ! have_cmd brew; then
        echo "${RED}Homebrew not found. Install it from https://brew.sh/ and re-run this script.${RESET}"
        exit 1
      fi
      install_brew
      ;;
    *)
      echo "${RED}Unsupported OS: $uname_out${RESET}"
      echo "Please install the required tools manually."
      exit 1
      ;;
  esac

  echo
  echo "${GREEN}→ Step 3: Ensuring typos (spell checker) is available…${RESET}"
  install_typos_with_cargo

  echo
  echo "${GREEN}→ Step 4: Re-checking toolchain after installation…${RESET}"
  check_all_versions

  if [[ "$ALL_OK" -eq 1 ]]; then
    echo
    echo "${GREEN}✓ Environment looks good. You can now build libmemalloc:${RESET}"
    echo "   ./build.sh debug   # or: ./build.sh release"
  else
    echo
    echo "${RED}Some tools are still missing or below required versions.${RESET}"
    echo "Please review the messages above and install/upgrade them manually."
    exit 1
  fi
}

main "$@"
