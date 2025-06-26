FROM debian:bookworm-slim AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Builder to libmemalloc"

# ------------------------------------------------------------
# Stage 1: Builder
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      gcc-13 g++-13 \
      cmake \
      valgrind && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100 && \
    rm -rf /var/lib/apt/lists/*

RUN rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY build.sh CMakeLists.txt ./
COPY src/ src/
COPY inc/ inc/
COPY tests/ tests/

RUN chmod +x build.sh

ARG BUILD_MODE=Release
RUN sh -lc "ulimit -d unlimited && ./build.sh $BUILD_MODE"

# ------------------------------------------------------------
# Stage 2: Runtime
# ------------------------------------------------------------
FROM alpine:3.18 AS runtime

RUN apk update \
        && apk add --no-cache libstdc++

RUN rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /home/appuser

COPY --from=builder --chown=appuser:appgroup /app/build/libmemalloc_app \
        /usr/local/bin/libmemalloc_app

USER appuser

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
                CMD pgrep libmemalloc_app >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/libmemalloc_app"]

# ------------------------------------------------------------
# Stage 3: Export
# ------------------------------------------------------------
FROM scratch AS export

COPY --from=builder /app/build /out
