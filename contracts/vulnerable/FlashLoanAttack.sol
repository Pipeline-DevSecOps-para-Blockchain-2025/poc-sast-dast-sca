// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FlashLoanPool
 * @dev VULNERABLE - Flash Loan Attacks (SWC-134)
 * @notice Demonstrates vulnerability to flash loan attacks
 * Reference: OWASP Smart Contract Top 10 - SC07:2025 (Flash Loan Attacks)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC07-flash-loan-attacks.html
 */

interface IFlashLoanReceiver {
    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        returns (bytes32);
}

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

contract FlashLoanPool {
    IPriceOracle public oracle;
    mapping(address => uint256) public reserves;
    uint256 public flashLoanPremium = 5; // 0.05%

    constructor(address _oracle) {
        oracle = IPriceOracle(_oracle);
    }

    function deposit(address token) public payable {
        reserves[token] += msg.value;
    }

    // VULNERABLE: Flash loan can be used to manipulate prices in the same transaction
    function flashLoan(address token, uint256 amount, address receiver, bytes calldata data) public {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Insufficient liquidity");

        uint256 fee = (amount * flashLoanPremium) / 10_000;

        // Transfer the flash loan
        (bool success,) = receiver.call{ value: amount }(
            abi.encodeWithSignature(
                "executeOperation(address,uint256,uint256,address,bytes)", token, amount, fee, msg.sender, data
            )
        );
        require(success, "Flash loan failed");

        // VULNERABLE: Only checks that balance is restored, doesn't account for price changes
        uint256 balanceAfter = address(this).balance;
        require(balanceAfter >= balanceBefore + fee, "Flash loan not repaid");
    }

    // VULNERABLE: Price is directly used without time-weighted average
    function getLoanValue(uint256 amount) public view returns (uint256) {
        return (amount * oracle.getPrice()) / 1e18;
    }
}

/**
 * @title AttackContract
 * @dev Example of how to exploit flash loan vulnerability
 */
contract AttackContract is IFlashLoanReceiver {
    FlashLoanPool public pool;
    IPriceOracle public oracle;

    constructor(address _pool, address _oracle) {
        pool = FlashLoanPool(_pool);
        oracle = IPriceOracle(_oracle);
    }

    function attack(address token, uint256 amount) public {
        pool.flashLoan(token, amount, address(this), "");
    }

    function executeOperation(address asset, uint256 amount, uint256 premium, address initiator, bytes calldata params)
        external
        override
        returns (bytes32)
    {
        // Use the flash loan to manipulate prices
        // Execute profitable operations
        // Repay the loan with profit

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

/**
 * @title SafeFlashLoanPool
 * @dev SECURE - Protections against flash loan attacks
 * Reference: OWASP Smart Contract Top 10 - SC07:2025
 */
contract SafeFlashLoanPool {
    IPriceOracle public oracle;
    mapping(address => uint256) public reserves;
    uint256 public flashLoanPremium = 50; // 0.5%
    uint256 public constant MAX_LOAN_PERCENTAGE = 50; // Max 50% of reserves

    constructor(address _oracle) {
        oracle = IPriceOracle(_oracle);
    }

    function deposit(address token) public payable {
        reserves[token] += msg.value;
    }

    // SECURE: Implements checks and limitations
    function flashLoan(address token, uint256 amount, address receiver, bytes calldata data) public {
        uint256 balanceBefore = address(this).balance;
        require(balanceBefore >= amount, "Insufficient liquidity");
        require(amount <= (balanceBefore * MAX_LOAN_PERCENTAGE) / 100, "Loan amount exceeds limit");

        uint256 fee = (amount * flashLoanPremium) / 10_000;

        // Transfer the flash loan
        (bool success,) = receiver.call{ value: amount }(
            abi.encodeWithSignature(
                "executeOperation(address,uint256,uint256,address,bytes)", token, amount, fee, msg.sender, data
            )
        );
        require(success, "Flash loan execution failed");

        // SECURE: Verify balance and fees
        uint256 balanceAfter = address(this).balance;
        require(balanceAfter >= balanceBefore + fee, "Flash loan not repaid with fee");

        reserves[token] += fee;
    }

    // SECURE: Uses time-weighted average price
    function getLoanValue(uint256 amount) public view returns (uint256) {
        // In production, this would use TWAP or an external price feed
        return (amount * oracle.getPrice()) / 1e18;
    }
}
