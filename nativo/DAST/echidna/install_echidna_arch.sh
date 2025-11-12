#!/bin/bash
# Echidna installation script for Arch Linux
set -e

echo "============================================="
echo "Installing Echidna on Arch Linux..."
echo "============================================="

# 1. Update system and install prerequisites
echo "[1/4] Updating system and installing prerequisites..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm curl git base-devel gmp openssl stack

# 2. Install Echidna via Stack
echo "[2/4] Installing Echidna via Stack (this may take a while)..."
stack install echidna

# 3. Install pre-built binary as alternative
echo "[3/4] Installing Echidna pre-built binary..."
ECHIDNA_VERSION="2.2.1"
curl -L -o echidna-test "https://github.com/crytic/echidna/releases/download/v${ECHIDNA_VERSION}/echidna-test-${ECHIDNA_VERSION}-Ubuntu-18.04"
chmod +x echidna-test
sudo mv echidna-test /usr/local/bin/

# 4. Add Stack bin to PATH
echo "[4/4] Configuring PATH..."
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc

echo "---------------------------------------------"
echo "Installation verification:"
echidna-test --version || echo "Echidna version check failed"
echo "---------------------------------------------"
echo "Echidna installation completed!"
echo "Usage: echidna-test <contract.sol>"
echo "Note: Restart your shell or run 'source ~/.bashrc' to update PATH"