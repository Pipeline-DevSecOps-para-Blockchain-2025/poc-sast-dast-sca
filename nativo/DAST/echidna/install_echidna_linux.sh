#!/bin/bash
# Echidna installation script for Ubuntu/Debian
set -e

echo "============================================="
echo "Installing Echidna on Linux (Ubuntu/Debian)..."
echo "============================================="

# 1. Update packages and install prerequisites
echo "[1/4] Updating packages and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y curl git build-essential libgmp-dev libssl-dev

# 2. Install Haskell Stack (required for Echidna)
echo "[2/4] Installing Haskell Stack..."
curl -sSL https://get.haskellstack.org/ | sh

# 3. Add Stack to PATH for current session
export PATH=$HOME/.local/bin:$PATH

# 4. Install Echidna via Stack
echo "[3/4] Installing Echidna (this may take a while)..."
stack install echidna

# Alternative: Install via pre-built binary (faster)
echo "[4/4] Installing Echidna pre-built binary as backup..."
ECHIDNA_VERSION="2.2.1"
wget -O echidna-test "https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04"
chmod +x echidna-test
sudo mv echidna-test /usr/local/bin/

echo "---------------------------------------------"
echo "Installation verification:"
echidna-test --version || echo "Echidna binary version check failed"
echo "---------------------------------------------"
echo "Echidna installation completed!"
echo "Usage: echidna-test <contract.sol>"
echo "Note: Add ~/.local/bin to your PATH if not already done"