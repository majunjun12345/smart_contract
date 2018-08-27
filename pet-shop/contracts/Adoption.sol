pragma solidity ^0.4.20;

contract Adoption {

    // 保存领养宠物的信息，16只宠物共16个信息
    address[16] public adopters;

    // 谁调用这个接口，谁就是领养宠物
    function adopt(uint petId) public returns (uint) {

        require(petId>=0 && petId <= 15);

        // msg.sender 是调用该方法的请求者的地址
        adopters[petId] = msg.sender;
        return petId;
    }

    // 该方法可以得到所有领养者的相关信息
    // view 不会更改状态变量 视图函数
    // 返回值是包含 16 个值的数组
    function getAdopters() public view returns (address[16]) {
        return adopters;
    }

}