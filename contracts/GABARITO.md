# Vulnerabilidades Reconhecidas

---

## [`SideEntranceLenderPool`](./vulnerable/SideEntrance.sol) (Damn Vulnerable DeFi - Challenge 4)

| ID | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :- | ----------------------------: | :----: | :------: | :-------- |
| SAST-01 | [Unexpected Ether balance (SWC-132)](https://swcregistry.io/docs/SWC-132/) | [`flashLoan`](./vulnerable/SideEntrance.sol#L49-L57) | [54](./vulnerable/SideEntrance.sol#L54) | A função checa somente o balanço global (`address(this).balance`), sem diferenciar entre empréstimo e depósito. |

### Correção: [`ProtectedSideEntranceLenderPool`](./vulnerable/SideEntrance.sol#L60-L77)

---

## [`EtherStore`](./vulnerable/ReEntrancy.sol) (Solidity by Example)

| ID | Tipo de Vulnerabilidade (SWC) | Função | Linha(s) | Descrição |
| :- | ----------------------------: | :----: | :------: | :-------- |
| SAST-02 | [Reentrancy (SWC-107)](https://swcregistry.io/docs/SWC-107/) | [`withdraw`](./vulnerable/ReEntrancy.sol#L44-L52) | [51](./vulnerable/ReEntrancy.sol#L51) | O estado de `balances` não é atualizado antes da transferência e pode ser modificado enquanto ela acontece. |

---
