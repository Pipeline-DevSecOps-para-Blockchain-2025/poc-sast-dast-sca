#!/bin/bash
# FINAL Mythril runner to prevent Windows/Git Bash path conversion

set -euo pipefail

# 1. GET CONTRACT FILENAME
CONTRACT_NAME="${1:-}"
if [ -z "$CONTRACT_NAME" ]; then
    echo "Usage: $0 <contract_name.sol>"
    echo "Available contracts:"
    find ./contracts -type f -name "*.sol" -exec basename {} + 2>/dev/null || echo "No contracts found"
    exit 1
fi

# 2. FIND THE FULL PATH to the contract on your host machine
CONTRACT_HOST_PATH=$(find ./contracts -type f -name "$CONTRACT_NAME" | head -n 1)
if [ -z "$CONTRACT_HOST_PATH" ]; then
    echo "Error: Contract not found in the './contracts' directory: $CONTRACT_NAME"
    exit 1
fi

# 3. Determine the relative path (e.g., "vulnerable/MyContract.sol")
CONTRACT_RELATIVE_PATH=$(echo "$CONTRACT_HOST_PATH" | sed 's|^./contracts/||')

# 4. CRITICAL FIX: Construct the container path with a DOUBLE SLASH at the start.
#    This prevents the Git Bash shell from converting it to a Windows path.
CONTRACT_CONTAINER_PATH="//contracts/$CONTRACT_RELATIVE_PATH"

# 5. SETUP output files
OUTPUT_DIR="poc-results/mythril"
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_FILE="$OUTPUT_DIR/${CONTRACT_NAME%.sol}_$TIMESTAMP.json"
LOG_FILE="$OUTPUT_DIR/${CONTRACT_NAME%.sol}_$TIMESTAMP.log"

echo "Host path: $CONTRACT_HOST_PATH"
echo "Container path (with fix): $CONTRACT_CONTAINER_PATH"
echo "--------------------------------------------------------"
echo "Analyzing $CONTRACT_NAME with Mythril..."

# 6. EXECUTE the command. Note that the variable now contains the double-slashed path.
docker-compose -f docker/docker-compose.yml run --rm mythril \
    analyze "$CONTRACT_CONTAINER_PATH" \
    --solv 0.8.19 \
    --execution-timeout 120 \
    -o jsonv2 > "$OUTPUT_FILE" 2> "$LOG_FILE"

echo "--------------------------------------------------------"
echo "Analysis complete."
echo "Results saved to: $OUTPUT_FILE"
echo "Log saved to: $LOG_FILE"

# Optional: Remove empty log file
if [ ! -s "$LOG_FILE" ]; then
    rm "$LOG_FILE"
    echo "Removed empty log file."
fi