# Slither install helpers (Windows, Linux, Docker, Jenkins)

Arquivos adicionados:

- `install_slither_linux.sh` - Script para Debian/Ubuntu que instala dependências, solc (via PPA quando possível) e `slither-analyzer` via pip.
- `install_slither_windows.ps1` - Script PowerShell para Windows que tenta instalar Python (winget/choco), `slither-analyzer` via pip e sugere instalar `solc` via choco/scoop ou manualmente.
- `Dockerfile.slither` - Dockerfile baseado em `python:3.11-slim` com `slither-analyzer` instalado. Tenta também instalar `solc`.
- `Jenkinsfile` - Pipeline declarativa que constrói a imagem Docker a partir de `Dockerfile.slither` e executa `slither` (procura pasta `contracts` por padrão).

Observações importantes:

- Slither requer `solc` (Solidity compiler) para algumas análises. Os scripts tentam instalar `solc` automaticamente quando possível, mas pode ser necessário instalar um binário `solc` adequado manualmente dependendo da plataforma e versões desejadas.
- Em Windows, recomenda-se executar o PowerShell como Administrador.
- Em Linux, execute: `sudo bash install_slither_linux.sh` e torne executável caso deseje `chmod +x`.
- O Dockerfile tenta usar o PPA `ethereum/ethereum` para instalar `solc`. Em ambientes onde isso falha, edite o Dockerfile para instalar `solc` via outro método (ex.: baixar binário, usar npm solc, etc.).

Exemplos de uso:

Linux (executar como root ou via sudo):

```bash
sudo bash install_slither_linux.sh
slither ./contracts
```

Windows (PowerShell como Administrador):

```powershell
.\install_slither_windows.ps1
slither .\contracts
```

Docker (build + run):

```bash
docker build -t slither:local -f Dockerfile.slither .
docker run --rm -v "$PWD":/work slither:local /work/contracts
```

Jenkins

- Adicione este repositório a um job Pipeline no Jenkins com suporte a Docker. O `Jenkinsfile` construirá a imagem e executará `slither` automaticamente.

Notas sobre compatibilidade e troubleshooting

- Se `slither` falhar por causa de versões do `solc`, instale a versão do `solc` compatível com seus contratos. Ferramentas como `solc-select` (Linux) ou baixar binários do GitHub podem ajudar.
- Em Windows, depois da instalação do Python, certifique-se de que a pasta `Scripts` do Python esteja no PATH para que `slither` (instalado via pip) esteja disponível globalmente.

Contribuições e melhorias sugeridas

- Adicionar um Docker multistage com cache de dependências para reduzir tamanho da imagem.
- Suporte para instalação em distribuições não Debian (Fedora, Arch) e para MacOS.
- Testes automatizados simples que rodem `slither --version` em CI.
