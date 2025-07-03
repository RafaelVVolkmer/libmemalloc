# syntax = docker/dockerfile:1.4

#-------------------------------------------------------------------------------
# BASE
#-------------------------------------------------------------------------------
ARG BASE_IMG=debian:bookworm-slim
ARG EXPORT_IMG=busybox:1.36.1

FROM ${BASE_IMG} AS base

RUN groupadd --system appgroup \
        && useradd  --system --create-home --gid appgroup appuser
 
#-------------------------------------------------------------------------------
# Stage 1: Builder
#-------------------------------------------------------------------------------
FROM base AS builder

LABEL org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
      org.opencontainers.image.description="Builder for libmemalloc"

ARG BUILD_MODE=Release

ENV DEBIAN_FRONTEND=noninteractive \
    BUILD_MODE=${BUILD_MODE} \
    BUILD_DIR=/app/build

RUN rm -f /etc/apt/sources.list.d/* \
        && printf 'deb http://ftp.br.debian.org/debian bookworm main\n\
                deb http://ftp.br.debian.org/debian bookworm-updates main\n\
                deb http://security.debian.org/debian-security bookworm-security main\n' \
                > /etc/apt/sources.list

RUN apt-get update -q \
        && apt-get install -qy --no-install-recommends \
                build-essential \
                cmake \
                git \
                wget \
                ca-certificates \
                valgrind \
                doxygen \
                graphviz \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup CMakeLists.txt    ./
COPY --chown=appuser:appgroup src/              src/
COPY --chown=appuser:appgroup inc/              inc/
COPY --chown=appuser:appgroup tests/            tests/
COPY --chown=appuser:appgroup doxygen/          doxygen/

RUN cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=${BUILD_MODE} \
        && cmake --build "${BUILD_DIR}" --config ${BUILD_MODE} -- -j"$(nproc)" \
        && ctest --test-dir "${BUILD_DIR}" -C ${BUILD_MODE} --output-on-failure --parallel "$(nproc)" \
        && cmake --build "${BUILD_DIR}" --config ${BUILD_MODE} --target doc

#-------------------------------------------------------------------------------
# Stage 2: Runtime
#-------------------------------------------------------------------------------
FROM base AS runtime

LABEL org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
      org.opencontainers.image.description="Runtime for libmemalloc"

ENV PORT=8080
EXPOSE ${PORT}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                libstdc++6 \
                ca-certificates \
                tini \
                curl \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
        
USER appuser
WORKDIR /home/appuser
        
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl --fail http://localhost:${PORT}/healthz || exit 1
        
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/libmemalloc_app"]
CMD ["--help"]

#-------------------------------------------------------------------------------
# Stage 3: Export artifacts
#-------------------------------------------------------------------------------
FROM ${EXPORT_IMG} AS export

LABEL org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
      org.opencontainers.image.description="Export for libmemalloc"

ARG BUILD_MODE=Release

WORKDIR /out

COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .
