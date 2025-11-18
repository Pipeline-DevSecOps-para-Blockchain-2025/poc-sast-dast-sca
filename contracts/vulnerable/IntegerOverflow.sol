// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IntegerOverflow
 * @dev VULNERABLE - Integer Overflow and Underflow (SWC-101)
 * @notice Demonstrates arithmetic vulnerabilities with fixed-size integers
 * Reference: OWASP Smart Contract Top 10 - SC08:2025 (Integer Overflow and Underflow)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC08-integer-overflow-underflow.html
 */

contract IntegerOverflow {
    // VULNERABLE: Using uint8 which has max value of 255
    uint8 public counter = 0;
    uint8 public constant MAX_UINT8 = 255;

    // VULNERABLE: No overflow protection
    function add(uint8 a, uint8 b) public pure returns (uint8) {
        return a + b;
    }

    // VULNERABLE: No bounds checking
    function increment() public {
        counter += 1;
        // After 255, will wrap to 0
    }

    // VULNERABLE: Subtraction without checking underflow
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        return a - b; // In Solidity < 0.8, this underflows instead of reverting
    }

    // VULNERABLE: User can manipulate balance beyond expected limits
    mapping(address => uint256) public balances;

    function addBalance(uint256 amount) public {
        balances[msg.sender] += amount;
        // No check for overflow
    }

    // VULNERABLE: Token supply can overflow
    uint256 public totalSupply = type(uint256).max - 1;

    function mint(uint256 amount) public {
        totalSupply += amount; // Will overflow
    }
}

/**
 * @title SafeArithmetic
 * @dev SECURE - Safe arithmetic operations
 * Reference: OWASP Smart Contract Top 10 - SC08:2025
 */
contract SafeArithmetic {
    // SECURE: Using appropriate integer size (uint256)
    uint256 public counter = 0;

    // SECURE: Proper bounds checking
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        require(a + b >= a, "Addition overflow");
        return a + b;
    }

    // SECURE: Using Solidity 0.8+ which has built-in overflow protection
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b; // Reverts automatically on overflow in 0.8+
    }

    // SECURE: Explicit validation before operation
    function increment() public {
        require(counter < type(uint256).max, "Counter would overflow");
        counter += 1;
    }

    // SECURE: Subtract with validation
    function subtract(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Subtraction underflow");
        return a - b;
    }

    // SECURE: Balance operations with limit checks
    mapping(address => uint256) public balances;
    uint256 public constant MAX_BALANCE = 1_000_000 ether;

    function addBalance(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        require(balances[msg.sender] + amount <= MAX_BALANCE, "Balance would exceed maximum");
        balances[msg.sender] += amount;
    }

    // SECURE: Token supply with proper constraints
    uint256 public totalSupply = 0;
    uint256 public constant MAX_SUPPLY = 1_000_000 ether;

    function mint(uint256 amount) public {
        require(totalSupply + amount <= MAX_SUPPLY, "Would exceed max supply");
        totalSupply += amount;
    }

    // SECURE: Using SafeMath-like pattern
    function mulDiv(uint256 x, uint256 y, uint256 z) public pure returns (uint256) {
        require(z != 0, "Division by zero");
        require(x <= type(uint256).max / y, "Multiplication overflow");
        return (x * y) / z;
    }
}

/**
 * @title SafeToken
 * @dev SECURE - ERC20-like token with proper arithmetic
 */
contract SafeToken {
    string public name = "Safe Token";
    string public symbol = "SAFE";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 initialSupply) {
        require(initialSupply <= 1_000_000_000 ether, "Supply exceeds maximum");
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balances[msg.sender] >= value, "Insufficient balance");
        require(balances[to] + value >= balances[to], "Overflow in recipient balance");

        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Invalid address");
        require(balances[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        require(balances[to] + value >= balances[to], "Overflow in recipient balance");

        balances[from] -= value;
        balances[to] += value;
        allowance[from][msg.sender] -= value;
        return true;
    }
}
