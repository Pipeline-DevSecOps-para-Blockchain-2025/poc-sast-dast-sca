/**
 * From solidity-security-blog: https://github.com/sigp/solidity-security-blog
 * Source: https://github.com/sigp/solidity-security-blog?tab=readme-ov-file#9-unchecked-call-return-values-1
 */

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity ^0.8.0;

contract Lotto {
    bool public payedOut = false;
    address payable public winner;
    uint256 public winAmount;

    // ... extra functionality here

    function sendToWinner() public virtual {
        require(!payedOut);
        winner.send(winAmount);
        payedOut = true;
    }

    function withdrawLeftOver() public {
        require(payedOut);
        payable(msg.sender).send(address(this).balance);
    }
}

contract LottoChecked is Lotto {
    function sendToWinner() public override {
        require(!payedOut);
        bool ok = winner.send(winAmount);
        require(ok);
        payedOut = true;
    }
}
