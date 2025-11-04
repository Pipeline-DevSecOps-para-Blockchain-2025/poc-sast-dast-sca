#!/bin/bash
# Mythril installation script for Ubuntu/Debian
set -e

echo "============================================="
echo "Installing Mythril on Linux (Ubuntu/Debian)..."
echo "============================================="

# 1. Update packages and install prerequisites
echo "[1/4] Updating packages and installing prerequisites..."
sudo apt-get update
sudo apt-get install -y python3-pip git build-essential libssl-dev libffi-dev python3-dev

# 2. Update pip
echo "[2/4] Updating pip..."
pip3 install --upgrade pip

# 3. Install solc-select for Solidity version management
echo "[3/4] Installing solc-select..."
pip3 install solc-select

# 4. Install Mythril
echo "[4/4] Installing mythril..."
pip3 install mythril

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