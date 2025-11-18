# OWASP Smart Contract Top 10 - Mapeamento de Vulnerabilidades

Este documento mapeia os **10 principais tipos de vulnerabilidades em Smart Contracts** identificados pelo OWASP Smart Contract Top 10 (2025) para os contratos vulneráveis presentes neste repositório.

**Fonte Oficial**: [OWASP Smart Contract Top 10](https://owasp.org/www-project-smart-contract-top-10/)

---

## 📊 Resumo das 10 Vulnerabilidades Principais

| # | OWASP ID | Vulnerabilidade | Impacto Financeiro (2024) | Ocorrências |
|---|----------|-----------------|----------|--------------------------|-------------|
| 1 | SC01:2025 | **Access Control Vulnerabilities** | **$953.2M** | Mais frequente |
| 2 | SC02:2025 | **Price Oracle Manipulation** | $8.8M | Moderno |
| 3 | SC03:2025 | **Logic Errors** | $63.8M | Comum |
| 4 | SC04:2025 | **Lack of Input Validation** | $14.6M | Frequente |
| 5 | SC05:2025 | **Reentrancy Attacks** | $35.7M | Clássico |
| 6 | SC06:2025 | **Unchecked External Calls** | $550.7K | Sutil |
| 7 | SC07:2025 | **Flash Loan Attacks** | $33.8M | DeFi |
| 8 | SC08:2025 | **Integer Overflow/Underflow** | N/A | Solidity < 0.8 |
| 9 | SC09:2025 | **Insecure Randomness** | N/A | Previsível |
| 10 | SC10:2025 | **Denial of Service (DoS)** | N/A | Bloqueante |

---

## 🔴 SC01:2025 - Access Control Vulnerabilities

**Descrição**: Falhas de controle de acesso permitem que usuários não autorizados acessem ou modifiquem dados ou funções de um contrato.

**Vulnerável**: `SimpleBank.withdrawAll()` - Sem verificação de permissão
**Corrigido**: `ProtectedSimpleBank.withdrawAll()` - Com validação de proprietário

**Impacto**: Perda de fundos, roubo de ativos
**Detecção**: SAST, análise estática

### Exemplo de Exploit:
```solidity
// VULNERÁVEL
function withdrawAll() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    msg.sender.call{value: amount}("");
}

// QUALQUER PESSOA pode chamar e roubar todos os fundos!
```

**Dados 2024**: $953.2M em perdas documentadas (SolidityScan Web3HackHub)

---

## 🟠 SC02:2025 - Price Oracle Manipulation

**Descrição**: Explorações em como smart contracts obtêm dados externos de preços, permitindo manipulação por atacantes.

**Vulnerável**: `SimpleOracle.getPrice()` - Usa apenas uma fonte de preço
**Corrigido**: `ProtectedOracle` - Implementa TWAP (Time-Weighted Average Price)

**Impacto**: Liquidações injustas, arbitragem prejudicial
**Detecção**: Análise de arquitetura, testes de integração

### Exemplo de Exploit:
```solidity
// VULNERÁVEL - Manipulável em um bloco
function getPrice() public view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
    return (uint256(reserve1) * 1e18) / uint256(reserve0);
}

// Atacante pode fazer grande swap e manipular o preço
```

**Dados 2024**: $8.8M em perdas documentadas

---

## 🟡 SC03:2025 - Logic Errors

**Descrição**: Erros de lógica de negócio onde o contrato se comporta diferente da intenção, causando comportamentos inesperados.

**Arquivo**: [`LogicError.sol`](./vulnerable/LogicError.sol)

**Vulnerável**: `VulnerableLogic.claimAirdrop()` - Sem verificação de múltiplas reivindicações
**Corrigido**: `SecureLogic.claimAirdrop()` - Rastreia endereços que já reivindicaram

**Impacto**: Distribuição injusta de fundos, exploração de condições
**Detecção**: Testes automatizados, revisão de código

### Exemplo de Exploit:
```solidity
// VULNERÁVEL
function claimAirdrop() public {
    balances[msg.sender] += airdropAmount;
    // Nada impede que clame múltiplas vezes!
}

// CORRETO
mapping(address => bool) public hasClaimed;
function claimAirdrop() public {
    require(!hasClaimed[msg.sender], "Already claimed");
    hasClaimed[msg.sender] = true;
    balances[msg.sender] += airdropAmount;
}
```

**Dados 2024**: $63.8M em perdas documentadas

---

## 🟢 SC04:2025 - Lack of Input Validation

**Descrição**: Validação insuficiente de parâmetros de entrada pode levar a comportamentos inesperados ou exploração.

**Vulnerável**: `NoValidation.transfer()` - Não valida endereço zero
**Corrigido**: `ValidatedTransfer.transfer()` - Valida todos os parâmetros

**Impacto**: Queima acidental de tokens, comportamentos não esperados
**Detecção**: SAST, revisão de código

### Exemplo de Exploit:
```solidity
// VULNERÁVEL
function transfer(address _to, uint256 _amount) public {
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
    // Nada impede transferência para address(0)!
}

// CORRETO
function transfer(address _to, uint256 _amount) public {
    require(_to != address(0), "Cannot transfer to zero address");
    require(_amount > 0, "Amount must be greater than 0");
    balances[msg.sender] -= _amount;
    balances[_to] += _amount;
}
```

**Dados 2024**: $14.6M em perdas documentadas

---

## 🔵 SC05:2025 - Reentrancy Attacks

**Descrição**: Ataques de reentrada exploram a capacidade de executar funções recursivamente durante a execução de uma transação.

**Vulnerável**: `EtherStore.withdraw()` - Atualiza estado após transferência
**Corrigido**: `EtherStoreGuarded.withdraw()` - Implementa Checks-Effects-Interactions

**Impacto**: Drenagem de contrato, perda de fundos
**Detecção**: Slither, Mythril

### Exemplo de Exploit:
```solidity
// VULNERÁVEL - Estado é atualizado APÓS a chamada
function withdraw() public {
    uint256 balance = balances[msg.sender];
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success);
    balances[msg.sender] = 0; // Muito tarde!
}

// CORRETO - Padrão Checks-Effects-Interactions
function withdraw() public {
    uint256 balance = balances[msg.sender];
    balances[msg.sender] = 0;  // Efeito primeiro
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success);          // Depois a interação
}
```

**Dados 2024**: $35.7M em perdas documentadas

---

## 🟣 SC06:2025 - Unchecked External Calls

**Descrição**: Falhar em verificar o resultado de chamadas externas pode fazer o contrato continuar em estado inválido.

**Vulnerável**: `UncheckedCall.withdraw()` - Não valida resultado de `call`
**Corrigido**: `SafeCall.withdraw()` - Valida retorno da chamada

**Impacto**: Continuação em estado inválido, operações falhadas silenciosamente
**Detecção**: Análise estática, revisão manual

### Exemplo de Exploit:
```solidity
// VULNERÁVEL
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    msg.sender.call{value: amount}("");  // Resultado ignorado!
}

// CORRETO
function withdraw(uint256 amount) public {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Withdrawal failed");
}
```

**Dados 2024**: $550.7K em perdas documentadas

---

## 🟠 SC07:2025 - Flash Loan Attacks

**Descrição**: Flash loans permitem exploração através da manipulação de preços e estado em uma única transação.

**Vulnerável**: `FlashLoanPool.flashLoan()` - Sem proteções contra manipulação
**Corrigido**: `SafeFlashLoanPool.flashLoan()` - Implementa limite de empréstimo e validação

**Impacto**: Drenagem de liquidez, manipulação de preços
**Detecção**: Análise de arquitetura DeFi, testes de integração

### Exemplo de Exploit:
```solidity
// VULNERÁVEL - Sem limite de empréstimo
function flashLoan(address token, uint256 amount, address receiver, bytes calldata data) {
    balanceBefore = address(this).balance;
    // Transferir grande quantidade...
    require(balanceAfter >= balanceBefore + fee);  // Apenas verifica repagamento
}

// CORRETO - Com limite
function flashLoan(address token, uint256 amount, address receiver, bytes calldata data) {
    require(amount <= (balanceBefore * MAX_LOAN_PERCENTAGE) / 100);
    // Transferir respeitando limites...
}
```

**Dados 2024**: $33.8M em perdas documentadas

---

## 🟡 SC08:2025 - Integer Overflow and Underflow

**Descrição**: Erros aritméticos causados por exceder limites de inteiros de tamanho fixo.

**Vulnerável**: `IntegerOverflow.add()` - Sem proteção contra overflow de uint8
**Corrigido**: `SafeArithmetic` - Usa Solidity 0.8+ com proteção integrada

**Impacto**: Cálculos incorretos, roubo de tokens
**Detecção**: Slither, Mythril, Solidity 0.8+ (automático)

### Exemplo de Exploit:
```solidity
// VULNERÁVEL (Solidity < 0.8)
function add(uint8 a, uint8 b) public pure returns (uint8) {
    return a + b;  // 255 + 1 = 0!
}

// CORRETO (Solidity 0.8+)
function add(uint8 a, uint8 b) public pure returns (uint8) {
    return a + b;  // Reverte automaticamente em overflow
}

// Ou com verificação explícita
function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
    require(a + b >= a, "Addition overflow");
    return a + b;
}
```

**Nota**: Solidity 0.8+ implementa verificações automáticas de overflow

---

## 🔴 SC09:2025 - Insecure Randomness

**Descrição**: Gerar números aleatórios em blockchain é desafiador pois é determinístico. Fontes inseguras são previsíveis.

**Vulnerável**: `InsecureRandomness.play()` - Usa `block.timestamp`
**Corrigido**: `SecureRandomness` - Usa Chainlink VRF ou Commit-Reveal

**Impacto**: Resultados previsíveis, exploração de loterias
**Detecção**: Análise de fontes de aleatoriedade, testes de previsibilidade

### Exemplo de Exploit:
```solidity
// VULNERÁVEL - Previsível
function play() public payable {
    uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp))) % 100;
    // Minerador/validador pode conhecer o valor!
}

// CORRETO - Chainlink VRF
function requestRandomness() public returns (bytes32) {
    return vrfCoordinator.requestRandomness(keyHash, fee);
}

// CORRETO - Commit-Reveal
// Fase 1: Usuários fazem commit de hash(valor, salt)
// Fase 2: Usuários revelam valor e salt
// Fase 3: Resultado final é XOR de todos os valores revelados
```

**Nota**: Usar Chainlink VRF, RANDAO, ou padrão Commit-Reveal

---

## 🟢 SC10:2025 - Denial of Service (DoS) Attacks

**Descrição**: Explorar vulnerabilidades para tornar o contrato não funcional ou consumir excessivamente gas.

**Vulnerável**: `DenialOfService.distributeRewards()` - Loop sem limite de tamanho
**Corrigido**: `SafeDOS` - Implementa processamento em lotes e limites

**Impacto**: Contrato não funcional, impossibilidade de usar funções
**Detecção**: Análise de padrões de loop, testes de escalabilidade

### Exemplo de Exploit:
```solidity
// VULNERÁVEL - Sem limite
function distributeRewards(uint256 reward) public {
    for (uint256 i = 0; i < users.length; i++) {
        balances[users[i]] += reward;
        // Com milhões de usuários, excede gas limit!
    }
}

// CORRETO - Com paginação
function distributeRewards(uint256 reward, uint256 startIndex, uint256 endIndex) public {
    require(endIndex - startIndex <= BATCH_SIZE);  // Limite de batch
    for (uint256 i = startIndex; i < endIndex; i++) {
        balances[users[i]] += reward;
    }
}

// CORRETO - Pull pattern ao invés de push
mapping(address => uint256) public pendingRefunds;
function claimRefund() public {
    uint256 amount = pendingRefunds[msg.sender];
    pendingRefunds[msg.sender] = 0;
    msg.sender.call{value: amount}("");
}
```

---

## 📚 Ferramentas de Detecção Recomendadas

### Análise Estática (SAST)
- **Slither**: Detecção de padrões vulneráveis
- **Mythril**: Análise simbólica de bytecode
- **Semgrep**: Busca de padrões customizados

### Análise Dinâmica (DAST)
- **Echidna**: Fuzzing de propriedades
- **Foundry Fuzz Testing**: Testes de fuzzing integrados
- **Manticore**: Execução simbólica

### Análise de Composição (SCA)
- **Solidity Scanner**: Verificação de dependências
- **OpenZeppelin Audits**: Auditoria de código

---

## 📖 Referências

- **Oficialmente**: https://owasp.org/www-project-smart-contract-top-10/
- **SWC Registry**: https://swcregistry.io/
- **SolidityScan Web3HackHub**: https://solidityscan.com/web3hackhub
- **Immunefi Reports**: https://immunefi.com/

---

*Último atualizado: Novembro de 2025*
*Baseado em OWASP Smart Contract Top 10 (2025) e dados do SolidityScan Web3HackHub*
