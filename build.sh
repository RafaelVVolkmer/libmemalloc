#!/usr/bin/env bash

set -euo pipefail

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
            rm -rf "$dir"
        fi
    done

    mkdir -p "$BUILD_DIR"
}

if [ "$DOCKER" = true ]; then
    echo
    echo "${GREEN}→  Build Docker - mode: $BUILD_TYPE.${RESET}"
    echo

    IMAGE_TAG="libmemalloc:${BUILD_TYPE,,}"

    docker build \
      --build-arg BUILD_MODE="$BUILD_TYPE" \
      --tag "$IMAGE_TAG" \
      .

    CONTAINER_ID=$(docker create "$IMAGE_TAG")

    mkdir -p ./bin/"$BUILD_TYPE"
    docker cp "$CONTAINER_ID":/out/. ./bin/"$BUILD_TYPE"/

    docker rm "$CONTAINER_ID"
    docker rmi "$IMAGE_TAG"
else
    echo
    echo "${GREEN}→  Build local - mode: $BUILD_TYPE.${RESET}"
    echo

    cleanup

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
echo "${GREEN}✓ Build and testing '$BUILD_TYPE' completed successfully.${RESET}"
echo "${GREEN}→ Binaries (.a .so) are in ./bin/$BUILD_TYPE.${RESET}"
echo
