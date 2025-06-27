# syntax = docker/dockerfile:1.4
ARG BUILD_MODE=Release

#-------------------------------------------------------------------------------
# Stage 1: Builder
#-------------------------------------------------------------------------------
FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Builder for libmemalloc"

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
    && useradd --system --create-home --gid appgroup appuser

USER appuser
WORKDIR /app

COPY --chown=appuser:appgroup build.sh   CMakeLists.txt ./
COPY --chown=appuser:appgroup src/       src/
COPY --chown=appuser:appgroup inc/       inc/
COPY --chown=appuser:appgroup tests/     tests/

RUN chmod +x build.sh \
    && mkdir -p "${BUILD_DIR}" \
    && cd "${BUILD_DIR}" \
    && ulimit -d unlimited \
    && cmake -DCMAKE_BUILD_TYPE=${BUILD_MODE} .. \
    && cmake --build . --config ${BUILD_MODE} \
    && ctest --output-on-failure --config ${BUILD_MODE}

#-------------------------------------------------------------------------------
# Stage 2: Runtime
#-------------------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Runtime for libmemalloc_app"

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

COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc_app /usr/local/bin/

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD pgrep libmemalloc_app >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/libmemalloc_app"]

#-------------------------------------------------------------------------------
# Stage 3: Export artifacts
#-------------------------------------------------------------------------------
FROM busybox AS export

ARG BUILD_MODE
WORKDIR /out

# só copia os dois arquivos de interesse
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.so .
COPY --from=builder /app/bin/${BUILD_MODE}/libmemalloc.a  .
