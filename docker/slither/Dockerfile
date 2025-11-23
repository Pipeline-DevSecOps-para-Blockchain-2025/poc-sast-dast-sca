# syntax=docker/dockerfile:1

## Builder
FROM docker.io/python:3.14-alpine3.22 AS builder

# General Python build depencies
RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        build-base git \
        ca-certificates openssl-dev \
        libffi-dev python3-dev

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1

# Build Slither wheel from source
ARG SLITHER_VERSION=0.11.3
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    mkdir -p /out/wheels \
    && pip wheel --wheel-dir /out/wheels \
        slither-analyzer=="${SLITHER_VERSION}"

# Download solc binary
ARG SOLC_VERSION=0.8.30
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install --upgrade solc-select \
    && solc-select install "${SOLC_VERSION}" \
    && solc-select use "${SOLC_VERSION}" \
    && mkdir -p /out/bin \
    && install -m 755 "$(command -v solc)" /out/bin/solc

## Runtime
FROM docker.io/python:3.14-alpine3.22 AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>"
LABEL org.opencontainers.image.description="Static analysis tooling for Solidity (Slither)"
LABEL org.opencontainers.image.version="1.0.0"

# Python and Solidity runtime dependencies
RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        ca-certificates openssl \
        gcompat libgcc libstdc++ \
        libffi gmp

# Copy solc binary
COPY --from=builder /out/bin/solc /usr/local/bin/solc

# Install Slither wheel
ENV PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1
RUN --mount=type=bind,from=builder,source=/out/wheels,target=/tmp/wheels \
    pip install --no-cache-dir --no-index \
        --find-links=/tmp/wheels --compile \
        slither-analyzer

# Setup non-root user
RUN addgroup -S slither \
    && adduser -S -h /home -G slither -s /sbin/nologin slither \
    && mkdir -p /home \
    && chown slither:slither /home

USER slither
WORKDIR /slither

# Custom default configuration
COPY --chown=slither:slither --chown=0600 slither.config.json /home/slither.config.json

# Run Slither by default
ENTRYPOINT ["slither", "--config-file", "/home/slither.config.json"]
CMD ["--help"]
