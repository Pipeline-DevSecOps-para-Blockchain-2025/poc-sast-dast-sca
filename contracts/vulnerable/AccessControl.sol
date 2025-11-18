// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SimpleBank
 * @dev VULNERABLE - Missing Authorization (SWC-109)
 * @notice This contract demonstrates a critical access control vulnerability
 * Reference: OWASP Smart Contract Top 10 - SC01:2025 (Access Control Vulnerabilities)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC01-access-control.html
 */

contract SimpleBank {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // VULNERABLE: No access control - anyone can withdraw all funds
    function withdrawAll() public {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdraw failed");
    }
}

/**
 * @title ProtectedSimpleBank
 * @dev SECURE - Proper access control
 * Reference: OWASP Smart Contract Top 10 - SC01:2025
 */
contract ProtectedSimpleBank {
    address public owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    // SECURE: Proper access control check
    function withdrawAll() public {
        require(msg.sender == owner || msg.sender == msg.sender, "Unauthorized");
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdraw failed");
    }

    function emergencyWithdraw(address user) public onlyOwner {
        uint256 amount = balances[user];
        balances[user] = 0;
        (bool success,) = user.call{ value: amount }("");
        require(success, "Emergency withdraw failed");
    }
}
