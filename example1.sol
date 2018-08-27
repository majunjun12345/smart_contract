pragma solidity ^0.4.20;

// 发行代币的标准接口
// 文件名是 token？

// 定义接口
contract ERC20Interface {
    // 像这样写一个状态变量，会自动为我们生成一个 get 函数，也就是 name
    // 声明 public 状态变量的时候，它会自动生成对应的函数
    // 等价于 function name() view returns (string name);
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    // 带有参数的函数，必须以方法方式生成
    // function balanceOf(address _owner) view returns (uint256 balance);  // 和下面的重复了
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


// 继承上述接口合约
contract ERC20 is ERC20Interface {

    // 下面定义的属性和方法在部署后都可以显现出来


    // 和下面声明的 balanceOf 等价
    mapping (address => uint256) balanceOf;
    // 表示后一个账号可以操控前一个账号的金额，用于 approve
    mapping (address => mapping (address => uint)) internal allowed;

    // 合约都应该有一个构造函数，合约在部署的时候会首先调用构造函数
    constructor() public {
        name = "MUKE Token";
        symbol = "IMOOC";
        decimals = 0;
        totalSupply = 100000000;
        // 创建者拥有所有余额
        balanceOf[msg.sender] = totalSupply;
    }

    // 不能和上面的 balanceOf 重名
    function balanceof(address _owner) view returns (uint256 balance) {
        return balanceOf[_owner];
    }

    function transfer(address _to, uint256 _value) returns (bool success) {

        // 目标地址不为空 原有量大于转移量 溢出检查
        require(_to != address(0));
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // msg.sender 可以拿到调用这个函数的账号
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        // 发送该事件
        emit Transfer(msg.sender, _to, _value);
    }

    // 调用的人扣除 _from 账号的币,必须先写 approve
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        // 调用该函数的人发送别人的币

        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        // msg.sender 能够操控 _from 账号的钱必须大于可操控的 _value
        require(allowed[_from][msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);

        success = true;
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        // 当前账户 委托 _spender 账户 能够使用的代币 _value
        allowed[msg.sender][_spender] = _value;

        // 发送事件
        emit Approval(msg.sender, _spender, _value);

        success = true;
    }

    function allowance(address _owner, address _spender) view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}