# Foundry installation script for Windows
# Requires PowerShell with Administrator privileges

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator. Open PowerShell as Administrator and run again."
        exit 1
    }
}

Ensure-Admin

Write-Host "=== Foundry Installer (Windows) ==="

# Install Git if not present
function Install-Git {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Git is already installed."
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Git via winget..."
        winget install --id Git.Git -e --silent
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Git via chocolatey..."
        choco install git -y
    } else {
        Write-Warning "Neither winget nor chocolatey found. Install Git manually: https://git-scm.com/download/win"
    }
}

Install-Git

# Install Foundry
Write-Host "Installing Foundry..."

# Download and run foundryup
$foundryupUrl = "https://foundry.paradigm.xyz"
$foundryupScript = "$env:TEMP\foundryup.ps1"

try {
    # Download foundryup installer
    Invoke-WebRequest -Uri $foundryupUrl -OutFile $foundryupScript
    
    # Run foundryup
    & $foundryupScript
    
    # Add Foundry to PATH
    $foundryPath = "$env:USERPROFILE\.foundry\bin"
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$foundryPath*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$foundryPath", "User")
        Write-Host "Added Foundry to user PATH"
    }
    
    # Refresh PATH for current session
    $env:PATH = "$env:PATH;$foundryPath"
    
} catch {
    Write-Warning "Foundryup installation failed: $_"
    Write-Host "Try manual installation from: https://book.getfoundry.sh/getting-started/installation"
}

Write-Host "-----"
try {
    forge --version
    cast --version
    anvil --version
} catch {
    Write-Warning "Foundry tools not working properly; check installation and PATH"
    Write-Host "You may need to restart your PowerShell session"
}

Write-Host "Done. Tools available: forge, cast, anvil, chisel"