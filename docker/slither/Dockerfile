# syntax=docker/dockerfile:1

## Builder
FROM python:3.14-alpine3.22 AS builder

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        build-base git \
        ca-certificates openssl-dev \
        libffi-dev python3-dev

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1

ARG SLITHER_VERSION=0.11.3
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    mkdir -p /out/wheels \
    && pip wheel --wheel-dir /out/wheels \
        slither-analyzer=="${SLITHER_VERSION}"

ARG SOLC_VERSION=0.8.30
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install --upgrade solc-select \
    && solc-select install "${SOLC_VERSION}" \
    && solc-select use "${SOLC_VERSION}" \
    && mkdir -p /out/bin \
    && install -m 755 "$(command -v solc)" /out/bin/solc

## Runtime
FROM python:3.14-alpine3.22 AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>"
LABEL org.opencontainers.image.description="Static analysis tooling for Solidity (Slither)"
LABEL org.opencontainers.image.version="1.0.0"

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        ca-certificates openssl \
        gcompat libgcc libstdc++ \
        libffi gmp

COPY --from=builder /out/bin/solc /usr/local/bin/solc

ENV PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1
RUN --mount=type=bind,from=builder,source=/out/wheels,target=/tmp/wheels \
    pip install --no-cache-dir --no-index \
        --find-links=/tmp/wheels --compile \
        slither-analyzer

RUN addgroup -S slither \
    && adduser -S -h /home -G slither -s /sbin/nologin slither \
    && mkdir -p /home \
    && chown slither:slither /home

COPY --chown=slither:slither slither.config.json /home/slither.config.json

USER slither
WORKDIR /slither

ENTRYPOINT ["slither", "--config-file", "/home/slither.config.json"]
CMD ["--help"]
