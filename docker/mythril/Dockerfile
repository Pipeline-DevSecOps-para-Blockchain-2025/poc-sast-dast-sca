# syntax=docker/dockerfile:1

## Builder
FROM python:3.14-alpine3.22 AS mythril-builder

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        build-base git \
        ca-certificates openssl-dev \
        libffi-dev python3-dev gmp-dev \
        gcompat libgcc libstdc++

ENV PYTHONUNBUFFERED=1 \
    PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1

ARG MYTHRIL_VERSION=0.24.8
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install --upgrade --compile \
        mythril=="${MYTHRIL_VERSION}" coincurve!=21.0.0 \
    && pip install --force-reinstall --compile 'setuptools<67.5.0'

## Runtime
FROM python:3.14-alpine3.22 AS mythril
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>" 
LABEL org.opencontainers.image.description="Static analysis tooling for EVM bytecode (Mythril)" 
LABEL org.opencontainers.image.version="1.0.0"

RUN --mount=type=cache,id=apk,target=/var/cache/apk \
    apk add --cache-dir=/var/cache/apk \
        ca-certificates openssl \
        gcompat libgcc libstdc++ \
        libffi gmp libgomp

ENV PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1
COPY --from=mythril-builder /usr/local/lib/python3.14/site-packages /usr/local/lib/python3.14/site-packages
COPY --from=mythril-builder /usr/local/bin /usr/local/bin

RUN addgroup -S mythril \
    && adduser -S -h /mythril -G mythril -s /sbin/nologin mythril \
    && mkdir -p /mythril \
    && chown mythril:mythril /mythril

USER mythril
WORKDIR /mythril

ENTRYPOINT ["myth"]
CMD ["--help"]
