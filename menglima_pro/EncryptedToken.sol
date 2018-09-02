pragma solidity ^0.4.20;

// 发行加密货币

contract EncryptedToken {
    uint INITIAL_SUPPLY = 666666;
    mapping(address => uint) balances;

    constructor () public {
        balances[msg.sender] = INITIAL_SUPPLY;
    }

    function transfer(address _to, uint _amount) public {
        assert(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function balanceOf(address _owner) view public returns (uint) {
        return balances[_owner];
    }
}