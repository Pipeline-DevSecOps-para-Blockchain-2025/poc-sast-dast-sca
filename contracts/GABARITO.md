# Vulnerabilidades Reconhecidas

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

## [`ERC20`](./clean/ERC20.sol)

Implementação segura de token ERC20 sem vulnerabilidades conhecidas.

---

[SC05:2025]: https://scs.owasp.org/sctop10/SC05-Reentrancy/ "SC05:2025 Reentrancy"
[SC07:2025]: https://scs.owasp.org/sctop10/SC07-FlashLoanAttacks/ "SC07:2025 Flash Loan Attacks"

[SWC-107]: https://swcregistry.io/docs/SWC-107/ "SWC-107: Reentrancy"
[SWC-132]: https://swcregistry.io/docs/SWC-132/ "SWC-132: Unexpected Ether balance"
