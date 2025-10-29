// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * Safe Contract for Slither Testing
 * 
 * This contract follows security best practices
 * and should have minimal or no vulnerabilities.
 */

contract SafeContract is ReentrancyGuard, Ownable, Pausable {
    mapping(address => uint256) private balances;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    modifier validAddress(address addr) {
        require(addr != address(0), "Invalid address");
        _;
    }
    
    modifier sufficientBalance(uint256 amount) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _;
    }
    
    constructor() {
        // Constructor is properly defined
    }
    
    /**
     * Secure deposit function
     */
    function deposit() public payable whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    /**
     * Secure withdrawal function with reentrancy protection
     */
    function withdraw(uint256 amount) 
        public 
        nonReentrant 
        whenNotPaused 
        sufficientBalance(amount) 
    {
        // State change before external call
        balances[msg.sender] -= amount;
        
        // Safe external call
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(msg.sender, amount);
    }
    
    /**
     * Emergency withdrawal - only owner
     */
    function emergencyWithdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: contractBalance}("");
        require(success, "Emergency withdrawal failed");
    }
    
    /**
     * Safe arithmetic operations (Solidity 0.8+ has built-in overflow protection)
     */
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b; // Safe in Solidity 0.8+
    }
    
    /**
     * Secure random number generation (using Chainlink VRF would be better)
     */
    function getSecureRandom(uint256 seed) public view returns (uint256) {
        // Note: Still not truly random, but better than block properties
        return uint256(keccak256(abi.encodePacked(
            seed,
            msg.sender,
            block.number,
            gasleft()
        )));
    }
    
    /**
     * Transfer ownership with proper checks
     */
    function transferOwnership(address newOwner) 
        public 
        override 
        onlyOwner 
        validAddress(newOwner) 
    {
        super.transferOwnership(newOwner);
    }
    
    /**
     * Pause contract - only owner
     */
    function pause() public onlyOwner {
        _pause();
    }
    
    /**
     * Unpause contract - only owner
     */
    function unpause() public onlyOwner {
        _unpause();
    }
    
    /**
     * Get user balance
     */
    function getBalance(address user) public view validAddress(user) returns (uint256) {
        return balances[user];
    }
    
    /**
     * Get contract balance
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * Secure receive function
     */
    receive() external payable whenNotPaused {
        deposit();
    }
    
    /**
     * Secure fallback function
     */
    fallback() external payable whenNotPaused {
        deposit();
    }
}