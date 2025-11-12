#!/bin/bash
# Foundry installation script for Arch Linux
set -e

echo "============================================="
echo "Installing Foundry on Arch Linux..."
echo "============================================="

# 1. Update system and install prerequisites
echo "[1/3] Updating system and installing prerequisites..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm curl git base-devel

# 2. Install Foundry using foundryup
echo "[2/3] Installing Foundry via foundryup..."
curl -L https://foundry.paradigm.xyz | bash

# 3. Add Foundry to PATH and install latest version
echo "[3/3] Configuring Foundry..."
export PATH="$HOME/.foundry/bin:$PATH"
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc

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