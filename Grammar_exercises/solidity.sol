pragma solidity ^0.4.17;

contract Test {
    uint a;  // 状态变量

    function setA(uint x) public {  // 定义函数
        a = x;
        emit Set_A(x);  // 出发事件
    }

    event Set_A(uint a);  // 定义事件

    struct Pos {   // 定义结构
        int lat;
        int al;
    }



    address public ownerAddr;   // owner 的地址


    // 只有该合约的 owner 才能执行某个函数
    modifier owner () {          // 函数修改器，类似于 python 的装饰器,可以修改函数的行为
        require(msg.sender == ownerAddr);   // 要求发送请求的人的地址和 owner 地址相等
        _;                                  // 先进行判断再执行 mine() 函数的代码 
    }

    // 这个函数只有 owner 才能被调用
    function mine() public owner {
        a += 1;
    }


    // 静态类型语言
    // 变量在申明的时候必须指定类型

    // 数据类型


    // 一. 值类型
    // 布尔类型
    // 整形
    // 字符串常量
    // 地址类型

    // 布尔类型 
    // true / false    &&  ||  ！
    bool boola = true;
    bool boolb = false;
    // 函数名 testbool
    // public 公有方法
    // returns 返回值类型
    function testbool() public returns (bool) {
        return boola && boolb;
    }


    // 2. 整形
    // int / unit int:有符号 unit: 无符号数
    // unit8 到 unit256, 默认 unit256  表示位

    int a;
    uint b;
    int c;

    function testadd() public constant returns (int) {
        if (b > c) {
            return b + c;
        } else if (b == c) {
            return b * c;
        } else {
            return b >> 2;  // 向右移两位，相当于除法运算，等价于 b / 2^2
        }
    }


    // 3. 常量 支持任意精度 不会有溢出
    // 有理数和整型常量、字符串常量、十六进制常量、地址常量

    // 有理数整型常量
    function testLiterals() public constant returns (int) {
        return 11111 * 454;
    }
    
    // 字符串常量
    function testStringLiterals() public constant returns (string) {
        return "abs";
    }
    
    // 十六进制常量
    // 返回2个字节的字节数组
    function restHexLitels() public constant returns (bytes2) {
        return hex"abcb";   // 0: string: abs
    }
    
    // 取出字节数组中的元素，上面的 returns 和下面的 return 对应
    function restHexLiterals() public constant returns (bytes2, bytes1, bytes1) {
        bytes2 a = hex"abcb";
        return (a, a[0], a[1]);
    }
    // 0: bytes2: 0xabcb
    // 1: bytes1: 0xab
    // 2: bytes1: 0xcb


    // 4. address 地址类型 表示一个账户地址（20字节） 合约就是一个地址
    // 属性 balance 表示地址余额
    // 函数 transfer() 用来转义一特比

    // 存钱
    function deposit() public payable {
        
    }
    
    // 获取当前账号存款
    function getBalance() public constant returns (uint) {
        return this.balance;
    }
    
    // 转移以太
    function transferEther(address towho) public {
        towho.transfer(10);
    }


    // 二、引用类型
    // 比值类型更复杂，要考虑占用空间和数据存储位置的问题
    // 存储位置 memory、storage
    // memory 函数呢运行时临时分配的空间，函数调用结束后将被释放
    // starage 存储在区块链中，开销大于 memory

    // 1. 数组
    // T[K]：元素类型为 T，固定长度为 K 的数组
    // T[]：元素类型为 T，长度动态调整
    // bytes、string 是一种特殊的数组
    // string 可以转换为 bytes，bytes 类似于 byte[]
    // 属性：length
    // 函数：push()

        // 变长数组
    uint[] public u = [1, 2, 3];
    
    string s = "abcdefg";
    
    function h() public constant returns (uint) {
        // 将 string 转换为字节数组
        return bytes(s).length;    // 8
    }
    
    function f() public view returns (byte) {
        return bytes(s)[1];       // 0x62 b的ascii 码
    }
    
    // len 为变量
    function newM(uint len) constant public returns (uint) {
        // 存储在 memory 里面
        uint[] memory a = new uint[] (len);
        
        bytes memory b = new bytes(len);
        a[6] = 8;
        
        // 调用下面的 g 函数
        g([uint(1), 2, 3]);
        
        return a.length;
    }
    
    // _data 是三个元素的数组 [1,2,3]
    function g(uint[3] _data) public constant {
        
    }


    // 三、结构体和映射
    
    
    // 结构体 struct
    // 通过结构体自定义类型，用基础的数据类型组合成自定义类型
    struct Funder {
        address addr;
        uint amount;
    }
    
    Funder funder;
    
    // 给自定义的结构体赋值
    function newFunder() public {
        funder = Funder({addr: msg.sender, amount:10});
    }


    // 映射 mappings 只能用作状态变量
    // 没有键、值的集合
    
    // 定义映射
    mapping(address => uint) public balances;
    
    // 更新键值对
    function updateBalnace (uint newBalance) public {
        balances[msg.sender] = newBalance;
    }


    // 全局变量和函数
    // 1. 有关交易和区块
    msg.sender(address)       // 获取交易发送者地址
    msg.value(uint)           // 当前交易所附带的以太币，单位 位
    block.coinbase(address)   // 当前矿工的地址
    block.difficulty(uint)    // 当前块的难度
    block.number(uint)        // 当前块的块号
    block.timestamp(uint)     // 当前块的 unix 时间戳
    now(uint)                 // 当前区块的时间戳
    tx.gasprice(uint)         // 当前交易的价格
    // 有关错误处理
    // 有关数字及加密功能
    // 有关地址和合约

    // returns 里面的参数是返回的参数类型
    function testApi () public constant returns (uint) {
    
    // return msg.sender;
    // msg.sender(address)       // 获取交易发送者地址
    return msg.value;                   // 当前交易所附带的以太币，单位 位
    // block.coinbase(address)   // 当前块的地址
    // block.difficulty(uint)    // 当前块的难度
    // block.number(uint)        // 当前块的块号
    // block.timestamp(uint)     // 当前块的 unix 时间戳
    // now(uint)                 // 当前区块的时间戳
    // tx.gasprice(uint)         // 当前交易的价格
    }


    // 错误处理  回退状态
    // assert: 检查函数内部的错误，会消耗我们提供的所有 gas
    // require：检查数据的变量或合约的状态变量是否满足条件，require 不会消耗 gas，检查外部传入数据情况
    
    // 向某个地址发送以太币，要求发送的以太币必须是 2 的倍数
    // payable 表示发送以特币
    // 发送的币 和 发送的地址参数 需要自己填写
    function sendHalf(address addr) public payable returns (uint balance) {
        
        // msg.value 是指发送的以太币，也就是传递进来的参数
        require(msg.value % 2 == 0);
        // this.balance 表示当前地址余额
        return this.balance;
    }
        
    function sendHalf(address addr) public payable returns (uint balance) {
        
        require(msg.value % 2 == 0);
        
        uint balanceBeforeTranfer = this.balance;
        
        // 传入的以太币一半会被转移到输入的地址
        addr.transfer(msg.value / 2);
        
        // 那么现在的以太币就是 刚才传进来的以太币减去转移的以太币
        assert(this.balance == balanceBeforeTranfer - msg.value / 2);
        
        // 搞不懂为什么这个值还是刚传进的的值，不应该是转移后的值吗？
        return this.balance;
    }


    // 函数参数
    // 输入参数   输出参数   命名参数   参数解构
    
    // a b 是输入参数  在命令行赋值
    function simpleInput(uint a, uint b) public constant returns (uint sum) {
        sum = a + b;
    }
    // 调用函数
    function testSimpleInput() public constant returns (uint sum) {
        sum = simpleInput({a:1, b: 3});
    }

    // 参数解构
    function simpleInput(uint a, uint b) 
        public constant returns (uint sum, uint mul) {
        sum = a + b;
        mul = a * b;
    }
    
    function testSimpleInput() public constant returns (uint sum, uint mul) {
        (sum, mul) = simpleInput({a:1, b: 3});
    }

        
    function f() public constant returns (uint, bool, uint) {
        return (7, true, 2);
    }

    function g() public {
        var (x, y, z) = f();
        // 只获取后面两个值
        (, y, z) = f();
        (x, ) = (1, 2)
        // 值的交换
        (x, z) = (z, x);
    }


    // 控制结构 if else while do for break continue return ? :
        
    function add() public constant returns (uint, uint) {
        uint i = 0;
        uint sum1 = 0;
        uint sum2 = 0;
        
        while (true) {
            i++;
            
            if (i> 10) {
                break;
            }
            
            if (i % 2 == 0) {
                sum1 += i;
            } else {
                sum2 += i;
            }
        }
        
        // 如果 sum1 大于 20，那么在此基础上加 10
        sum1 = sum1 > 20 ? sum1 + 10 : sum1;

        return (sum1, sum2);
    }


}




