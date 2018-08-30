pragma solidity ^0.4.20;


contract MyToken {

    // 用来保存每个地址拥有的余额
    mapping(address => uint256) public balanceOf;

    // 构造函数，传入代币的供应量
    // 在构造的时候，将所有的余额给创建者，也就是创建合约的时候创建者拥有所有的代币
    // 创建者的地址通过 msg.sender 获得
    constructor(uint256 initSupply) public {
        balanceOf[msg.sender] = initSupply;
    }

    // 转移货币
    function transfer(address _to, uint256 _value) public {
        
        // 检查   原有的币大于转移的币    获得的币大于以前的币
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
    }

}