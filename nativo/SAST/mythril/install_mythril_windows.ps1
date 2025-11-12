# Mythril installation script for Windows
# Requires PowerShell with Administrator privileges

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator. Open PowerShell as Administrator and run again."
        exit 1
    }
}

Ensure-Admin

Write-Host "=== Mythril Installer (Windows) ==="

function Install-Python {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Python is already installed."
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python via winget..."
        winget install --id Python.Python.3 -e --silent
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Python via chocolatey..."
        choco install python -y
    } else {
        Write-Warning "Neither winget nor chocolatey found. Install Python manually: https://www.python.org/downloads/"
    }
}

Install-Python

# Update pip and install Mythril
Write-Host "Updating pip and installing mythril..."
python -m pip install --upgrade pip setuptools wheel
python -m pip install --upgrade mythril

# Install solc-select for Solidity version management
Write-Host "Installing solc-select..."
python -m pip install solc-select

Write-Host "Installing and configuring Solidity compiler..."
solc-select install 0.8.19
solc-select use 0.8.19

Write-Host "-----"
try {
    myth version
    solc --version
} catch {
    Write-Warning "Mythril or solc not working properly; check if Python and packages were installed correctly."
}

Write-Host "Done. Usage: myth analyze <contract.sol>"