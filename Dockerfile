FROM alpine:3.18 AS builder

LABEL maintainer="Rafael Volkmer <rafael.v.volkmer@gmail.com>"
LABEL version="v4.0.00"
LABEL description="Builder to libmemalloc"

# ------------------------------------------------------------
# Stage 1: Builder
# ------------------------------------------------------------
RUN apk update && \
    apk add --no-cache \
      bash \
      cmake \
      valgrind \
      make \
      musl-dev \
      gcc \
      g++ && \
    rm -rf /var/cache/apk/*

RUN rm -rf /var/cache/apk/*

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app
COPY build.sh CMakeLists.txt ./
COPY src/ src/
COPY inc/ inc/
COPY tests/ tests/

RUN chmod +x build.sh

ARG BUILD_MODE=Release
RUN ./build.sh $BUILD_MODE

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
