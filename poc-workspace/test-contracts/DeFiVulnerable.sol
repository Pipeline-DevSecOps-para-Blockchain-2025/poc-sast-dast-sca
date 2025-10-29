// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * DeFi Vulnerable Contract for Testing
 * 
 * This contract contains DeFi-specific vulnerabilities commonly found
 * in decentralized finance applications.
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract DeFiVulnerable {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    
    IERC20 public token;
    address public owner;
    uint256 public totalSupply;
    
    // Price oracle (vulnerable to manipulation)
    uint256 public price = 100; // Simple price for testing
    
    event Deposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut);
    
    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }
    
    // Vulnerability 1: Reentrancy in DeFi context
    function withdraw(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Vulnerable: External call before state change
        token.transfer(msg.sender, amount);
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // Vulnerability 2: Price manipulation
    function swap(uint256 amountIn) public {
        require(amountIn > 0, "Amount must be positive");
        
        // Vulnerable: Using manipulable price oracle
        uint256 amountOut = (amountIn * price) / 100;
        
        token.transferFrom(msg.sender, address(this), amountIn);
        
        // Update price based on swap (vulnerable to manipulation)
        price = (price * 95) / 100; // Simple price impact
        
        balances[msg.sender] += amountOut;
        totalSupply += amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut);
    }
    
    // Vulnerability 3: Flash loan attack vector
    function flashLoan(uint256 amount) public {
        uint256 balanceBefore = token.balanceOf(address(this));
        
        // Send tokens
        token.transfer(msg.sender, amount);
        
        // Call borrower (vulnerable - no reentrancy protection)
        (bool success, ) = msg.sender.call(abi.encodeWithSignature("onFlashLoan(uint256)", amount));
        require(success, "Flash loan callback failed");
        
        // Check repayment (vulnerable - no fee)
        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Flash loan not repaid");
    }
    
    // Vulnerability 4: Unchecked arithmetic (even in 0.8+, can be bypassed)
    function unsafeCalculation(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked {
            return a * b; // Can overflow
        }
    }
    
    // Vulnerability 5: Front-running vulnerable function
    function setPrice(uint256 newPrice) public {
        // Vulnerable: No access control, can be front-run
        price = newPrice;
    }
    
    // Vulnerability 6: MEV vulnerable arbitrage
    function arbitrage() public {
        // Vulnerable: Predictable arbitrage opportunity
        uint256 profit = (token.balanceOf(address(this)) * 5) / 100;
        token.transfer(msg.sender, profit);
    }
    
    // Vulnerability 7: Slippage not protected
    function swapWithoutSlippage(uint256 amountIn) public {
        uint256 amountOut = (amountIn * price) / 100;
        
        // Vulnerable: No minimum amount out protection
        token.transferFrom(msg.sender, address(this), amountIn);
        token.transfer(msg.sender, amountOut);
    }
    
    // Vulnerability 8: Governance attack vector
    function emergencyWithdraw() public {
        // Vulnerable: Can be called by anyone if governance is compromised
        require(msg.sender == owner, "Only owner");
        token.transfer(owner, token.balanceOf(address(this)));
    }
    
    // Vulnerability 9: Liquidity manipulation
    function addLiquidity(uint256 amount) public {
        // Vulnerable: No minimum liquidity requirements
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        totalSupply += amount;
    }
    
    // Vulnerability 10: Oracle manipulation via timestamp
    function updatePriceBasedOnTime() public {
        // Vulnerable: Price based on block timestamp
        if (block.timestamp % 2 == 0) {
            price = price * 110 / 100; // 10% increase
        } else {
            price = price * 90 / 100;  // 10% decrease
        }
    }
    
    // Safe deposit function
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be positive");
        
        token.transferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        totalSupply += amount;
        
        emit Deposit(msg.sender, amount);
    }
    
    // Getter functions
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }
    
    function getPrice() public view returns (uint256) {
        return price;
    }
    
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}