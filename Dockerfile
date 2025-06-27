# syntax = docker/dockerfile:1.4

# ------------------------------------------------------------
# Stage 1: Builder (Debian Bookworm-Slim + glibc)
# ------------------------------------------------------------
FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>" \
      version="v4.0.00" \
      description="Builder for libmemalloc"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      cmake \
      valgrind \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup build.sh CMakeLists.txt ./
COPY --chown=appuser:appgroup src/    src/
COPY --chown=appuser:appgroup inc/    inc/
COPY --chown=appuser:appgroup tests/  tests/

RUN chmod +x build.sh

ARG BUILD_MODE=Release
RUN sh -lc "ulimit -d unlimited && ./build.sh \$BUILD_MODE"

# ------------------------------------------------------------
# Stage 2: Runtime (Debian Bookworm-Slim)
# ------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>" \
      version="v4.0.00" \
      description="Runtime for libmemalloc_app"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      libstdc++6 \
      ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# ------------------------------------------------------------
# Stage 3: Copy and Check
# ------------------------------------------------------------
FROM busybox AS export
ARG BUILD_MODE
WORKDIR /out

COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .
