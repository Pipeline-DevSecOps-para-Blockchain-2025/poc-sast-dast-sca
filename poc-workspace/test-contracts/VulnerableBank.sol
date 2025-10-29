// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * Contrato vulnerável — ideal para testes com Slither, Mythril, Echidna
 * Vulnerabilidade: Reentrância (Reentrancy)
 */
contract VulnerableBank {
    mapping(address => uint256) public balances;

    // Deposita ETH na conta do usuário
    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // Função vulnerável: permite reentrância
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Saldo insuficiente");

        // Envia o valor antes de atualizar o saldo (vulnerável)
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Falha ao enviar Ether");

        balances[msg.sender] -= _amount;
    }

    // Consulta saldo
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
}
