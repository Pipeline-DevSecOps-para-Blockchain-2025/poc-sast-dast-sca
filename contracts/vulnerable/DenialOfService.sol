/**
 * From Ethernaut: https://docs.eridian.xyz/ethereum-dev/defi-challenges/ethernaut
 * Source: https://github.com/OpenZeppelin/ethernaut/blob/d05643a4/contracts/src/levels/Denial.sol
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Denial {
    address public partner; // withdrawal partner - pay the gas, split the withdraw
    /// forge-lint: disable-next-item(screaming-snake-case-const)
    address public constant owner = address(0xA9E);
    uint256 timeLastWithdrawn;
    mapping(address => uint256) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public virtual {
        uint256 amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        /// forge-lint: disable-next-item(unchecked-call)
        partner.call{ value: amountToSend }("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }

    // allow deposit of funds
    receive() external payable { }

    // convenience function
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

contract Undeniable is Denial {
    function withdraw() public override {
        uint256 amountToSend = address(this).balance / 100;
        /// forge-lint: disable-next-item(unchecked-call)
        partner.call{ value: amountToSend, gas: 2300 }("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] += amountToSend;
    }
}
