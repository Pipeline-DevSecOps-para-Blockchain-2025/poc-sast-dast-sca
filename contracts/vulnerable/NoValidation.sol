/**
 * From DeFiVulnLabs: https://github.com/SunWeb3Sec/DeFiVulnLabs
 * Source: https://github.com/SunWeb3Sec/DeFiVulnLabs/blob/f61f6ee5/src/test/empty-loop.sol
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/Test.sol";

/*
Name: Empty loop issue

Description:
Due to insufficient validation, an attacker can simply pass an empty array to bypass the loop and signature verification.

Mitigation:
Check the number of signatures
require(sigs.length > 0, "No signatures provided");

REF:
https://twitter.com/1nf0s3cpt/status/1673195574215213057
https://twitter.com/akshaysrivastv/status/1648310441058115592
https://dacian.me/exploiting-developer-assumptions#heading-unexpected-empty-inputs
*/

contract SimpleBank {
    struct Signature {
        bytes32 hash;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function verifySignatures(Signature calldata sig) public view {
        require(msg.sender == ecrecover(sig.hash, sig.v, sig.r, sig.s), "Invalid signature");
    }

    function withdraw(Signature[] calldata sigs) public virtual {
        // Mitigation: Check the number of signatures
        //require(sigs.length > 0, "No signatures provided");
        for (uint256 i = 0; i < sigs.length; i++) {
            Signature calldata signature = sigs[i];
            // Verify every signature and revert if any of them fails to verify.
            verifySignatures(signature);
        }
        payable(msg.sender).transfer(1 ether);
    }

    receive() external payable { }
}

contract VerifiedBank is SimpleBank {
    function withdraw(Signature[] calldata sigs) public override {
        require(sigs.length > 0, "No signatures provided");
        super.withdraw(sigs);
    }
}
