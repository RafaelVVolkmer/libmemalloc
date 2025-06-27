# syntax = docker/dockerfile:1.4

#-------------------------------------------------------------------------------
# Stage 1: Builder
#-------------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>" \
      version="v4.0.00" \
      description="Builder for libmemalloc"

ARG BUILD_MODE=Release

ENV DEBIAN_FRONTEND=noninteractive \
    BUILD_MODE=${BUILD_MODE} \
    BUILD_DIR=/app/build

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      valgrind \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system appgroup \
 && useradd  --system --create-home --gid appgroup appuser

USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup build.sh   CMakeLists.txt ./
COPY --chown=appuser:appgroup src/       src/
COPY --chown=appuser:appgroup inc/       inc/
COPY --chown=appuser:appgroup tests/     tests/

RUN chmod +x build.sh

RUN ulimit -d unlimited \
 && ./build.sh "${BUILD_MODE}"

#-------------------------------------------------------------------------------
# Stage 3: Export artifacts
#-------------------------------------------------------------------------------
FROM busybox AS export

ARG BUILD_MODE=Release

WORKDIR /out

COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .
