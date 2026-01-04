#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ==============================================================================
# docker-clean.sh — full Docker cleanup helper
#
# - Stops and removes ALL containers (running or exited)
# - Removes ALL images (dangling + unused)
# - Removes orphan volumes
# - Removes unused networks
# - Removes buildx builders and cache
# - Removes tonistiigi/binfmt (multi-arch emulation layer)
# - Provides clear, colored, structured output
#
# Use this script to fully reset Docker after ACT, buildx, multiarch builds,
# corrupted cache, or zombie containers.
# ==============================================================================

set -euo pipefail

# ------------------------------------------------------------------------------
# Colors
# ------------------------------------------------------------------------------
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
RESET=$'\033[0m'

# ------------------------------------------------------------------------------
# Formatting helpers
# ------------------------------------------------------------------------------
banner() {
  echo -e "\n${BLUE}=====================================================================${RESET}"
  echo -e "${GREEN}$1${RESET}"
  echo -e "${BLUE}=====================================================================${RESET}"
}

section() {
  echo -e "\n${YELLOW}→ $1${RESET}"
}

ok() {
  echo -e "${GREEN}✓ $1${RESET}"
}

warn() {
  echo -e "${YELLOW}! $1${RESET}"
}

err() {
  echo -e "${RED}✗ $1${RESET}"
}

# ------------------------------------------------------------------------------
# Intro
# ------------------------------------------------------------------------------
banner "Docker Cleanup — Full System Reset"

# ------------------------------------------------------------------------------
# Stop all running containers
# ------------------------------------------------------------------------------
section "Stopping running containers"
if docker ps -q | grep -q .; then
  docker stop $(docker ps -q) >/dev/null 2>&1 || warn "Some containers could not be stopped"
  ok "Running containers stopped"
else
  warn "No running containers found"
fi

# ------------------------------------------------------------------------------
# Remove all containers
# ------------------------------------------------------------------------------
section "Removing all containers"
if docker ps -aq | grep -q .; then
  docker rm -f $(docker ps -aq) >/dev/null 2>&1 || warn "Some containers could not be removed"
  ok "All containers removed"
else
  warn "No containers to remove"
fi

# ------------------------------------------------------------------------------
# Remove all images
# ------------------------------------------------------------------------------
section "Removing all Docker images"
docker image prune -a -f >/dev/null 2>&1 || warn "Failed to remove some images"
ok "All images removed"

# ------------------------------------------------------------------------------
# Remove orphan volumes
# ------------------------------------------------------------------------------
section "Removing orphan volumes"
docker volume prune -f >/dev/null 2>&1 || warn "Failed to remove some volumes"
ok "Volumes cleaned"

# ------------------------------------------------------------------------------
# Remove unused networks
# ------------------------------------------------------------------------------
section "Removing unused networks"
docker network prune -f >/dev/null 2>&1 || warn "Failed to remove some networks"
ok "Networks cleaned"

# ------------------------------------------------------------------------------
# Remove buildx builders
# ------------------------------------------------------------------------------
section "Removing Docker buildx builders"

if docker buildx ls >/dev/null 2>&1; then
  # Remove inactive builders first
  docker buildx rm --all-inactive >/dev/null 2>&1 || true

  # Remove remaining (non-default) builders
  while read -r builder; do
    [ -z "$builder" ] && continue
    if [[ "$builder" != "default" ]]; then
      docker buildx rm "$builder" >/dev/null 2>&1 || true
    fi
  done < <(docker buildx ls --format '{{ .Name }}')
  ok "Buildx builders removed"
else
  warn "Buildx is not configured"
fi

# ------------------------------------------------------------------------------
# Remove tonistiigi/binfmt containers (multiarch emulation)
# ------------------------------------------------------------------------------
section "Removing binfmt (multiarch emulation layer)"

if docker ps -a | grep -q "tonistiigi/binfmt"; then
  docker ps -a | grep "tonistiigi/binfmt" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1
  ok "binfmt containers removed"
else
  warn "No binfmt containers found"
fi

# ------------------------------------------------------------------------------
# Clean builder cache
# ------------------------------------------------------------------------------
section "Cleaning Docker builder cache"
docker builder prune -a -f >/dev/null 2>&1 || warn "Failed to prune builder cache"
ok "Builder cache cleaned"

# ------------------------------------------------------------------------------
# Final summary
# ------------------------------------------------------------------------------
banner "Docker cleanup completed successfully!"
echo -e "${GREEN}Your Docker environment is now fully reset and clean.${RESET}\n"
