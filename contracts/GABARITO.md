# Vulnerabilidades Reconhecidas

---

## [`SideEntranceLenderPool`](./vulnerable/SideEntrance.sol) (Damn Vulnerable DeFi - Challenge 4)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :----: | ----------------------------: | :----: | :------: | :-------- |
| SAST-01 | SC07:2025 |[Unexpected Ether balance (SWC-132)](https://swcregistry.io/docs/SWC-132/)| [`flashLoan`](./vulnerable/SideEntrance.sol#L49-L57) |[54](./vulnerable/SideEntrance.sol#L54) | A função checa somente o balanço global (`address(this).balance`), sem diferenciar entre empréstimo e depósito. |

### Correção: [`ProtectedSideEntranceLenderPool`](./vulnerable/SideEntrance.sol#L60-L77)

---

## [`EtherStore`](./vulnerable/ReEntrancy.sol) (Solidity by Example)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-02 | SC05:2025 | [Reentrancy (SWC-107)](https://swcregistry.io/docs/SWC-107/) | [`withdraw`](./vulnerable/ReEntrancy.sol#L44-L52) |(./vulnerable/ReEntrancy.sol#L51) | O estado de `balances` não é atualizado antes da transferência e pode ser modificado enquanto ela acontece. |

### Correção: [`EtherStoreGuarded`](./vulnerable/ReEntrancy.sol#L60-L78)

---

## [`SimpleBank`](./vulnerable/AccessControl.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-03 | [SC01:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC01-access-control.html) | [Missing Authorization (SWC-109)](https://swcregistry.io/docs/SWC-109/) | [`withdrawAll`](./vulnerable/AccessControl.sol#L19-L25) | [20](./vulnerable/AccessControl.sol#L20) | A função `withdrawAll` é pública e pode ser chamada por qualquer um, permitindo o roubo dos fundos. |

### Código vulnerável: [vulnerable/AccessControl.sol](./vulnerable/AccessControl.sol)
### Correção: [`ProtectedSimpleBank`](./vulnerable/AccessControl.sol#L31-L65)

---

## [`SimpleOracle`](./vulnerable/PriceOracle.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-04 | [SC02:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC02-price-oracle-manipulation.html) | [Oracle Manipulation (SWC-134)](https://swcregistry.io/docs/SWC-134/) | [`getPrice`](./vulnerable/PriceOracle.sol#L26-L30) | [27](./vulnerable/PriceOracle.sol#L27) | O preço é obtido de uma única fonte (um par de liquidez de uma DEX), que pode ser manipulada em um único bloco. |

### Código vulnerável: [vulnerable/PriceOracle.sol](./vulnerable/PriceOracle.sol)
### Correção: [`ProtectedOracle`](./vulnerable/PriceOracle.sol#L45-L79)

---

## [`VulnerableLogic`](./vulnerable/LogicError.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-05 | [SC03:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC03-logic-errors.html) | [Business Logic Error (SWC-100)](https://swcregistry.io/docs/SWC-100) | [`claimAirdrop`](./vulnerable/LogicError.sol#L16-L19) | [17](./vulnerable/LogicError.sol#L17) | O contrato não verifica se o usuário já reivindicou o airdrop, permitindo que um mesmo endereço o faça várias vezes. |

### Código vulnerável: [vulnerable/LogicError.sol](./vulnerable/LogicError.sol)
### Correção: [`SecureLogic`](./vulnerable/LogicError.sol#L40-L56)

---

## [`NoValidation`](./vulnerable/NoValidation.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-06 | [SC04:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC04-lack-of-input-validation.html) | [Missing Input Validation (SWC-100)](https://swcregistry.io/docs/SWC-100) | [`transfer`](./vulnerable/NoValidation.sol#L19-L24) | [22](./vulnerable/NoValidation.sol#L22) | A função `transfer` não valida se o endereço do destinatário é o endereço zero, o que pode levar à queima de tokens. |

### Código vulnerável: [vulnerable/NoValidation.sol](./vulnerable/NoValidation.sol)
### Correção: [`ValidatedTransfer`](./vulnerable/NoValidation.sol#L51-L74)

---

## [`UncheckedCall`](./vulnerable/UncheckedCall.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-07 | [SC06:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC06-unchecked-external-calls.html) | [Unchecked External Call (SWC-104)](https://swcregistry.io/docs/SWC-104) | [`withdraw`](./vulnerable/UncheckedCall.sol#L24-L31) | [28](./vulnerable/UncheckedCall.sol#L28) | O resultado da chamada `call` não é verificado, o que pode fazer com que o contrato continue a execução mesmo que a transferência de fundos falhe. |

### Código vulnerável: [vulnerable/UncheckedCall.sol](./vulnerable/UncheckedCall.sol)
### Correção: [`SafeCall`](./vulnerable/UncheckedCall.sol#L69-L105)

---

## [`FlashLoanPool`](./vulnerable/FlashLoanAttack.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-08 | [SC07:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC07-flash-loan-attacks.html) | [Flash Loan Attack (SWC-134)](https://swcregistry.io/docs/SWC-134) | [`flashLoan`](./vulnerable/FlashLoanAttack.sol#L46-L73) | [50](./vulnerable/FlashLoanAttack.sol#L50) | Um flash loan pode ser usado para manipular o preço em um oráculo e então executar uma operação vantajosa no mesmo bloco. |

### Código vulnerável: [vulnerable/FlashLoanAttack.sol](./vulnerable/FlashLoanAttack.sol)
### Correção: [`SafeFlashLoanPool`](./vulnerable/FlashLoanAttack.sol#L109-L174)

---

## [`IntegerOverflow`](./vulnerable/IntegerOverflow.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-09 | [SC08:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC08-integer-overflow-underflow.html) | [Integer Overflow and Underflow (SWC-101)](https://swcregistry.io/docs/SWC-101) | [`add`](./vulnerable/IntegerOverflow.sol#L16-L19) / [`increment`](./vulnerable/IntegerOverflow.sol#L22-L26) | [17](./vulnerable/IntegerOverflow.sol#L17) / [25](./vulnerable/IntegerOverflow.sol#L25) | A adição de dois `uint8` pode resultar em um overflow, fazendo com que o valor volte a zero, sem gerar um erro. |

### Código vulnerável: [vulnerable/IntegerOverflow.sol](./vulnerable/IntegerOverflow.sol)
### Correção: [`SafeArithmetic`](./vulnerable/IntegerOverflow.sol#L63-L133)

---

## [`InsecureRandomness`](./vulnerable/InsecureRandomness.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-10 | [SC09:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC09-insecure-randomness.html) | [Insecure Randomness (SWC-120)](https://swcregistry.io/docs/SWC-120) | [`play`](./vulnerable/InsecureRandomness.sol#L18-L33) | [21](./vulnerable/InsecureRandomness.sol#L21) | O número "aleatório" é gerado a partir de `block.timestamp`, que pode ser manipulado por mineradores. |

### Código vulnerável: [vulnerable/InsecureRandomness.sol](./vulnerable/InsecureRandomness.sol)
### Correção: [`SecureRandomness`](./vulnerable/InsecureRandomness.sol#L85-L117)

---

## [`DenialOfService`](./vulnerable/DenialOfService.sol) (Exemplo Criado)

| ID | OWASP | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :-- | :---: | ----------------------------: | :----: | :------: | :-------- |
| SAST-11 | [SC10:2025](https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC10-denial-of-service.html) | [Denial of Service (SWC-113)](https://swcregistry.io/docs/SWC-113) | [`distributeRewards`](./vulnerable/DenialOfService.sol#L19-L25) / [`refundAll`](./vulnerable/DenialOfService.sol#L34-L41) | [20](./vulnerable/DenialOfService.sol#L20) / [35](./vulnerable/DenialOfService.sol#L35) | Loops não limitados podem consumir todo o gas disponível, impossibilitando a execução da função. |

### Código vulnerável: [vulnerable/DenialOfService.sol](./vulnerable/DenialOfService.sol)
### Correção: [`SafeDOS`](./vulnerable/DenialOfService.sol#L87-L190)

---

## [`ERC20`](./clean/ERC20.sol)

Implementação segura de token ERC20 sem vulnerabilidades conhecidas.

---
