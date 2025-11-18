// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VulnerableLogic
 * @dev VULNERABLE - Logic Errors / Business Logic Vulnerability (SWC-100)
 * @notice Demonstrates a case where a user can claim the same airdrop multiple times
 * Reference: OWASP Smart Contract Top 10 - SC03:2025 (Logic Errors)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC03-logic-errors.html
 */

contract VulnerableLogic {
    uint256 public airdropAmount = 1 ether;
    mapping(address => uint256) public balances;

    // VULNERABLE: No mechanism to prevent multiple claims
    function claimAirdrop() public {
        balances[msg.sender] += airdropAmount;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdraw failed");
    }

    receive() external payable { }
}

/**
 * @title SecureLogic
 * @dev SECURE - Proper validation of business logic
 * Reference: OWASP Smart Contract Top 10 - SC03:2025
 */
contract SecureLogic {
    uint256 public airdropAmount = 1 ether;
    mapping(address => uint256) public balances;
    mapping(address => bool) public hasClaimed;

    // SECURE: Tracking claimed status prevents duplicate claims
    function claimAirdrop() public {
        require(!hasClaimed[msg.sender], "Already claimed");
        hasClaimed[msg.sender] = true;
        balances[msg.sender] += airdropAmount;
    }

    function withdraw() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdraw failed");
    }

    receive() external payable { }
}
