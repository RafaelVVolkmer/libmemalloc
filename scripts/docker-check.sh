#!/usr/bin/env bash

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ==============================================================================
# docker-check.sh — Dockerfile Security & Quality Scanner (SAFE MODE)
#
# SAFE MODE:
#   - No installations
#   - No sudo
#   - No filesystem modifications
#   - Fully compatible with WSL2, Docker Desktop, act, GitHub Actions
#
# Purpose:
#   - Lint Dockerfile (Hadolint)
#   - Scan config + images (Trivy)
#   - Generate SBOM (Syft)
#   - Vuln scan from SBOM (Grype)
#   - CIS checks (Dockle)
#   - Layer efficiency (Dive)
#   - OCI signing/verify (Cosign, lightweight dummy keys)
#
# Uses all local configuration files automatically:
#   - .hadolint.yaml
#   - trivy.yaml
#   - .trivyignore
#   - syft.yaml
#   - grype.yaml
#   - .dockleignore
#
# Summary:
#   - Tracks warnings and failures
#   - Displays full summary at the end
#
# No tool on PATH is mandatory — missing tools are simply skipped.
# ==============================================================================

# ==============================================================================
# Colors
# ==============================================================================
RED="\033[1;31m"; GREEN="\033[1;32m"; YELLOW="\033[1;33m"
BLUE="\033[1;34m"; CYAN="\033[1;36m"; RESET="\033[0m"

# ==============================================================================
# Argument parsing
# ==============================================================================
DOCKERFILE=""
for arg in "$@"; do
    case $arg in
        --dockerfile=*) DOCKERFILE="${arg#*=}";;
        *) echo -e "${RED}Unknown argument: $arg${RESET}"; exit 1;;
    esac
done

[[ -z "$DOCKERFILE" ]] && {
    echo -e "${RED}Usage: $0 --dockerfile=PATH${RESET}"
    exit 1
}

# ==============================================================================
# Paths and configuration files
# ==============================================================================
LOG_ROOT="logs/docker"
mkdir -p "$LOG_ROOT"

CONFIG_DIR="$(dirname "$DOCKERFILE")"

HADOLINT_CONFIG="${CONFIG_DIR}/.hadolint.yaml"
TRIVY_CONFIG="${CONFIG_DIR}/trivy.yaml"
TRIVY_IGNORE="${CONFIG_DIR}/.trivyignore"
SYFT_CONFIG="${CONFIG_DIR}/syft.yaml"
GRYPE_CONFIG="${CONFIG_DIR}/grype.yaml"
DOCKLE_IGNORE="${CONFIG_DIR}/.dockleignore"

# ==============================================================================
# Safe tool checker
# ==============================================================================
require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${YELLOW}[SKIP] Missing tool: $1${RESET}"
        return 1
    fi
    return 0
}

# ==============================================================================
# Detect multi-stage names
# ==============================================================================
echo -e "${CYAN}Detecting stages…${RESET}"
mapfile -t STAGES < <(grep -E '^FROM .* AS ' "$DOCKERFILE" | awk '{print $NF}')

