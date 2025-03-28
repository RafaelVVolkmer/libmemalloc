FROM alpine:latest AS builder

RUN apk add --no-cache cmake build-base

WORKDIR /src

COPY . .

RUN mkdir build && cd build && cmake -DCMAKE_BUILD_TYPE=Release .. && make

FROM alpine:latest

WORKDIR /bin

COPY --from=builder /src/build/*.a ./
COPY --from=builder /src/build/*.o ./
COPY --from=builder /src/build/*.so ./

CMD ["/bin/sh"]
