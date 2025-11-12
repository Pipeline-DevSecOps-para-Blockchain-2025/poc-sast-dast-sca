# Run Security Tools PoC Containers (PowerShell)
# This script provides easy commands to run security analysis tools

param(
    [Parameter(Position=0)]
    [ValidateSet('slither', 'mythril', 'help')]
    [string]$Tool,
    
    [Parameter(Position=1)]
    [ValidateSet('analyze', 'shell', 'help')]
    [string]$Command,
    
    [Parameter(Position=2)]
    [string]$ContractPath,
    
    [string]$OutputDir = "poc-results",
    [string]$WorkspaceDir = "poc-workspace"
)

function Print-Status { param($m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Print-Success { param($m) Write-Host "[SUCCESS] $m" -ForegroundColor Green }
function Print-Warning { param($m) Write-Host "[WARNING] $m" -ForegroundColor Yellow }
function Print-Error { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

function Show-Usage {
    Write-Host "Usage: .\run-containers.ps1 <tool> <command> [contract_path] [options]"
    Write-Host ""
    Write-Host "Available tools:"
    Write-Host "  slither   - Static analysis for Solidity"
    Write-Host "  mythril   - Security analysis for EVM bytecode"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  analyze <contract_path>  - Run analysis on contract"
    Write-Host "  shell                    - Start interactive shell"
    Write-Host "  help                     - Show tool help"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\run-containers.ps1 slither analyze contracts\vulnerable\MyContract.sol"
    Write-Host "  .\run-containers.ps1 mythril analyze contracts\vulnerable\MyContract.sol"
    Write-Host "  .\run-containers.ps1 slither shell"
    Write-Host "  .\run-containers.ps1 mythril help"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -OutputDir <dir>       - Output directory for results (default: poc-results)"
    Write-Host "  -WorkspaceDir <dir>    - Workspace directory (default: poc-workspace)"
}

if ($Tool -eq 'help' -or [string]::IsNullOrEmpty($Tool) -or [string]::IsNullOrEmpty($Command)) {
    Show-Usage
    exit 0
}

# Change to project root (script is in scripts/)
Set-Location -Path (Join-Path $PSScriptRoot "..")

# Create directories
New-Item -ItemType Directory -Force -Path $OutputDir, $WorkspaceDir | Out-Null

# Check if image exists
& docker image inspect "security-tools-poc:$Tool" > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Print-Error "Docker image security-tools-poc:$Tool not found"
    Print-Status "Run '.\scripts\build-docker-images.ps1' first"
    exit 1
}

# Execute command
switch ($Command) {
    'analyze' {
        if ([string]::IsNullOrEmpty($ContractPath)) {
            Print-Error "Contract path required for analyze command"
            exit 1
        }
        
        if (-not (Test-Path $ContractPath)) {
            Print-Error "Contract file not found: $ContractPath"
            exit 1
        }
        
        Print-Status "Running $Tool analysis on $ContractPath"
        
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $contractName = [System.IO.Path]::GetFileNameWithoutExtension($ContractPath)
        
        switch ($Tool) {
            'slither' {
                & docker run --rm `
                    -v "${PWD}:/workspace" `
                    -v "${PWD}/$OutputDir:/results" `
                    --workdir /workspace `
                    "security-tools-poc:slither" `
                    $ContractPath `
                    --json "/results/slither-$contractName-$timestamp.json"
            }
            'mythril' {
                & docker run --rm `
                    -v "${PWD}:/workspace" `
                    -v "${PWD}/$OutputDir:/results" `
                    --workdir /workspace `
                    "security-tools-poc:mythril" `
                    analyze $ContractPath `
                    --output-dir "/results" `
                    --output-format json
            }
        }
    }
    
    'shell' {
        Print-Status "Starting interactive shell for $Tool"
        & docker run -it --rm `
            -v "${PWD}:/workspace" `
            -v "${PWD}/$OutputDir:/results" `
            -v "${PWD}/$WorkspaceDir:/poc-workspace" `
            --workdir /workspace `
            --entrypoint /bin/sh `
            "security-tools-poc:$Tool"
    }
    
    'help' {
        Print-Status "Showing help for $Tool"
        & docker run --rm "security-tools-poc:$Tool" --help
    }
    
    default {
        Print-Error "Unknown command: $Command"
        Show-Usage
        exit 1
    }
}

if ($LASTEXITCODE -eq 0) {
    Print-Success "Command completed successfully"
} else {
    Print-Error "Command failed with exit code $LASTEXITCODE"
}