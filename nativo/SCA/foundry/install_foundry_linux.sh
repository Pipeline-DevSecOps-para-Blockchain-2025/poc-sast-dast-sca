#!/bin/bash
# Foundry installation script for Ubuntu/Debian
set -e

echo "============================================="
echo "Installing Foundry on Linux (Ubuntu/Debian)..."
echo "============================================="

# 1. Update packages and install prerequisites
echo "[1/3] Updating packages and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y curl git build-essential

# 2. Install Foundry using foundryup
echo "[2/3] Installing Foundry via foundryup..."
curl -L https://foundry.paradigm.xyz | bash

# 3. Add Foundry to PATH and install latest version
echo "[3/3] Configuring Foundry..."
source ~/.bashrc
export PATH="$HOME/.foundry/bin:$PATH"

# Install the latest version
~/.foundry/bin/foundryup

echo "---------------------------------------------"
echo "Installation verification:"
forge --version || echo "Forge not found in PATH"
cast --version || echo "Cast not found in PATH"
anvil --version || echo "Anvil not found in PATH"
echo "---------------------------------------------"
echo "Foundry installation completed!"
echo "Tools available: forge, cast, anvil, chisel"
echo "Note: Restart your shell or run 'source ~/.bashrc' to update PATH"