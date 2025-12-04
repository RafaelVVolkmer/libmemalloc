# syntax=docker/dockerfile:1.4

# SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
# SPDX-License-Identifier: MIT

# ---------------------------------------------------------------------------
# Base image (used as foundation for builder / runtime stages)
# ---------------------------------------------------------------------------
ARG BASE_IMG=debian:bookworm-slim

FROM ${BASE_IMG} AS base

ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILD_MODE=Release

ENV BUILDPLATFORM=${BUILDPLATFORM}
ENV TARGETPLATFORM=${TARGETPLATFORM}

ENV DEBIAN_FRONTEND=noninteractive

# Create dedicated unprivileged user/group (UID/GID can be overridden at build time)
ARG APP_UID=1000
ARG APP_GID=1000
RUN set -eux; \
    groupadd --system --gid "${APP_GID}" appgroup; \
    useradd  --system --create-home --uid "${APP_UID}" --gid appgroup appuser

# ---------------------------------------------------------------------------
# Stage 1: Builder (build, test, docs, coverage)
# ---------------------------------------------------------------------------
FROM base AS builder

ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILD_MODE=Release

LABEL org.opencontainers.image.title="libmemalloc (builder)" \
      org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
			org.opencontainers.image.url="https://github.com/RafaelVVolkmer/libmemalloc" \
      org.opencontainers.image.description="Builder image for libmemalloc" \
      org.opencontainers.image.licenses="MIT"

ENV BUILD_MODE=${BUILD_MODE} \
    BUILD_DIR=/app/build

# Install build / docs / coverage tools
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eux; \
    apt-get update -q; \
    pkgs="build-essential git wget ca-certificates cmake gcovr doxygen graphviz"; \
    # Valgrind is only needed on native architectures where tests really run
    if [ "${TARGETARCH}" = "amd64" ] || [ "${TARGETARCH}" = "arm64" ]; then \
      pkgs="${pkgs} valgrind"; \
    fi; \
    apt-get install -qy --no-install-recommends ${pkgs}; \
    rm -rf /var/lib/apt/lists/*

USER appuser
WORKDIR /app

# Keep COPY steps separate to maximize cache reuse when only sources change
COPY --chown=appuser:appgroup CMakeLists.txt  ./
COPY --chown=appuser:appgroup libmemalloc.map ./
COPY --chown=appuser:appgroup src/            src/
COPY --chown=appuser:appgroup inc/            inc/
COPY --chown=appuser:appgroup tests/          tests/
COPY --chown=appuser:appgroup doxygen/        doxygen/
COPY --chown=appuser:appgroup readme/         readme/

RUN cmake -S . -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_MODE}" \
 && cmake --build "${BUILD_DIR}" --config "${BUILD_MODE}" -- -j"$(nproc)" \
 && ctest --test-dir "${BUILD_DIR}" -C "${BUILD_MODE}" \
          --output-on-failure --parallel "$(nproc)" \
 && if [ "${BUILD_MODE}" = "Release" ]; then \
      cmake --build "${BUILD_DIR}" --config "${BUILD_MODE}" --target doc; \
    fi

# ---------------------------------------------------------------------------
# Stage 2: Runtime (if a future CLI/server uses libmemalloc)
# ---------------------------------------------------------------------------
FROM base AS runtime

LABEL org.opencontainers.image.title="libmemalloc (runtime)" \
      org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
			org.opencontainers.image.url="https://github.com/RafaelVVolkmer/libmemalloc" \
      org.opencontainers.image.description="Runtime image for libmemalloc" \
      org.opencontainers.image.licenses="MIT"

ENV PORT=8080
EXPOSE ${PORT}

# Install only the minimal runtime dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    set -eux; \
    apt-get update -q; \
    apt-get install -qy --no-install-recommends \
      libstdc++6 \
      ca-certificates \
      tini \
      curl; \
    rm -rf /var/lib/apt/lists/*

USER appuser
WORKDIR /home/appuser

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD curl --fail "http://localhost:${PORT}/healthz" || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/libmemalloc_app"]
CMD ["--help"]

# ---------------------------------------------------------------------------
# Stage 3: Export artifacts (pure artifacts image for build scripts)
# ---------------------------------------------------------------------------
FROM scratch AS export

LABEL org.opencontainers.image.title="libmemalloc (artifacts)" \
      org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
			org.opencontainers.image.url="https://github.com/RafaelVVolkmer/libmemalloc" \
      org.opencontainers.image.description="Exported libmemalloc artifacts (static/shared)" \
      org.opencontainers.image.licenses="MIT"

ARG BUILD_MODE=Release

WORKDIR /out

# Export only the compiled libraries
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .

CMD ["true"]

# ---------------------------------------------------------------------------
# Stage 4: Export artifacts + docs (used by build.sh --docker Release)
# ---------------------------------------------------------------------------
FROM scratch AS docs-export

LABEL org.opencontainers.image.title="libmemalloc (artifacts + docs)" \
      org.opencontainers.image.authors="Rafael V. Volkmer <rafael.v.volkmer@gmail.com>" \
      org.opencontainers.image.version="v4.0.00" \
			org.opencontainers.image.url="https://github.com/RafaelVVolkmer/libmemalloc" \
      org.opencontainers.image.description="Exported libmemalloc artifacts with Doxygen site" \
      org.opencontainers.image.licenses="MIT"

ARG BUILD_MODE=Release

WORKDIR /out

# Export libraries
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .

# Export full Doxygen site (including coverage/ if generated)
COPY --from=builder /app/doxygen/doxygen-awesome/html/ docs/html/

# Export project logo used by the site
COPY --from=builder /app/readme/libmemalloc.svg         docs/html/

CMD ["true"]
