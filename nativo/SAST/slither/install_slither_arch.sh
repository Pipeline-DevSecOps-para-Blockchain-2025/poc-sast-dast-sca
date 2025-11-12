#!/bin/bash
# Slither installation script for Arch Linux
set -e

echo "============================================="
echo "Installing Slither on Arch Linux..."
echo "============================================="

# 1. Update system and install prerequisites
echo "[1/5] Updating system and installing prerequisites..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm python python-pip git base-devel

# 2. Update pip
echo "[2/5] Updating pip..."
pip install --upgrade pip

# 3. Install solc-select for Solidity version management
echo "[3/5] Installing solc-select..."
pip install solc-select

# 4. Install Slither
echo "[4/5] Installing slither-analyzer..."
pip install slither-analyzer

# 5. Install and configure Solidity compiler
echo "[5/5] Installing and activating solc 0.8.30..."
solc-select install 0.8.30
solc-select use 0.8.30

echo "---------------------------------------------"
echo "Installation verification:"
slither --version
solc --version
echo "---------------------------------------------"
echo "Slither installation completed successfully!"
echo "Use 'solc-select install <version>' to add other Solidity versions."