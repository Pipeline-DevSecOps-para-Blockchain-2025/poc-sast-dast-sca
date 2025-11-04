# Echidna installation script for Windows
# Requires PowerShell with Administrator privileges

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "This script must be run as Administrator. Open PowerShell as Administrator and run again."
        exit 1
    }
}

Ensure-Admin

Write-Host "=== Echidna Installer (Windows) ==="

# Install Haskell Stack if not present
function Install-Stack {
    if (Get-Command stack -ErrorAction SilentlyContinue) {
        Write-Host "Haskell Stack is already installed."
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Installing Haskell Stack via winget..."
        winget install --id Haskell.Stack -e --silent
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Installing Haskell Stack via chocolatey..."
        choco install haskell-stack -y
    } else {
        Write-Warning "Neither winget nor chocolatey found. Install Stack manually: https://docs.haskellstack.org/en/stable/install_and_upgrade/"
        return
    }
}

# Install pre-built binary (faster option)
function Install-EchidnaBinary {
    Write-Host "Downloading Echidna pre-built binary..."
    $echidnaVersion = "2.2.1"
    $downloadUrl = "https://github.com/crytic/echidna/releases/download/v$echidnaVersion/echidna-test-$echidnaVersion-Windows.exe"
    $outputPath = "$env:ProgramFiles\echidna-test.exe"
    
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
        Write-Host "Echidna binary installed to $outputPath"
        
        # Add to PATH if not already there
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        $programFiles = [Environment]::GetFolderPath("ProgramFiles")
        if ($currentPath -notlike "*$programFiles*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$programFiles", "Machine")
            Write-Host "Added Program Files to system PATH"
        }
    } catch {
        Write-Warning "Failed to download pre-built binary: $_"
    }
}

Install-Stack
Install-EchidnaBinary

# Try to install via Stack (may take a long time)
Write-Host "Installing Echidna via Stack (this may take 30+ minutes)..."
try {
    stack install echidna
    Write-Host "Echidna installed via Stack successfully"
} catch {
    Write-Warning "Stack installation failed, but pre-built binary should work"
}

Write-Host "-----"
try {
    echidna-test --version
} catch {
    Write-Warning "Echidna not working properly; check installation and PATH"
}

Write-Host "Done. Usage: echidna-test <contract.sol>"