#!/bin/bash
# Simple Echidna runner - assumes Docker images are already built

set -e

CONTRACT_NAME="${1:-}"
OUTPUT_DIR="poc-results/echidna"

if [ -z "$CONTRACT_NAME" ]; then
    echo "Usage: $0 <contract_name.sol>"
    echo "Available contracts:"
    ls poc-workspace/test-contracts/*.sol 2>/dev/null | xargs -n 1 basename || echo "No contracts found"
    exit 1
fi

if [ ! -f "poc-workspace/test-contracts/$CONTRACT_NAME" ]; then
    echo "Contract not found: $CONTRACT_NAME"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

cd docker

OUTPUT_FILE="../poc-results/echidna/${CONTRACT_NAME%.sol}_$TIMESTAMP.txt"
CORPUS_DIR="../poc-results/echidna/corpus_${CONTRACT_NAME%.sol}_$TIMESTAMP"

echo "Fuzzing $CONTRACT_NAME with Echidna..."

mkdir -p "$CORPUS_DIR"
docker-compose run --rm echidna bash -c "echidna-test test-contracts/$CONTRACT_NAME --config /home/pocuser/.echidna/echidna.config.yaml" 2>&1 | tee $OUTPUT_FILE

echo "Results: ../poc-results/echidna/${CONTRACT_NAME%.sol}_$TIMESTAMP.txt"

cd ..