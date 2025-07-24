#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="."
BUILD_DIR="./build"
DOCS_DIR="./docs"
DOXYGEN_DIR="./doxygen/doxygen-awesome"
BIN_DIR=""

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

usage() {
    cat <<EOF
Usage: $0 [release|debug] [--docker] [--platform <platform>]
  release       → build Release (default)
  debug         → build Debug
  --docker      → instead of local build, generate Docker image
  --platform    → target platform for Docker buildx (default: linux/amd64)
EOF
    exit 2
}

# defaults
MODE="release"
DOCKER=false
PLATFORMS="linux/amd64"

# parse args
while [ $# -gt 0 ]; do
    case "${1,,}" in
        release|debug)
            MODE="${1,,}"
            shift
            ;;
        --docker)
            DOCKER=true
            shift
            ;;
        --platform)
            if [ -z "${2:-}" ]; then usage; fi
            PLATFORMS="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# map to CMake build type
case "${MODE}" in
    release) BUILD_TYPE="Release" ;;
    debug)   BUILD_TYPE="Debug"   ;;
    *)       usage ;;
esac

BIN_DIR="./bin/${BUILD_TYPE}"

# sanity checks
if $DOCKER; then
    command -v docker >/dev/null 2>&1 || { echo "${RED}Docker not found!${RESET}"; exit 1; }
else
    command -v cmake  >/dev/null 2>&1 || { echo "${RED}CMake not found!${RESET}"; exit 1; }
fi

cleanup() {
    for d in "$BUILD_DIR" "$DOCS_DIR" "$BIN_DIR" "$DOXYGEN_DIR"; do
        if [ -d "$d" ]; then
            sudo rm -rf "$d"
        fi
    done
}

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
        .

    CONTAINER_ID=$(docker create "$IMAGE_TAG")

    # extrai artefatos
    cleanup
    mkdir -p "$BIN_DIR"
    docker cp "$CONTAINER_ID":/out/libmemalloc.so "$BIN_DIR/"
    docker cp "$CONTAINER_ID":/out/libmemalloc.a  "$BIN_DIR/"

    if [ "$BUILD_TYPE" = "Release" ]; then
        docker cp "$CONTAINER_ID":/out/docs "$ROOT_DIR"
    fi

    docker rm -f "$CONTAINER_ID" >/dev/null 2>&1 || true
    # docker rmi -f "$IMAGE_TAG"       >/dev/null 2>&1 || true

else
    echo
    echo "${GREEN}→  Local build (${BUILD_TYPE})${RESET}"
    echo

    cleanup
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ..
    cmake --build . --config "$BUILD_TYPE"
    ctest --output-on-failure -C "$BUILD_TYPE"

    if [ "$BUILD_TYPE" = "Release" ]; then
        echo
        echo "${GREEN}→ Generating Doxygen documentation…${RESET}"
        cmake --build . --config "$BUILD_TYPE" --target doc >/dev/null 2>&1 || true
    fi
fi

echo
echo "${GREEN}✓ Build and testing '${BUILD_TYPE}' completed successfully!${RESET}"
echo "${GREEN}→ Binaries are in: ${BIN_DIR}${RESET}"
if [ "$BUILD_TYPE" = "Release" ]; then
    echo "${GREEN}→ Doxygen docs are in: ${DOCS_DIR}${RESET}"
fi
echo