// 可见性
// public 公开函数是合约接口的一部分，可以通过内部或者消息来进行调用，函数默认可见性是 public
// private 私有函数和状态变量尽在当前合约中可以访问，在继承的合约内，不可访问
// external 外部函数是合约接口的一部分，只能外部调用或合约内部通过消息调用
// internal 函数和状态变量只能通过内部访问，在当前合约和继承合约中可以调用，状态变量默认是 internal
contract Test {
    
    uint public data;
    
    function f(uint a) private returns (uint b) {
        return a + 1;
    }
    
    function setData(uint a) internal {
        data = a;
    }
    
    // 只能供外部调用
    function esetData(uint a) external {
        data = a;
    }
    
    
    function testsetData() public {
        setData(1);
        // 这里会报错，不过可以通过消息的方式调用
        // esetData(1);
        this.esetData(1);
    }

    function abc() public {
        // public 可以通过直接调用
        testsetData();
        // 也可以通过消息调用 this 表示消息调用
        this.testsetData();
    }
}
 
// is 是继承的关键字
contract Test2 is Test {
    function setData(uint a) internal {
        // 可以访问到 public、internal 的 data，不能访问 private
        data = a;
    }
 }

contract D {
    function readData() public {
        Test test = new Test();
        // 访问其他函数的 external
        test.esetData(1);
        // 访问其他函数的 public
        test.testsetData();
        // 这个会报错，不能访问其他函数的 internal
        //  test.setData();
        // 调用其他合约的 public 方法
        this.testsetData();
    }
}


// 构造函数，合约创建时运行的函数，主要是进行初始化操作
// 视图函数 constant/view，不会修改状态变量，新版中优先使用 view
// 纯函数 pure，既不会读取状态变量也不会修改状态变量
// 回退函数，无名函数，合约接受以太币需要用到该函数

contract Test {
    
    uint internal data;
    
    // 构造函数 constructor
    constructor (uint a) public {
        data = a;
    }
    
    event EVENT(uint a);
    
    // 视图函数 constant view
    
    function testView() public constant returns (uint) {
        // view 函数不能对状态变量进行修改
        // data = 1;
        // view 函数也不能触发事件
        // emit EVENT(1);
        return data;
    }
    
    // 纯函数
    function f() pure returns (uint) {
        // 不能读取状态变量
        // a = data;
        // this.balance;
        // 也不能访问全局函数
        // msg.value；
        return 1 * 2 + 3;
    }
    
    // 回退函数 无名函数， 转账必须带上 payable, 一个合约只能有一个回退函数
    function () public payable {
        
    }
    
 }

 // 往 Test 合约转移以太币
 contract Caller {
     function callTest(Test test) public {
         test.send(1 ether);
     }
 }
