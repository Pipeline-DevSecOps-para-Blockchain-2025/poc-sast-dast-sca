#!/usr/bin/env bash
set -euo pipefail

# install_slither_linux.sh
# Instala o Slither (slither-analyzer) em sistemas Debian/Ubuntu
# Requer privilégios de sudo

usage() {
  echo "Usage: sudo $0"
  exit 1
}

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root. Try: sudo $0"
  exit 1
fi

apt-get update
apt-get install -y --no-install-recommends \
  software-properties-common \
  curl \
  ca-certificates \
  gnupg \
  python3 \
  python3-pip \
  build-essential

# Add Ethereum PPA to get a reasonably recent solc
if ! command -v solc >/dev/null 2>&1; then
  add-apt-repository ppa:ethereum/ethereum -y || true
  apt-get update
  apt-get install -y solc || echo "Warning: solc installation failed; you may install solc manually"
fi

# Ensure pip tooling up-to-date
python3 -m pip install --upgrade pip setuptools wheel

# Install slither
python3 -m pip install --upgrade slither-analyzer

echo "-----"
echo "slither version:"
slither --version || true
echo "Installed. Run 'slither <path-to-your-contracts>' to analyze a project."
