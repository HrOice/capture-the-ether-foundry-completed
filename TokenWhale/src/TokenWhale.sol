// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract TokenWhale {
    address player;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name = "Simple ERC20 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address _player) {
        player = _player;
        totalSupply = 1000;
        balanceOf[player] = 1000;
    }

    function isComplete() public view returns (bool) {
        return balanceOf[player] >= 1000000;
    }

    function _transfer(address to, uint256 value) internal {
        unchecked {
            balanceOf[msg.sender] -= value;
            balanceOf[to] += value;
        }

        emit Transfer(msg.sender, to, value);
    }

    function transfer(address to, uint256 value) public {
        require(balanceOf[msg.sender] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);

        _transfer(to, value);
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function approve(address spender, uint256 value) public {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public {
        require(balanceOf[from] >= value);
        require(balanceOf[to] + value >= balanceOf[to]);
        require(allowance[from][msg.sender] >= value);

        allowance[from][msg.sender] -= value;
        _transfer(to, value);
    }
}

// Write your exploit contract below
contract ExploitContract {
    TokenWhale public tokenWhale;

    // transferFrom 调用了 _transfer， 但是_transfer是从msg.sender中作为from发送到to
    // 也就是说，使用approval/transferFrom时，并不会减少from的余额，会减少发送者的余额。
    // 那么我是player，我委托第三方可以代我发送token，
    // 当第三方实际执行时，并不会检查msg.sender的余额，这样三方会是下溢的，再让三方转给我，
    // There is no check to msg.sender's balance when it call transferFrom.
    // So we can make it underflow through calling transferFrom.
    constructor(TokenWhale _tokenWhale) {
        tokenWhale = _tokenWhale;
    }

    // write your exploit functions below

}
