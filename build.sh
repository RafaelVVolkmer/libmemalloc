#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="."
BUILD_DIR="./build"
DOCS_DIR="./docs"
DOXYGEN_DIR="./doxygen/doxygen-awesome"

RED=$'\033[31m'
GREEN=$'\033[32m'
RESET=$'\033[0m'

usage()
{
    echo "Use: $0 [release|debug] [--docker]"
    echo "  release      → build Release (default)"
    echo "  debug        → build Debug"
    echo "  --docker     → instead of local build, generate Docker image"
    exit 2
}
[ $# -gt 2 ] && usage

MODE="release"
DOCKER=false

for arg in "$@"; do
    case "${arg,,}" in
        release|debug)
            MODE="${arg,,}"
            ;;
        --docker)
            DOCKER=true
            ;;
        *)
            usage
            ;;
    esac
done

case "${MODE}" in
    release) BUILD_TYPE="Release" ;;
    debug)   BUILD_TYPE="Debug"   ;;
    *)       usage                ;;
esac

BIN_DIR="./bin/$BUILD_TYPE"

if [ "$DOCKER" = true ]; then
  command -v docker >/dev/null || {
    echo "${RED}Docker not found!${RESET}"
    exit 1
  }
elif [ "$DOCKER" = false ]; then
  command -v cmake >/dev/null || {
    echo "${RED}Cmake not found!${RESET}"
    exit 1
  }
else
  echo "${RED}Unexpected DOCKER value: $DOCKER${RESET}"
  exit 1
fi

cleanup()
{
    for dir in "$BUILD_DIR" "$DOCS_DIR" "$BIN_DIR" "$DOXYGEN_DIR"; do
        if [ -d "$dir" ]; then
            sudo rm -rf "$dir"
        fi
    done
}

if [ "$DOCKER" = true ]; then
    echo
    echo "${GREEN}→  Build Docker - mode: $BUILD_TYPE.${RESET}"
    echo

    IMAGE_TAG="libmemalloc:${BUILD_TYPE,,}"

    if [ "$BUILD_TYPE" = "Release" ]; then
      TARGET="docs-export"
    else
      TARGET="export"
    fi

    docker build \
      --build-arg BUILD_MODE="$BUILD_TYPE" \
      --target "$TARGET" \
      --tag "$IMAGE_TAG" \
      .

    CONTAINER_ID=$(docker create "$IMAGE_TAG")

    cleanup

    mkdir -p "$BIN_DIR"
    docker cp "$CONTAINER_ID":/out/libmemalloc.so "$BIN_DIR"
    docker cp "$CONTAINER_ID":/out/libmemalloc.a  "$BIN_DIR"

    if [ "$BUILD_TYPE" = "Release" ]; then
      docker cp "$CONTAINER_ID":/out/docs "$ROOT_DIR"
    fi

    docker rm -f "$CONTAINER_ID" 2>/dev/null || true
    docker rmi -f "$IMAGE_TAG" 2>/dev/null || true
else
    echo
    echo "${GREEN}→  Build local - mode: $BUILD_TYPE.${RESET}"
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
        cmake --build . --config "$BUILD_TYPE" --target doc \
            > /dev/null 2>&1 || true
    fi
fi

echo
echo "${GREEN}✓ Build and testing '$BUILD_TYPE' completed successfully!${RESET}"
echo "${GREEN}→ Binaries (.a .so) are in: "$BIN_DIR" !${RESET}"
if [ "$BUILD_TYPE" = "Release" ]; then
  echo "${GREEN}→ Doxygen docs are in: "$DOCS_DIR" !${RESET}"
fi
echo
