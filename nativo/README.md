# Native Security Tools Installation

This directory contains native installation scripts for security analysis tools, supporting multiple operating systems and Linux distributions.

## Supported Tools

- **Slither** - Static analysis for Solidity smart contracts
- **Mythril** - Symbolic execution and security analysis
- **Echidna** - Property-based fuzzing for smart contracts  
- **Foundry** - Development framework with testing and deployment tools

## Supported Platforms

- **Linux**: Ubuntu/Debian, Arch Linux
- **Windows**: PowerShell with package managers (winget/chocolatey)

## Quick Installation

### Install All Tools

**Linux:**
```bash
chmod +x nativo/install-all-tools.sh
sudo ./nativo/install-all-tools.sh
```

**Windows (as Administrator):**
```powershell
.\nativo\install-all-tools.ps1
```

### Install Individual Tools

**Slither:**
```bash
# Ubuntu/Debian
sudo ./nativo/SAST/slither/install_slither_linux.sh

# Arch Linux  
sudo ./nativo/SAST/slither/install_slither_arch.sh

# Windows (PowerShell as Admin)
.\nativo\SAST\slither\install_slither_windows.ps1
```

**Mythril:**
```bash
# Ubuntu/Debian
sudo ./nativo/SAST/mythril/install_mythril_linux.sh

# Arch Linux
sudo ./nativo/SAST/mythril/install_mythril_arch.sh

# Windows (PowerShell as Admin)
.\nativo\SAST\mythril\install_mythril_windows.ps1
```

**Echidna:**
```bash
# Ubuntu/Debian
sudo ./nativo/DAST/echidna/install_echidna_linux.sh

# Arch Linux
sudo ./nativo/DAST/echidna/install_echidna_arch.sh

# Windows (PowerShell as Admin)
.\nativo\DAST\echidna\install_echidna_windows.ps1
```

**Foundry:**
```bash
# Ubuntu/Debian
./nativo/SCA/foundry/install_foundry_linux.sh

# Arch Linux
./nativo/SCA/foundry/install_foundry_arch.sh

# Windows (PowerShell as Admin)
.\nativo\SCA\foundry\install_foundry_windows.ps1
```

## Directory Structure

```
nativo/
├── install-all-tools.sh          # Master installer (Linux)
├── install-all-tools.ps1         # Master installer (Windows)
├── SAST/                          # Static Analysis Tools
│   ├── slither/
│   │   ├── install_slither_linux.sh
│   │   ├── install_slither_arch.sh
│   │   └── install_slither_windows.ps1
│   └── mythril/
│       ├── install_mythril_linux.sh
│       ├── install_mythril_arch.sh
│       └── install_mythril_windows.ps1
├── DAST/                          # Dynamic Analysis Tools
│   └── echidna/
│       ├── install_echidna_linux.sh
│       ├── install_echidna_arch.sh
│       └── install_echidna_windows.ps1
└── SCA/                           # Software Composition Analysis
    └── foundry/
        ├── install_foundry_linux.sh
        ├── install_foundry_arch.sh
        └── install_foundry_windows.ps1
```

## Usage After Installation

**Slither:**
```bash
slither contract.sol
slither . --json report.json
```

**Mythril:**
```bash
myth analyze contract.sol
myth analyze contract.sol -o json
```

**Echidna:**
```bash
echidna-test contract.sol
echidna-test contract.sol --config config.yaml
```

**Foundry:**
```bash
forge init my-project
forge build
forge test
```

## Prerequisites

### Linux (Ubuntu/Debian)
- `sudo` privileges
- Internet connection
- `curl`, `git` (installed by scripts)

### Linux (Arch)
- `sudo` privileges  
- Internet connection
- `pacman` package manager

### Windows
- PowerShell with Administrator privileges
- Internet connection
- Package manager (winget or chocolatey) recommended

## Troubleshooting

### PATH Issues
After installation, you may need to:
```bash
# Linux
source ~/.bashrc
# or restart your terminal

# Windows  
# Restart PowerShell session
```

### Permission Issues (Linux)
```bash
# Make scripts executable
chmod +x nativo/**/*.sh
```

### Missing Dependencies
The scripts install most dependencies automatically, but you may need:

**Linux:**
- Build tools: `build-essential` (Ubuntu) or `base-devel` (Arch)
- Python 3 and pip
- Git

**Windows:**
- Visual Studio Build Tools (for some Python packages)
- Git for Windows

## Verification

After installation, verify tools work:
```bash
slither --version
myth version  
echidna-test --version
forge --version
cast --version
anvil --version
```

## Notes

- **Echidna** installation may take 30+ minutes when building from source
- **Foundry** tools include: forge, cast, anvil, chisel
- **Solidity compiler** versions are managed via `solc-select`
- Scripts are designed to be idempotent (safe to run multiple times)