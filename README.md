# poc-sast-das-sca

## 🔐 Análise de Segurança - OWASP Smart Contract Top 10

Este projeto mapeia todos os **10 principais tipos de vulnerabilidades em Smart Contracts** conforme definido pela **OWASP Smart Contract Top 10 (2025)**.

### 📚 Documentação de Segurança

Toda a análise de vulnerabilidades está no diretório `contracts/`:

1. **[contracts/OWASP_TOP10_OVERVIEW.md](./contracts/OWASP_TOP10_OVERVIEW.md)** ⭐
   - Visão geral completa das 10 vulnerabilidades
   - Dados de perdas financeiras de 2024
   - Exemplos de código vulnerável vs. seguro
   - Ferramentas de detecção recomendadas

2. **[contracts/GABARITO2.md](./contracts/GABARITO2.md)**
   - Análise linha por linha de cada vulnerabilidade
   - Mapeamento OWASP (SC01:2025 a SC10:2025)
   - Links diretos para código vulnerável e corrigido

3. **[contracts/README.md](./contracts/README.md)**
   - Índice completo de contratos
   - Estrutura de diretórios
   - Instruções de uso

### 🎯 Vulnerabilidades Cobertas

| OWASP | Tipo | Arquivo | Status |
|-------|------|---------|--------|
| SC01:2025 | Access Control Vulnerabilities | [AccessControl.sol](./contracts/vulnerable/AccessControl.sol) | ✅ |
| SC02:2025 | Price Oracle Manipulation | [PriceOracle.sol](./contracts/vulnerable/PriceOracle.sol) | ✅ |
| SC03:2025 | Logic Errors | [LogicError.sol](./contracts/vulnerable/LogicError.sol) | ✅ |
| SC04:2025 | Lack of Input Validation | [NoValidation.sol](./contracts/vulnerable/NoValidation.sol) | ✅ |
| SC05:2025 | Reentrancy Attacks | [ReEntrancy.sol](./contracts/vulnerable/ReEntrancy.sol) | ✅ |
| SC06:2025 | Unchecked External Calls | [UncheckedCall.sol](./contracts/vulnerable/UncheckedCall.sol) | ✅ |
| SC07:2025 | Flash Loan Attacks | [FlashLoanAttack.sol](./contracts/vulnerable/FlashLoanAttack.sol) | ✅ |
| SC08:2025 | Integer Overflow/Underflow | [IntegerOverflow.sol](./contracts/vulnerable/IntegerOverflow.sol) | ✅ |
| SC09:2025 | Insecure Randomness | [InsecureRandomness.sol](./contracts/vulnerable/InsecureRandomness.sol) | ✅ |
| SC10:2025 | Denial of Service (DoS) | [DenialOfService.sol](./contracts/vulnerable/DenialOfService.sol) | ✅ |

### 🔗 Referências

- **OWASP Smart Contract Top 10**: https://owasp.org/www-project-smart-contract-top-10/
- **SWC Registry**: https://swcregistry.io/
- **Dados de Segurança**: https://solidityscan.com/web3hackhub
