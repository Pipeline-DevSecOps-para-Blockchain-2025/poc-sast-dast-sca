# syntax=docker/dockerfile:1

## Builder
FROM docker.io/debian:bookworm-slim AS builder

ARG ADERYN_VERSION=0.6.8

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        tar \
    && rm -rf /var/lib/apt/lists/*

RUN arch="$(dpkg --print-architecture)" \
    && case "$arch" in \
        amd64) target='x86_64-unknown-linux-gnu' ;; \
        arm64) target='aarch64-unknown-linux-gnu' ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac \
    && url="https://github.com/Cyfrin/aderyn/releases/download/aderyn-v${ADERYN_VERSION}/aderyn-${target}.tar.xz" \
    && mkdir -p /out/bin \
    && curl -fsSL "$url" -o /tmp/aderyn.tar.xz \
    && tar -xJf /tmp/aderyn.tar.xz -C /out/bin aderyn

## Runtime
FROM docker.io/alpine:3.23 AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>; MatheusMadureiraa <matheusgmadureira@gmail.com>"
LABEL org.opencontainers.image.description="Static analysis tooling for Solidity (Aderyn)"
LABEL org.opencontainers.image.version="1.0.0"

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        ca-certificates \
        libgcc \
        libstdc++

COPY --from=builder /out/bin/aderyn /usr/local/bin/aderyn

RUN addgroup -g 1000 -S aderyn \
    && adduser -u 1000 -S -h /home/aderyn -G aderyn -s /sbin/nologin aderyn \
    && mkdir -p /home/aderyn \
    && chown aderyn:aderyn /home/aderyn

USER aderyn
WORKDIR /aderyn

ENTRYPOINT ["aderyn"]
CMD ["--help"]
