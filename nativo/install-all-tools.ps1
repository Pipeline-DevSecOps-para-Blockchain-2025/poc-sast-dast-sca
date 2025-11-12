# Master installer for all security analysis tools (Windows)
# Requires PowerShell with Administrator privileges

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator. Open PowerShell as Administrator and run again."
        exit 1
    }
}

Ensure-Admin

Write-Host "============================================="
Write-Host "Security Tools Master Installer (Windows)"
Write-Host "============================================="

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "This will install the following security analysis tools:"
Write-Host "- Slither (SAST)"
Write-Host "- Mythril (SAST)"
Write-Host "- Echidna (DAST/Fuzzing)"
Write-Host "- Foundry (Development Framework)"
Write-Host ""

$continue = Read-Host "Continue with installation? (y/N)"
if ($continue -notmatch "^[Yy]$") {
    Write-Host "Installation cancelled."
    exit 0
}

# Function to run installer scripts
function Run-Installer {
    param(
        [string]$Tool,
        [string]$Category,
        [string]$ScriptName
    )
    
    Write-Host ""
    Write-Host "Installing $Tool..." -ForegroundColor Yellow
    
    $scriptPath = Join-Path $scriptDir "$Category\$Tool\${ScriptName}_windows.ps1"
    
    if (Test-Path $scriptPath) {
        try {
            & $scriptPath
            Write-Host "$Tool installation completed." -ForegroundColor Green
        } catch {
            Write-Warning "$Tool installation failed: $_"
        }
    } else {
        Write-Warning "Installer not found for $Tool ($scriptPath)"
    }
}

# Install each tool
Run-Installer "slither" "SAST" "install_slither"
Run-Installer "mythril" "SAST" "install_mythril"
Run-Installer "echidna" "DAST" "install_echidna"
Run-Installer "foundry" "SCA" "install_foundry"

Write-Host ""
Write-Host "============================================="
Write-Host "All installations completed!" -ForegroundColor Green
Write-Host "============================================="
Write-Host ""
Write-Host "Verification commands:"
Write-Host "- Slither: slither --version"
Write-Host "- Mythril: myth version"
Write-Host "- Echidna: echidna-test --version"
Write-Host "- Foundry: forge --version"
Write-Host ""
Write-Host "Note: You may need to restart your PowerShell session"
Write-Host "to ensure all tools are available in your PATH."