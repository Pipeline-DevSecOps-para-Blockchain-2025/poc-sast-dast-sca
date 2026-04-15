# syntax=docker/dockerfile:1

## Builder
FROM docker.io/debian:bookworm-slim AS builder

ARG ADERYN_VERSION=0.6.8

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    <<'EOF'
set -eu
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    xz-utils
EOF

ADD --chmod=0644 \
    https://github.com/Cyfrin/aderyn/releases/download/aderyn-v${ADERYN_VERSION}/aderyn-x86_64-unknown-linux-gnu.tar.xz \
    /tmp/aderyn.tar.xz

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    <<'EOF'
set -eu
mkdir -p /out/bin /out/extract
tar -xJf /tmp/aderyn.tar.xz -C /out/extract --strip-components=1
install -m 755 /out/extract/aderyn /out/bin/aderyn
EOF

## Runtime
FROM docker.io/debian:bookworm-slim AS runtime
LABEL org.opencontainers.image.authors="Eduwilll <eduwill100@gmail.com>; marmitar <tiagodepalves@gmail.com>; MatheusMadureiraa <matheusgmadureira@gmail.com>"
LABEL org.opencontainers.image.description="Static analysis tooling for Solidity (Aderyn)"
LABEL org.opencontainers.image.version="1.0.0"

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    <<'EOF'
set -eu
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates
EOF

COPY --from=builder /out/bin/aderyn /usr/local/bin/aderyn

RUN groupadd -g 1000 aderyn \
    && useradd -u 1000 -g aderyn -d /home/aderyn -m -s /usr/sbin/nologin aderyn

USER aderyn
WORKDIR /aderyn

ENTRYPOINT ["aderyn"]
CMD ["--help"]
