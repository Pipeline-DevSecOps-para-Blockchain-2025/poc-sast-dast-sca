// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Vulnerable Contract for Slither Testing
 * 
 * This contract contains several intentional vulnerabilities
 * to test Slither's detection capabilities.
 */

contract VulnerableContract {
    mapping(address => uint256) public balances;
    address public owner;
    bool private locked;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Vulnerability 1: Reentrancy
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Vulnerable: External call before state change
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] -= amount;
        emit Withdrawal(msg.sender, amount);
    }
    
    // Vulnerability 2: Integer Overflow (pre-0.8.0 behavior simulation)
    function unsafeAdd(uint256 a, uint256 b) public pure returns (uint256) {
        // This would overflow in older Solidity versions
        return a + b;
    }
    
    // Vulnerability 3: Unprotected function
    function emergencyWithdraw() public {
        // Missing access control
        payable(msg.sender).transfer(address(this).balance);
    }
    
    // Vulnerability 4: Timestamp dependence
    function timeBasedFunction() public view returns (bool) {
        // Vulnerable: Using block.timestamp for critical logic
        return block.timestamp % 2 == 0;
    }
    
    // Vulnerability 5: Unchecked low-level call
    function unsafeCall(address target, bytes calldata data) public {
        // Vulnerable: Not checking return value
        target.call(data);
    }
    
    // Vulnerability 6: State variable shadowing
    address owner; // Shadows the state variable
    
    function setOwner(address _owner) public {
        owner = _owner; // Which owner is this referring to?
    }
    
    // Vulnerability 7: Unused variable
    function unusedVariable() public pure returns (uint256) {
        uint256 unused = 42; // Unused variable
        return 100;
    }
    
    // Vulnerability 8: Dangerous delegatecall
    function dangerousDelegateCall(address target, bytes calldata data) public {
        // Vulnerable: Arbitrary delegatecall
        target.delegatecall(data);
    }
    
    // Vulnerability 9: Missing zero address check
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        // Missing: require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
    
    // Vulnerability 10: Weak randomness
    function weakRandom() public view returns (uint256) {
        // Vulnerable: Predictable randomness
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
    }
    
    // Deposit function (safer)
    function deposit() public payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    // Getter functions
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    // Receive function
    receive() external payable {
        deposit();
    }
    
    // Fallback function
    fallback() external payable {
        deposit();
    }
}