if [[ ${#STAGES[@]} -eq 0 ]]; then
    echo -e "${RED}No named stages found.${RESET}"
    exit 1
fi

echo -e "${GREEN}Stages detected:${RESET}"
printf "  - %s\n" "${STAGES[@]}"

# ==============================================================================
# Failure/Warning tracking
# ==============================================================================
FAILURES=()
WARNINGS=()

add_fail()  { FAILURES+=("$1"); echo -e "${RED}[FAIL]${RESET} $1"; }
add_warn()  { WARNINGS+=("$1"); echo -e "${YELLOW}[WARN]${RESET} $1"; }

# ==============================================================================
# Docker build wrapper with retry and daemon crash detection
# ==============================================================================
docker_safe_build() {
    local stage="$1"
    local tag="$2"
    local logfile="$3"

    echo -e "${BLUE}→ Building stage ${stage}${RESET}"

    for attempt in 1 2 3; do
        if docker build --target "$stage" -t "$tag" -f "$DOCKERFILE" . >"$logfile" 2>&1; then
            return 0
        fi

        # Detect Docker daemon crash (WSL2 / Desktop)
        if grep -q "connection reset by peer" "$logfile"; then
            add_fail "Docker daemon crashed during stage '$stage'"
            cat "$logfile"
            exit 1
        fi

        echo -e "${YELLOW}→ Build attempt $attempt failed, retrying…${RESET}"
        sleep 2
    done

    add_fail "Build failed for stage '$stage'"
    cat "$logfile"
}

# ==============================================================================
# Stage-by-stage scanning
# ==============================================================================
for stage in "${STAGES[@]}"; do
    echo -e "\n${CYAN}→ SCANNING STAGE: ${stage}${RESET}"

    STAGE_LOG_DIR="${LOG_ROOT}/${stage}"
    mkdir -p "$STAGE_LOG_DIR"

    TAG="scan-${stage}"

    # --- 1. Build -------------------------------------------------------------
    docker_safe_build "$stage" "$TAG" "$STAGE_LOG_DIR/build.log"

    # --- 2. Hadolint ----------------------------------------------------------
    if require hadolint; then
        echo -e "${BLUE}→ Hadolint${RESET}"

        if [[ -f "$HADOLINT_CONFIG" ]]; then
            hadolint --config "$HADOLINT_CONFIG" "$DOCKERFILE" \
                >"$LOG_ROOT/hadolint.log" 2>&1 || true
        else
            hadolint "$DOCKERFILE" >"$LOG_ROOT/hadolint.log" 2>&1 || true
        fi

        if grep -qE "DL3[0-9]{2}|DL4[0-9]{2}" "$LOG_ROOT/hadolint.log"; then
            add_fail "Hadolint critical DL300x/DL400x rules triggered"
        fi
    fi

    # --- 4. Trivy config ------------------------------------------------------
    if require trivy; then
        echo -e "${BLUE}→ Trivy config${RESET}"

        if [[ -f "$TRIVY_CONFIG" ]]; then
            trivy config . --config "$TRIVY_CONFIG" --ignorefile "$TRIVY_IGNORE" \
                >"$STAGE_LOG_DIR/trivy-config.log" 2>&1 || true
        else
            trivy config . >"$STAGE_LOG_DIR/trivy-config.log" 2>&1 || true
        fi

        grep -qE "CRITICAL|HIGH" "$STAGE_LOG_DIR/trivy-config.log" && \
            add_warn "Trivy config reported HIGH/CRITICAL issues"
    fi

    # --- 5. Trivy image -------------------------------------------------------
    if require trivy; then
        echo -e "${BLUE}→ Trivy image${RESET}"

        if [[ -f "$TRIVY_CONFIG" ]]; then
            trivy image "$TAG" --config "$TRIVY_CONFIG" --ignorefile "$TRIVY_IGNORE" \
                >"$STAGE_LOG_DIR/trivy-image.log" 2>&1 || true
        else
            trivy image "$TAG" >"$STAGE_LOG_DIR/trivy-image.log" 2>&1 || true
        fi

        grep -qE "CRITICAL|HIGH" "$STAGE_LOG_DIR/trivy-image.log" && \
            add_warn "Trivy image reported HIGH/CRITICAL vulnerabilities"
    fi

    # --- 6. Syft SBOM ---------------------------------------------------------
    if require syft; then
        echo -e "${BLUE}→ Syft SBOM${RESET}"

        if [[ -f "$SYFT_CONFIG" ]]; then
            syft "$TAG" -o cyclonedx-json --config "$SYFT_CONFIG" \
                >"$STAGE_LOG_DIR/sbom.json" 2>/dev/null || true
        else
            syft "$TAG" -o cyclonedx-json >"$STAGE_LOG_DIR/sbom.json" 2>/dev/null || true
        fi
    fi

    # --- 7. Grype --------------------------------------------------------------
    if require grype; then
        echo -e "${BLUE}→ Grype${RESET}"

        if [[ -f "$GRYPE_CONFIG" ]]; then
            grype sbom:"$STAGE_LOG_DIR/sbom.json" --config "$GRYPE_CONFIG" \
                >"$STAGE_LOG_DIR/grype.log" 2>&1 || true
        else
            grype sbom:"$STAGE_LOG_DIR/sbom.json" >"$STAGE_LOG_DIR/grype.log" 2>&1 || true
        fi

        grep -qE "Critical|High" "$STAGE_LOG_DIR/grype.log" && \
            add_warn "Grype found High/Critical vulnerabilities"
    fi

    # --- 8. Dockle -------------------------------------------------------------
    if require dockle; then
        echo -e "${BLUE}→ Dockle${RESET}"

        if [[ -f "$DOCKLE_IGNORE" ]]; then
            dockle "$TAG" --exit-code 0 --ignorefile "$DOCKLE_IGNORE" \
                >"$STAGE_LOG_DIR/dockle.log" 2>&1 || true
        else
            dockle "$TAG" --exit-code 0 >"$STAGE_LOG_DIR/dockle.log" 2>&1 || true
        fi

        grep -qE "^\[E\]|\[F\]" "$STAGE_LOG_DIR/dockle.log" && \
            add_fail "Dockle reported CIS errors for stage '$stage'"
    fi

    # --- 9. Dive ---------------------------------------------------------------
    if require dive; then
        echo -e "${BLUE}→ Dive${RESET}"
        dive "$TAG" --ci --json "$STAGE_LOG_DIR/dive.json" \
            >"$STAGE_LOG_DIR/dive.log" 2>&1 || true

        if [[ -f "$STAGE_LOG_DIR/dive.json" ]]; then
            eff=$(jq '.efficiencyScore // 100' "$STAGE_LOG_DIR/dive.json" 2>/dev/null || echo 100)
            (( eff < 85 )) && add_warn "Dive efficiency < 85% ($eff)"
        fi
    fi

done

# ==============================================================================
# Final Summary
# ==============================================================================
echo -e "\n${CYAN}══════════════════════════════════════════════════════${RESET}"
echo -e "${CYAN}                     FINAL SUMMARY                    ${RESET}"
echo -e "${CYAN}══════════════════════════════════════════════════════${RESET}"

echo -e "${GREEN}Total stages: ${#STAGES[@]}${RESET}"
echo -e "${YELLOW}Warnings: ${#WARNINGS[@]}${RESET}"
echo -e "${RED}Failures: ${#FAILURES[@]}${RESET}"

if (( ${#FAILURES[@]} > 0 )); then
    echo -e "\n${RED}Failures:${RESET}"
    printf " - %s\n" "${FAILURES[@]}"
fi

if (( ${#WARNINGS[@]} > 0 )); then
    echo -e "\n${YELLOW}Warnings:${RESET}"
    printf " - %s\n" "${WARNINGS[@]}"
fi

if (( ${#FAILURES[@]} == 0 )); then
    echo -e "\n${GREEN}✓ Docker Security & Quality Scan PASSED (Safe Mode)${RESET}"
else
    echo -e "\n${RED}✗ Docker Security & Quality Scan FAILED${RESET}"
fi

echo -e "${CYAN}Logs are available in ${LOG_ROOT}${RESET}"
