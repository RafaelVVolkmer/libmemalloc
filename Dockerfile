# syntax = docker/dockerfile:1.4

#-------------------------------------------------------------------------------
# Stage 1: Builder
#-------------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Builder for libmemalloc"

ARG BUILD_MODE=Release

ENV DEBIAN_FRONTEND=noninteractive \
    BUILD_MODE=${BUILD_MODE} \
    BUILD_DIR=/app/build

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      git \
      wget \
      ca-certificates \
      valgrind \
      doxygen \
      graphviz \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system appgroup \
 && useradd  --system --create-home --gid appgroup appuser

USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup build.sh   CMakeLists.txt ./
COPY --chown=appuser:appgroup src/       src/
COPY --chown=appuser:appgroup inc/       inc/
COPY --chown=appuser:appgroup tests/     tests/
COPY --chown=appuser:appgroup doxygen/  doxygen/

RUN chmod +x build.sh

RUN ulimit -d unlimited \
 && ./build.sh "${BUILD_MODE}"

#-------------------------------------------------------------------------------
# Stage 2: Runtime
#-------------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime
        
LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Runtime for libmemalloc"
        
ENV DEBIAN_FRONTEND=noninteractive
        
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
        libstdc++6 \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*
        

RUN groupadd --system appgroup \
        && useradd --system --no-create-home --gid appgroup appuser
        
USER appuser
WORKDIR /home/appuser
        
 HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
        CMD pgrep libmemalloc_app >/dev/null || exit 1
        
ENTRYPOINT ["/usr/local/bin/libmemalloc_app"]

#-------------------------------------------------------------------------------
# Stage 3: Export artifacts
#-------------------------------------------------------------------------------
FROM busybox:1.36.1 AS export

ARG BUILD_MODE=Release

WORKDIR /out

COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .
