// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NoValidation
 * @dev VULNERABLE - Lack of Input Validation (SWC-100)
 * @notice Missing input validation for recipient address
 * Reference: OWASP Smart Contract Top 10 - SC04:2025 (Lack of Input Validation)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC04-lack-of-input-validation.html
 */

contract NoValidation {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    // VULNERABLE: No validation that _to is not address(0)
    function transfer(address _to, uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    // VULNERABLE: No validation for min/max amounts
    function setAllowance(uint256 amount) public {
        if (amount > 1_000_000 ether) {
            // Should revert, but doesn't validate
        }
    }

    // VULNERABLE: No validation of recipient count
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }
}

/**
 * @title ValidatedTransfer
 * @dev SECURE - Proper input validation
 * Reference: OWASP Smart Contract Top 10 - SC04:2025
 */
contract ValidatedTransfer {
    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
    }

    // SECURE: Validates recipient and amount
    function transfer(address _to, uint256 _amount) public {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    // SECURE: Validates allowance limits
    function setAllowance(uint256 amount) public {
        require(amount <= 1_000_000 ether, "Amount exceeds maximum");
        require(amount >= 0, "Amount cannot be negative");
    }

    // SECURE: Validates batch parameters
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Array length mismatch");
        require(recipients.length > 0 && recipients.length <= 100, "Invalid batch size");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            transfer(recipients[i], amounts[i]);
        }
    }
}
