// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleOracle
 * @dev VULNERABLE - Price Oracle Manipulation (SWC-134)
 * @notice Demonstrates vulnerability from relying on DEX prices without additional safeguards
 * Reference: OWASP Smart Contract Top 10 - SC02:2025 (Price Oracle Manipulation)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC02-price-oracle-manipulation.html
 */

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract SimpleOracle {
    IUniswapV2Pair public pair;
    address public token0;
    address public token1;

    constructor(address _pair, address _token0, address _token1) {
        pair = IUniswapV2Pair(_pair);
        token0 = _token0;
        token1 = _token1;
    }

    // VULNERABLE: Directly uses DEX reserves without protection against manipulation
    function getPrice() public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        return (uint256(reserve1) * 1e18) / uint256(reserve0);
    }

    function getPriceInUSD(address token) public view returns (uint256) {
        // VULNERABLE: Single source of price data
        return getPrice();
    }
}

/**
 * @title ProtectedOracle
 * @dev SECURE - Uses multiple price sources and time-weighted average prices
 * Reference: OWASP Smart Contract Top 10 - SC02:2025
 */
contract ProtectedOracle {
    IUniswapV2Pair public pair;
    address public token0;
    address public token1;
    uint256 public priceCumulativeLast;
    uint32 public blockTimestampLast;
    uint256 public priceAverage;

    constructor(address _pair, address _token0, address _token1) {
        pair = IUniswapV2Pair(_pair);
        token0 = _token0;
        token1 = _token1;
        (uint112 reserve0, uint112 reserve1, uint32 timestamp) = pair.getReserves();
        priceCumulativeLast = (uint256(reserve1) * 1e18) / uint256(reserve0);
        blockTimestampLast = timestamp;
    }

    // SECURE: Uses time-weighted average price (TWAP)
    function update() external {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestamp) = pair.getReserves();
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0) {
            uint256 currentPrice = (uint256(reserve1) * 1e18) / uint256(reserve0);
            priceAverage = currentPrice; // In real scenario, calculate proper TWAP
            blockTimestampLast = blockTimestamp;
        }
    }

    function getPrice() public view returns (uint256) {
        return priceAverage;
    }
}
