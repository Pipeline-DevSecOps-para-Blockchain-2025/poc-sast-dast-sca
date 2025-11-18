// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title UncheckedCall
 * @dev VULNERABLE - Unchecked External Calls (SWC-104)
 * @notice External call result is not validated
 * Reference: OWASP Smart Contract Top 10 - SC06:2025 (Unchecked External Calls)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC06-unchecked-external-calls.html
 */

contract UncheckedCall {
    mapping(address => uint256) public balances;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // VULNERABLE: Call result is not checked - execution continues even if call fails
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        // If this call fails, the function still completes successfully
        msg.sender.call{ value: amount }("");
    }

    // VULNERABLE: Using delegatecall without checking return value
    function callExternalContract(address target, bytes memory data) public {
        // Could fail silently
        target.call(data);
    }

    // VULNERABLE: No validation of external call result
    function sendFunds(address payable recipient) public {
        uint256 amount = address(this).balance;
        recipient.call{ value: amount }("");
        // No way to know if it succeeded
    }
}

/**
 * @title SafeCall
 * @dev SECURE - Proper external call validation
 * Reference: OWASP Smart Contract Top 10 - SC06:2025
 */
contract SafeCall {
    mapping(address => uint256) public balances;
    address public owner;

    event WithdrawalFailed(address indexed user, uint256 amount);
    event FundsTransferred(address indexed recipient, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // SECURE: Call result is validated
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdrawal failed");
    }

    // SECURE: Validates return value of external call
    function callExternalContract(address target, bytes memory data) public {
        (bool success,) = target.call(data);
        require(success, "External call failed");
    }

    // SECURE: Checks return value and handles failures
    function sendFunds(address payable recipient) public {
        uint256 amount = address(this).balance;
        (bool success,) = recipient.call{ value: amount }("");

        if (success) {
            emit FundsTransferred(recipient, amount);
        } else {
            emit WithdrawalFailed(recipient, amount);
            revert("Transfer failed");
        }
    }

    // SECURE: Using transfer (limited gas) is also acceptable for simple transfers
    function safeSendFunds(address payable recipient, uint256 amount) public {
        require(address(this).balance >= amount, "Insufficient balance");
        recipient.transfer(amount);
    }
}
