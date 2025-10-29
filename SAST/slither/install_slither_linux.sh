#!/bin/bash
set -e # Sai imediatamente se um comando falhar

echo "============================================="
echo "Iniciando a instalação do Slither no Linux..."
echo "============================================="

# 1. Atualizar pacotes e instalar pré-requisitos (Python 3, pip e git)
echo "[1/5] Atualizando pacotes e instalando python3-pip e git..."
sudo apt-get update
sudo apt-get install -y python3-pip git

# 2. Garantir que o pip está atualizado
echo "[2/5] Atualizando pip..."
pip3 install --upgrade pip

# 3. Instalar solc-select (ferramenta recomendada para gerenciar versões do Solidity)
echo "[3/5] Instalando solc-select..."
pip3 install solc-select

# 4. Instalar o Slither
echo "[4/5] Instalando slither-analyzer..."
pip3 install slither-analyzer

# 5. Instalar uma versão padrão do Solidity (ex: 0.8.30)
# O Slither precisa do compilador 'solc' para funcionar.
echo "[5/5] Instalando e ativando solc 0.8.30..."
solc-select install 0.8.30
solc-select use 0.8.30

echo "---------------------------------------------"
echo "Verificação da instalação:"
slither --version
solc --version
echo "---------------------------------------------"
echo "Instalação do Slither concluída com sucesso!"
echo "Use 'solc-select install <versao>' para adicionar outras versões do Solidity."