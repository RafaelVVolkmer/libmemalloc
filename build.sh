#!/usr/bin/env bash
set -x
set -euo pipefail

BUILD_DIR="build"

usage() {
    echo "Uso: $0 [release|debug]"
    echo "  release  → build Release (default)"
    echo "  debug    → build Debug"
    exit 1
}

if [ $# -eq 0 ]; then
    MODE="release"
elif [ $# -eq 1 ]; then
    MODE="$1"
else
    usage
fi

case "${MODE,,}" in
    release)
        BUILD_TYPE="Release"
        ;;
    debug)
        BUILD_TYPE="Debug"
        ;;
    *)
        usage
        ;;
esac

if [ ! -d "$BUILD_DIR" ]; then
    mkdir "$BUILD_DIR"
fi

cd "$BUILD_DIR"

cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" ..

cmake --build . --config "$BUILD_TYPE"

ctest --output-on-failure "$BUILD_TYPE"

echo
echo "Build and tests '$BUILD_TYPE' with success."
