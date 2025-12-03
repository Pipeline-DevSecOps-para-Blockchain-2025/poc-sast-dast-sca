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

## [`EtherStore`](./vulnerable/ReEntrancy.sol) (Solidity by Example)

| OWASP | SWC | Função | Linha(s) | Descrição |
| :---: | ----------------------------: | :----: | :------: | :-------- |
| [SC05:2025][SC05:2025] | [SWC-107][SWC-107] | [`withdraw`](./vulnerable/ReEntrancy.sol#L44-L52) | [51](./vulnerable/ReEntrancy.sol#L51) | O estado de `balances` não é atualizado antes da transferência e pode ser modificado enquanto ela acontece. |

### Correção: [`EtherStoreGuarded`](./vulnerable/ReEntrancy.sol#L60-L78)

---

## [`SideEntranceLenderPool`](./vulnerable/FlashLoan.sol) (Damn Vulnerable DeFi - Challenge 4)

| OWASP  | SWC | Função | Linha(s) | Descrição |
| :----: | ----------------------------: | :----: | :------: | :-------- |
| [SC07:2025][SC07:2025] |[SWC-132][SWC-132] | [`flashLoan`](./vulnerable/FlashLoan.sol#L49-L57) | [54](./vulnerable/FlashLoan.sol#L54) | A função checa somente o balanço global (`address(this).balance`), sem diferenciar entre empréstimo e depósito. |

### Correção: [`ProtectedSideEntranceLenderPool`](./vulnerable/FlashLoan.sol#L60-L77)

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
[SC05:2025]: https://scs.owasp.org/sctop10/SC05-Reentrancy/ "SC05:2025 Reentrancy"
[SC07:2025]: https://scs.owasp.org/sctop10/SC07-FlashLoanAttacks/ "SC07:2025 Flash Loan Attacks"
[SC10:2025]: https://scs.owasp.org/sctop10/SC10-DenailOfService/ "SC10:2025 Denial Of Service"

[SWC-107]: https://swcregistry.io/docs/SWC-107/ "SWC-107: Reentrancy"
[SWC-113]: https://swcregistry.io/docs/SWC-113/ "SWC-113: DoS with Failed Call"
[SWC-114]: https://swcregistry.io/docs/SWC-114/ "SWC-114: Transaction Order Dependence"
[SWC-115]: https://swcregistry.io/docs/SWC-115/ "SWC-115: Authorization through tx.origin"
[SWC-132]: https://swcregistry.io/docs/SWC-132/ "SWC-132: Unexpected Ether balance"
