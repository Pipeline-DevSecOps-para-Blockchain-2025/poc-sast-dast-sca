#!/bin/bash
# Master installer for all security analysis tools
# Supports Ubuntu/Debian and Arch Linux

set -e

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    elif [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================="
echo "Security Tools Master Installer"
echo "Detected distribution: $DISTRO"
echo "============================================="

# Function to run installer scripts
run_installer() {
    local tool=$1
    local category=$2
    local script_name=$3
    
    echo ""
    echo "Installing $tool..."
    
    if [ "$DISTRO" = "arch" ]; then
        script_path="$SCRIPT_DIR/$category/$tool/${script_name}_arch.sh"
    else
        script_path="$SCRIPT_DIR/$category/$tool/${script_name}_linux.sh"
    fi
    
    if [ -f "$script_path" ]; then
        chmod +x "$script_path"
        bash "$script_path"
        echo "$tool installation completed."
    else
        echo "Warning: Installer not found for $tool ($script_path)"
    fi
}

# Install all tools
echo "This will install the following security analysis tools:"
echo "- Slither (SAST)"
echo "- Mythril (SAST)" 
echo "- Echidna (DAST/Fuzzing)"
echo "- Foundry (Development Framework)"
echo ""

read -p "Continue with installation? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

# Install each tool
run_installer "slither" "SAST" "install_slither"
run_installer "mythril" "SAST" "install_mythril"  
run_installer "echidna" "DAST" "install_echidna"
run_installer "foundry" "SCA" "install_foundry"

echo ""
echo "============================================="
echo "All installations completed!"
echo "============================================="
echo ""
echo "Verification:"
echo "- Slither: slither --version"
echo "- Mythril: myth version"
echo "- Echidna: echidna-test --version"
echo "- Foundry: forge --version"
echo ""
echo "Note: You may need to restart your shell or run 'source ~/.bashrc'"
echo "to ensure all tools are available in your PATH."