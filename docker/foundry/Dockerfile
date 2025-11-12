# syntax=docker/dockerfile:1

## Builder
FROM rust:alpine3.22 AS builder

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        build-base git ca-certificates \
        linux-headers libusb-dev

ARG FOUNDRY_VERSION=1.4.4
RUN --mount=type=cache,id=cargo-registry,target=/usr/local/cargo/registry \
    --mount=type=cache,id=cargo-git,target=/usr/local/cargo/git \
    cargo install --force --profile release --locked \
        --git https://github.com/foundry-rs/foundry --tag "v${FOUNDRY_VERSION}" \
        forge cast chisel anvil

## Runtime
FROM alpine:3.22 AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>"
LABEL org.opencontainers.image.description="Blazing fast smart contract development toolkit (used for DAST/SCA)"
LABEL org.opencontainers.image.version="1.0.0"

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        ca-certificates

COPY --from=builder /usr/local/cargo/bin /usr/local/bin

RUN addgroup -S foundry \
    && adduser -S -h /home -G foundry -s /sbin/nologin foundry \
    && mkdir -p /home \
    && chown foundry:foundry /home

USER foundry
WORKDIR /foundry

ENTRYPOINT []
CMD ["forge", "--help"]
