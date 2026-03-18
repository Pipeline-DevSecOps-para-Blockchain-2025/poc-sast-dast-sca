# syntax=docker/dockerfile:1

## Runtime
FROM docker.io/mythril/myth AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>"
LABEL org.opencontainers.image.description="Static analysis tooling for EVM bytecode (Mythril)"
LABEL org.opencontainers.image.version="1.0.0"

# Use root temporarily
USER root
ENV PIP_ROOT_USER_ACTION=ignore PIP_DISABLE_PIP_VERSION_CHECK=1

# Remap upstream mythril user/group to 1000:1000 and fix home directory
RUN groupmod -g 1000 mythril \
    && usermod -u 1000 -d /home/mythril mythril \
    && mkdir -p /home/mythril \
    && chown -R mythril:mythril /home/mythril

# Download newer solc binary
ARG SOLC_VERSION=0.8.30
RUN --mount=type=cache,id=pip,target=/root/.cache/pip \
    pip install --upgrade solc-select \
    && solc-select install "${SOLC_VERSION}" \
    && solc-select use "${SOLC_VERSION}"

# Setup non-root user
USER mythril
