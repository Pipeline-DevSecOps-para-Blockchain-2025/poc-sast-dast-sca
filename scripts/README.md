# Simple Security Analysis Scripts

Clean, minimal scripts to run security tools on smart contracts. Assumes Docker images are already built.

## Scripts

- `run-slither.sh <contract.sol>` - Run Slither analysis
- `run-mythril.sh <contract.sol>` - Run Mythril analysis  
- `run-echidna.sh <contract.sol>` - Run Echidna fuzzing
- `run-foundry.sh` - Run Foundry compilation and tests
- `run-all.sh` - Run all tools on all contracts

## Usage

```bash
# Make executable
chmod +x scripts/*.sh

# Analyze specific contract
./scripts/run-slither.sh VulnerableContract.sol
./scripts/run-mythril.sh DeFiVulnerable.sol

# Run all tools
./scripts/run-all.sh
```

## Output

Results saved to `poc-results/` with timestamps.

## Prerequisites

- Docker images built with `build-docker-images.sh`
- Contracts in `poc-workspace/test-contracts/`