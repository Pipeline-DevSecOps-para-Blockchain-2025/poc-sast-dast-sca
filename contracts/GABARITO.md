# Vulnerabilidades Reconhecidas

---

## [`Wallet`](./vulnerable/AccessControl.sol) (DeFiVulnLabs)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC01:2025][SC01:2025] | [SWC-115][SWC-115] | [`transfer`](./vulnerable/AccessControl.sol#L16-L22) | [18](./vulnerable/AccessControl.sol#L18) | Autorização baseada em `tx.origin` permite phishing: um contrato malicioso pode fazer o usuário dono disparar `transfer` e drenar fundos. |

### Correção: [`ControlledWallet`](./vulnerable/AccessControl.sol#L25-L32)

---

## [`PriceOracleManipulation`](./vulnerable/PriceOracle.sol) (OWASP Smart Contract Top 10)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC02:2025][SC02:2025] | [SWC-114][SWC-114] | [`borrow`](./vulnerable/PriceOracle.sol#L22-L31) | [27](./vulnerable/PriceOracle.sol#L27) | Oráculo externo não autenticado: qualquer endereço passado no construtor pode retornar preço manipulado, permitindo empréstimo acima do colateral real. Sem checagem de staleness, desvios ou múltiplas fontes. |

### Correção: Usar oráculo confiável (e.g., Chainlink) com controle de acesso para setar `priceFeed`, checar tempo/round, limites de desvio e/ou TWAP antes de calcular o colateral.

---

## [`VulnerableBank`](./vulnerable/LogicError.sol) (DeFiVulnLabs)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC03:2025][SC03:2025] | [SWC-123][SWC-123] | [`unlockToken`](./vulnerable/LogicError.sol#L63-L78) | [70](./vulnerable/LogicError.sol#L70) | Ausência de cheque completo permite múltiplos saques: `block.timestamp` não é exigido antes da transferência e `locker.hasLockedTokens` não é invalidado, permitindo drenar o mesmo locker repetidas vezes antes do vencimento. |

### Correção: [`FixedeBank`](./vulnerable/LogicError.sol#L81-L125)

---

## [`SimpleBank`](./vulnerable/NoValidation.sol) (DeFiVulnLabs)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC04:2025][SC04:2025] | [SWC-122][SWC-122] | [`withdraw`](./vulnerable/NoValidation.sol#L40-L49) | [43](./vulnerable/NoValidation.sol#L43) | Falta de validação de entrada: aceita array vazio, pula o loop de verificação de assinaturas e transfere 1 ETH sem qualquer checagem. |

### Correção: [`VerifiedBank`](./vulnerable/NoValidation.sol#L54-L59)

---

## [`EtherStore`](./vulnerable/ReEntrancy.sol) (Solidity by Example)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC05:2025][SC05:2025] | [SWC-107][SWC-107] | [`withdraw`](./vulnerable/ReEntrancy.sol#L44-L52) | [51](./vulnerable/ReEntrancy.sol#L51) | O estado de `balances` não é atualizado antes da transferência e pode ser modificado enquanto ela acontece. |

### Correção: [`EtherStoreGuarded`](./vulnerable/ReEntrancy.sol#L60-L78)

---

## [`Lotto`](./vulnerable/UncheckedCall.sol) (sigp solidity-security-blog)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC06:2025][SC06:2025] | [SWC-104][SWC-104] | [`sendToWinner`](./vulnerable/UncheckedCall.sol#L16-L20) | [18](./vulnerable/UncheckedCall.sol#L18) | Retorno de `winner.send` é ignorado; se o envio falha (fallback cara, falta de gas), `payedOut` vira `true` e os fundos ficam presos. |

### Correção: [`LottoChecked`](./vulnerable/UncheckedCall.sol#L28-L34)

---

## [`SideEntranceLenderPool`](./vulnerable/FlashLoan.sol) (Damn Vulnerable DeFi - Challenge 4)

