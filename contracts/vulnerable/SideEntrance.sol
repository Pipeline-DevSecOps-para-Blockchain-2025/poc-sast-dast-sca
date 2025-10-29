/**
 * From Damn Vulnerable DeFi v4: https://www.damnvulnerabledefi.xyz/challenges/side-entrance/
 * Source: https://github.com/theredguild/damn-vulnerable-defi/blob/v4.1.0/src/side-entrance/SideEntranceLenderPool.sol
 *
 * # Side Entrance
 *
 * A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.
 *
 * It has 1000 ETH in balance already, and is offering free flashloans using the deposited ETH to promote their system.
 *
 * You start with 1 ETH in balance. Pass the challenge by rescuing all ETH from the pool and depositing it in the
 * designated recovery account.
 */

// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity ^0.8.25;

import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

contract SideEntranceLenderPool {
    mapping(address => uint256) public balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];

        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{ value: amount }();

        if (address(this).balance < balanceBefore) {
            revert RepayFailed();
        }
    }
}
