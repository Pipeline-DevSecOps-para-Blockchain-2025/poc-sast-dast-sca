<#
Build Docker Images for Security Tools PoC (PowerShell)
This script mirrors scripts/build-docker-images.sh
#>

Set-StrictMode -Version Latest

function Print-Status { param($m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Print-Success { param($m) Write-Host "[SUCCESS] $m" -ForegroundColor Green }
function Print-Warning { param($m) Write-Host "[WARNING] $m" -ForegroundColor Yellow }
function Print-Error { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }

# Check Docker installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Print-Error "Docker is not installed. Please install Docker first."
    exit 1
}

# Check Docker running
try {
    docker info > $null 2>&1
} catch {
    Print-Error "Docker is not running. Please start Docker first."
    exit 1
}

Print-Success "Docker is available and running"

# Change to project root directory (script is in scripts/)
Set-Location -Path (Join-Path $PSScriptRoot "..")

# Create necessary directories
Print-Status "Creating workspace directories..."
New-Item -ItemType Directory -Force -Path poc-workspace, poc-temp, poc-results | Out-Null

# Create Docker network if missing
Print-Status "Creating Docker network..."
$networkName = 'security-tools-poc-network'
try {
    $exists = docker network inspect $networkName > $null 2>&1; $netOk = ($LASTEXITCODE -eq 0)
} catch { $netOk = $false }
if (-not $netOk) {
    docker network create $networkName | Out-Null
    Print-Success "Docker network created: $networkName"
} else {
    Print-Warning "Docker network already exists: $networkName"
}

# Available tools with their Docker contexts
$toolsConfig = @{
    'slither' = 'Docker/slither'
    'mythril' = 'Docker/mythril'
}

# Build tool-specific images
foreach ($tool in $toolsConfig.Keys) {
    $toolDir = $toolsConfig[$tool]
    
    if ((Test-Path $toolDir) -and (Test-Path "$toolDir/Dockerfile")) {
        Print-Status "Building $tool Docker image..."
        & docker build -t "security-tools-poc:$tool" $toolDir
        if ($LASTEXITCODE -eq 0) {
            Print-Success "$tool image built successfully"
        } else {
            Print-Error "Failed to build $tool image"
            continue
        }
    } else {
        Print-Warning "Skipping $tool - Dockerfile not found in $toolDir"
    }
}

# List built images
Print-Status "Listing built images..."
$images = & docker images | Select-String security-tools-poc
if ($images) {
    $images | ForEach-Object { Write-Host $_.ToString() }
} else {
    Print-Warning "No security-tools-poc images found"
}

# Test images
function Test-Image {
    param(
        [string]$tool,
        [string]$testCommand
    )
    Print-Status "Testing $tool image..."
    & docker run --rm "security-tools-poc:$tool" $testCommand > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Print-Success "$tool image test passed"
        return $true
    } else {
        Print-Warning "$tool image test failed"
        return $false
    }
}

# Test available tool images
foreach ($tool in $toolsConfig.Keys) {
    & docker image inspect "security-tools-poc:$tool" > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        switch ($tool) {
            "slither" { Test-Image $tool "--version" }
            "mythril" { Test-Image $tool "version" }
        }
    }
}

Print-Success "Docker image build process completed!"

Write-Host "`nAvailable images:"
foreach ($tool in $toolsConfig.Keys) {
    & docker image inspect "security-tools-poc:$tool" > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  - security-tools-poc:$tool"
    }
}

Write-Host "`nUsage examples:"
Write-Host "  # Run Slither analysis:"
Write-Host "  docker run --rm -v `$(pwd)/contracts:/contracts security-tools-poc:slither /contracts"
Write-Host ""
Write-Host "  # Run Mythril analysis:"
Write-Host "  docker run --rm -v `$(pwd)/contracts:/contracts security-tools-poc:mythril analyze /contracts/MyContract.sol"
Write-Host ""
Write-Host "  # Interactive shell:"
Write-Host "  docker run -it --rm -v `$(pwd):/workspace security-tools-poc:slither bash"