| OWASP  | SWC | Função | Linha(s) | Descrição |
| :----: | ----------------------------: | :----: | :------: | :-------- |
| [SC07:2025][SC07:2025] |[SWC-132][SWC-132] | [`flashLoan`](./vulnerable/FlashLoan.sol#L49-L57) | [54](./vulnerable/FlashLoan.sol#L54) | A função checa somente o balanço global (`address(this).balance`), sem diferenciar entre empréstimo e depósito. |

### Correção: [`ProtectedSideEntranceLenderPool`](./vulnerable/FlashLoan.sol#L60-L77)

---

## [`InsecureMoonToken`](./vulnerable/IntegerOverflow.sol) (serial-coder)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC08:2025][SC08:2025] | [SWC-101][SWC-101] | [`buy`](./vulnerable/IntegerOverflow.sol#L31-L35) / [`sell`](./vulnerable/IntegerOverflow.sol#L37-L44) | [34](./vulnerable/IntegerOverflow.sol#L34), [40](./vulnerable/IntegerOverflow.sol#L40) | Multiplicação e soma sem checagem podem dar overflow, permitindo pagar menos ou sacar mais tokens/ETH. |

### Correção: [`FixedMoonToken`](./vulnerable/IntegerOverflow.sol#L66-L105)

---

## [`GuessTheRandomNumber`](./vulnerable/InsecureRandomness.sol) (Solidity by Example)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC09:2025][SC09:2025] | [SWC-120][SWC-120] | [`guess`](./vulnerable/InsecureRandomness.sol#L36-L47) | [37](./vulnerable/InsecureRandomness.sol#L37) | Aleatoriedade previsível: usa `blockhash` e `block.timestamp`, que são públicos e manipuláveis, permitindo prever o número e drenar o pote. |

### Correção: Use VRF (p.ex., Chainlink) ou commit-reveal; nunca derive "random" de campos do bloco.

---

## [`Denial`](./vulnerable/DenialOfService.sol) (Ethernaut)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC10:2025][SC10:2025] | [SWC-113][SWC-113] | [`withdraw`](./vulnerable/DenialOfService.sol#L21-L31) | [26](./vulnerable/DenialOfService.sol#L26) | Erros do `partner` impossibilitam o `owner` de recuperar fundos. |

### Correção: [`Undeniable`](./vulnerable/DenialOfService.sol#L42-L52)

---

## [`ERC20`](./clean/ERC20.sol)

Implementação segura de token ERC20 sem vulnerabilidades conhecidas.

---

[SC01:2025]: https://scs.owasp.org/sctop10/SC01-AccessControlVulnerabilities/ "SC01:2025 Access Control Vulnerabilities"
[SC02:2025]: https://scs.owasp.org/sctop10/SC02-PriceOracleManipulation/ "SC02:2025 Price Oracle Manipulation"
[SC03:2025]: https://scs.owasp.org/sctop10/SC03-LogicErrors/ "SC03:2025 Logic Errors"
[SC04:2025]: https://scs.owasp.org/sctop10/SC04-LackOfInputValidation/ "SC04:2025 Lack of Input Validation"
[SC05:2025]: https://scs.owasp.org/sctop10/SC05-Reentrancy/ "SC05:2025 Reentrancy"
[SC06:2025]: https://scs.owasp.org/sctop10/SC06-UncheckedExternalCalls/ "SC06:2025 Unchecked External Calls"
[SC07:2025]: https://scs.owasp.org/sctop10/SC07-FlashLoanAttacks/ "SC07:2025 Flash Loan Attacks"
[SC08:2025]: https://scs.owasp.org/sctop10/SC08-IntegerOverflowUnderflow/ "SC08:2025 Integer Overflow/Underflow"
[SC09:2025]: https://scs.owasp.org/sctop10/SC09-InsecureRandomness/ "SC09:2025 Insecure Randomness"
[SC10:2025]: https://scs.owasp.org/sctop10/SC10-DenailOfService/ "SC10:2025 Denial Of Service"

[SWC-101]: https://swcregistry.io/docs/SWC-101/ "SWC-101: Integer Overflow and Underflow"
[SWC-104]: https://swcregistry.io/docs/SWC-104/ "SWC-104: Unchecked Call Return Value"
[SWC-107]: https://swcregistry.io/docs/SWC-107/ "SWC-107: Reentrancy"
[SWC-113]: https://swcregistry.io/docs/SWC-113/ "SWC-113: DoS with Failed Call"
[SWC-114]: https://swcregistry.io/docs/SWC-114/ "SWC-114: Transaction Order Dependence"
[SWC-115]: https://swcregistry.io/docs/SWC-115/ "SWC-115: Authorization through tx.origin"
[SWC-120]: https://swcregistry.io/docs/SWC-120/ "SWC-120: Weak Sources of Randomness from Chain Attributes"
[SWC-122]: https://swcregistry.io/docs/SWC-122/ "SWC-122: Lack of Proper Validation"
[SWC-123]: https://swcregistry.io/docs/SWC-123/ "SWC-123: Requirement Violation"
[SWC-132]: https://swcregistry.io/docs/SWC-132/ "SWC-132: Unexpected Ether balance"
