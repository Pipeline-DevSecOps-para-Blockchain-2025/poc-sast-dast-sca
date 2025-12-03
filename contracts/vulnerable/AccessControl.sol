/**
 * From DeFiVulnLabs: https://github.com/SunWeb3Sec/DeFiVulnLabs
 * Source: https://github.com/SunWeb3Sec/DeFiVulnLabs/blob/f61f6ee5/src/test/txorigin.sol
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Wallet {
    address public owner;

    constructor() payable {
        owner = msg.sender;
    }

    function transfer(address payable _to, uint256 _amount) public virtual {
        // check with msg.sender instead of tx.origin
        require(tx.origin == owner, "Not owner");

        (bool sent,) = _to.call{ value: _amount }("");
        require(sent, "Failed to send Ether");
    }
}

contract ControlledWallet is Wallet {
    function transfer(address payable _to, uint256 _amount) public override {
        require(msg.sender == owner, "Not owner");

        (bool sent,) = _to.call{ value: _amount }("");
        require(sent, "Failed to send Ether");
    }
}
