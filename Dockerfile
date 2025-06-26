# ------------------------------------------------------------
# Stage 1: Builder (Debian w/ GCC-13 via backports)
# ------------------------------------------------------------
FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Builder for libmemalloc"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
 && echo 'deb http://deb.debian.org/debian bookworm-backports main' \
      > /etc/apt/sources.list.d/backports.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      gcc-13 \
      g++-13 \
      cmake \
      valgrind \
      libvalgrind-dev \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 \
 && rm -rf /var/lib/apt/lists/*

# Cria user/group no Debian
RUN groupadd --system appgroup \
 && useradd  --system --gid appgroup appuser

WORKDIR /app
COPY --chown=appuser:appgroup build.sh CMakeLists.txt ./
COPY --chown=appuser:appgroup src/ src/
COPY --chown=appuser:appgroup inc/ inc/
COPY --chown=appuser:appgroup tests/ tests/

RUN chmod +x build.sh
ARG BUILD_MODE=Release
# ulimit só no builder, para os testes
RUN sh -lc "ulimit -d unlimited && ./build.sh ${BUILD_MODE}"

# ------------------------------------------------------------
# Stage 2: Runtime
# ------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

RUN apt-get update \
 && apt-get install -y --no-install-recommends libstdc++ \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --system appgroup \
 && useradd  --system --gid appgroup appuser

WORKDIR /home/appuser
COPY --from=builder --chown=appuser:appgroup /app/build/libmemalloc_app \
     /usr/local/bin/libmemalloc_app

USER appuser
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD pgrep libmemalloc_app >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/libmemalloc_app"]

# ------------------------------------------------------------
# Stage 3: Export (opcional)
# ------------------------------------------------------------
FROM scratch AS export
COPY --from=builder /app/build /out
