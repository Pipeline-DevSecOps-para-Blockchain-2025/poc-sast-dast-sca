#!/bin/bash
# Mythril installation script for Arch Linux
set -e

echo "============================================="
echo "Installing Mythril on Arch Linux..."
echo "============================================="

# 1. Update system and install prerequisites
echo "[1/4] Updating system and installing prerequisites..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm python python-pip git base-devel openssl libffi

# 2. Update pip
echo "[2/4] Updating pip..."
pip install --upgrade pip

# 3. Install solc-select for Solidity version management
echo "[3/4] Installing solc-select..."
pip install solc-select

# 4. Install Mythril
echo "[4/4] Installing mythril..."
pip install mythril

# Install and configure Solidity compiler
echo "Installing and activating solc 0.8.19..."
solc-select install 0.8.19
solc-select use 0.8.19

echo "---------------------------------------------"
echo "Installation verification:"
myth version
solc --version
echo "---------------------------------------------"
echo "Mythril installation completed successfully!"
echo "Usage: myth analyze <contract.sol>"