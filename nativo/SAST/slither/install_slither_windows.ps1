<#
  install_slither_windows.ps1
  Script PowerShell para instalar Slither (Windows) usando winget/chocolatey quando disponível.
  Requer execução em PowerShell com privilégios de administrador para instalar pacotes.
#>

function Ensure-Admin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Error "Este script precisa ser executado como Administrador. Abra PowerShell como Administrador e execute novamente."
        exit 1
    }
}

Ensure-Admin

Write-Host "=== Instalador Slither (Windows) ==="

function Install-Python {
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Python já está instalado."
        return
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Host "Instalando Python via winget..."
        winget install --id Python.Python.3 -e --silent
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Instalando Python via chocolatey..."
        choco install python -y
    } else {
        Write-Warning "Nem winget nem chocolatey encontrados. Instale Python manualmente: https://www.python.org/downloads/"
    }
}

function Install-Solc {
    if (Get-Command solc -ErrorAction SilentlyContinue) {
        Write-Host "solc já está instalado."
        return
    }

    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Tentando instalar solc via chocolatey..."
        choco install solidity -y || choco install solc -y || Write-Warning "Falha ao instalar solc via chocolatey."
    } elseif (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Host "Tentando instalar solc via scoop..."
        scoop install solc || Write-Warning "Falha ao instalar solc via scoop."
    } else {
        Write-Warning "Não foi encontrado gerenciador de pacotes para instalar solc automaticamente.\nBaixe um binário solc adequado de https://github.com/ethereum/solidity/releases e coloque no PATH."
    }
}

Install-Python

# Atualiza pip e instala slither
Write-Host "Atualizando pip e instalando slither-analyzer..."
python -m pip install --upgrade pip setuptools wheel
python -m pip install --upgrade slither-analyzer

Install-Solc

Write-Host "-----"
try {
    slither --version
} catch {
    Write-Warning "slither não funcionou ao executar --version; verifique se Python e pacotes foram instalados corretamente e se o PATH contém o Python Scripts."
}

Write-Host "Pronto. Execute: slither <pasta-ou-arquivo-solidity>"
