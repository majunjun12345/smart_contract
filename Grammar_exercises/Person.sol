// ^ 向上兼容
pragma solidity ^0.4.20;

// 每个合约都有个单独的地址
// 合约都有对应的账户地址，部署合约时，会消耗账户地址中的 gas

// this 表示当前合约的地址

// 字节码  字节码的多少是扣除手续费的依据
// 在合约外部可以通过合约的 ABI 调用合约内部的函数
// 也就是能够通过 ABI 实现外部与合约以及合约与合约之间的交互


// 构造函数在创建合约时对数据进行初始化
// 析构函数用于销毁数据


// constant 代表方法只读，不会更改状态变量，如果方法中有 constant 关键字，创建合约时会马上调用该方法
// 现在用 view 关键字代替


// msg.sender 是目标函数调用者的地址(账户地址)

/*
属性和方法的权限 `public internal private`
  属性的默认访问权限是 `internal`
  `interna` 和 `private` 类型的属性都不能被外部访问，只能在合约内部使用
  属性类型为 `public`，能够被外部访问，会生成和属性名相同并且返回值就是当前属性的 `get` 函数，
  且当自己重写该 `get` 函数时，会覆盖默认值；

  合约中的方法默认为 public 类型，可被外部访问

  下面这点和属性一样
  而 `internal` 和 `private` 类型的函数不能通过指针进行访问，
  哪怕是在内部通过 `this` 访问，直接访问就可以了；

  不管是属性还是方法，只有是 public 时，才可以通过合约地址进行访问；
  在合约内部 this 就表示合约地址，internal 和 private 类型不能使用 this 访问
  直接访问就可以了
*/


contract Person {

    uint _height;
    uint _age;
    address _owner;
    uint public _money;

    constructor () public {
        _height = 180;
        _age = 29;
        _owner = msg.sender;
    }

    function _money() view public returns (uint) {
        return 120;
    }

    function owner() view public returns (address) {
        return _owner;
    }

    function setHeight(uint height) public {
        _height = height;
    }

    function height() view public returns (uint) {
        return _height;
    }

    function setAge(uint age) public {
        _age = age;
    }

    function age() view public returns (uint) {
        return _age;
    }

    function kill() public {
        if (_owner==msg.sender) {
            selfdestruct(_owner);
        }
    }
}


contract Animal {

    uint _weight;
    uint private _height;
    uint internal _age;
    uint public _money;

    function test1() view public returns (uint) {
        return _weight;
    }

    function test2() view public returns (uint) {
        return _height;
    }

    function test3() view internal returns (uint) {
        return _age;
    }

    function test4() view private returns (uint) {
        return _money;
    }

    // 只能访问 public 的
    // this 表示当前合约的地址
    function testInternal1() view public returns (uint) {
        return this.test1();
    }

    // 去掉 this 后，就能够访问 internal 和 private
    function testInternal2() view public returns (uint) {
        return test4();
    }
} 


contract Animal1 {
    uint _sex;

    constructor () public {
        _sex = 1;
    }
    
    function sex() view public returns (uint) {
        return _sex;
    }
}


// 子合约继承属性和方法的权限
// 子合约只能继承 public 类型的函数
// 子合约只能继承 public 和 internal 类型的属性
contract Dog is Animal, Animal1 {
    
    
    function testInherit() view public returns (uint) {
        return _age;
    }

    // 合约方法的重写
    function sex() view public returns (uint) {
        return 2;
    }
}


// 测试值传递
contract PP{
    uint _age;

    constructor (uint age) public {
        _age = age;
    }

    function f() public {
        modify(_age);
    }

    function modify(uint age) {
        age = 300;
    }

    function age() view public returns (uint) {
        return _age;
    }

}


// 测试引用传递
contract PPp{
    string _name;

    constructor (string name) public {
        _name = name;
    }

    function f() public {
        modify(_name);
    }

    function modify(string storage name) internal {
        bytes(name)[0] = "M";
    }

    function name() view public returns (string) {
        return _name;
    }
}















