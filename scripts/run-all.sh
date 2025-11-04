#!/bin/bash
# Run all security tools on all contracts

set -e

echo "Running all security tools..."

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "poc-results/run_$TIMESTAMP"

# Get available contracts
CONTRACTS=($(ls poc-workspace/test-contracts/*.sol 2>/dev/null | xargs -n 1 basename))

if [ ${#CONTRACTS[@]} -eq 0 ]; then
    echo "No contracts found in poc-workspace/test-contracts/"
    exit 1
fi

echo "Found ${#CONTRACTS[@]} contracts: ${CONTRACTS[*]}"

# Run Slither on each contract
echo "Running Slither..."
for contract in "${CONTRACTS[@]}"; do
    echo "  Analyzing $contract"
    ./scripts/run-slither.sh "$contract" || echo "  Failed: $contract"
done

# Run Mythril on each contract  
echo "Running Mythril..."
for contract in "${CONTRACTS[@]}"; do
    echo "  Analyzing $contract"
    ./scripts/run-mythril.sh "$contract" || echo "  Failed: $contract"
done

# Run Echidna on each contract
echo "Running Echidna..."
for contract in "${CONTRACTS[@]}"; do
    echo "  Fuzzing $contract"
    ./scripts/run-echidna.sh "$contract" || echo "  Failed: $contract"
done

# Run Foundry once
echo "Running Foundry..."
./scripts/run-foundry.sh || echo "  Foundry failed"

# Copy results to timestamped directory
cp -r poc-results/* "poc-results/run_$TIMESTAMP/" 2>/dev/null || true

echo "All tools completed. Results in poc-results/run_$TIMESTAMP/"