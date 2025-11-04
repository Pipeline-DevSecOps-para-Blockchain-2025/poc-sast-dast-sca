#!/bin/bash
# Simple Foundry runner - assumes Docker images are already built

set -e

OUTPUT_DIR="poc-results/foundry"

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

cd docker

OUTPUT_FILE="../poc-results/foundry/foundry_$TIMESTAMP.txt"
GAS_FILE="../poc-results/foundry/gas_$TIMESTAMP.txt"

echo "Running Foundry compilation and tests..."

# Initialize if needed
docker-compose run --rm foundry bash -c "if [ ! -f foundry.toml ]; then forge init --no-git --force .; fi"

# Compile
echo "Compiling contracts..."
docker-compose run --rm foundry forge build 2>&1 | tee $OUTPUT_FILE

# Test with gas report
echo "Running tests with gas report..."
docker-compose run --rm foundry forge test --gas-report 2>&1 | tee $GAS_FILE

echo "Results: ../poc-results/foundry/foundry_$TIMESTAMP.txt"
echo "Gas report: ../poc-results/foundry/gas_$TIMESTAMP.txt"

cd ..