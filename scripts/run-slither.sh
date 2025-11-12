#!/bin/bash
# Simple Slither runner - assumes Docker images are already built

set -e

CONTRACT_NAME="${1:-}"
OUTPUT_DIR="poc-results/slither"

if [ -z "$CONTRACT_NAME" ]; then
    echo "Usage: $0 <contract_name.sol>"
    echo "Available contracts:"
    ls contracts/clean/*.sol 2>/dev/null | xargs -n 1 basename || echo "No contracts found"
    ls contracts/vunerable/*.sol 2>/dev/null | xargs -n 1 basename || echo "No contracts found"
    exit 1
fi

CONTRACT_PATH=$(find contracts -type f -name "$CONTRACT_NAME" | head -n 1 || true)

if [ -z "$CONTRACT_PATH" ]; then
    echo "Contract not found: $CONTRACT_NAME"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

cd docker

OUTPUT_FILE="/poc-results/slither/${CONTRACT_NAME%.sol}_$TIMESTAMP.json"
LOG_FILE="../poc-results/slither/${CONTRACT_NAME%.sol}_$TIMESTAMP.txt"

echo "Analyzing $CONTRACT_NAME..."

docker-compose run --rm slither slither test-contracts/$CONTRACT_NAME --json $OUTPUT_FILE --exclude-dependencies 2>&1 | tee $LOG_FILE

echo "Results: ../poc-results/slither/${CONTRACT_NAME%.sol}_$TIMESTAMP.json"
echo "Log: ../poc-results/slither/${CONTRACT_NAME%.sol}_$TIMESTAMP.txt"

cd ..