pragma solidity ^0.4.17;

// 必须用双引号
// import "truffle/Assert.sol";
// import "truffle/DeployedAddresses.sol";
// import "../contracts/Adoption.sol";

// contract TestAdoption {
//     Adoption adoption = Adoption(DeployedAddresses.Adoption());

//     function testUserCanAdoptPet() public {
//         uint returnedId = adoption.adopt(8);
//         uint expected = 8;
//         Assert.equal(returnedId, expected, "Adoption of pet Id 8 should be recorded.");
//     }

//     function testGetAdoptAddressByPetId() public {
//         address expected = this;
//         address adopter = adoption.adopters(8);

//         Assert.equal(adopter, expected, "Owner of pet ID 8 shoule be recorded.");
//     }

//     function testGetAdopterAddressByPetIdInArray() public {
//         address expected = this;
//         address[16] memory adopters = adoption.getAdopters();
//         Assert.equal(adopters[8], expected, "Owner of Pet Id 8 should be recorded.");
//     }
// }



import "truffle/Assert.sol"; //truffle公共的库
import "truffle/DeployedAddresses.sol"; //truffle公共的库
import "../contracts/Adoption.sol";

contract TestAdoption {
    Adoption adoption = Adoption(DeployedAddresses.Adoption());

    // 测试 adopt()
    function testUserCanAdoptPet() public {
        uint returnedId = adoption.adopt(8); //调用输入参数

        uint expected = 8; //期望的结果

        Assert.equal(returnedId, expected, "Adoption of pet ID 8 should be recorded."); //判断如果没有就抛出异常
    }

    // 单个测试 测试领养地址是否正确
    function testGetAdopterAddressByPetId() public {

        // this 表示当前合约的地址
        address expected = this;

        // 数组取值方式
        address adopter = adoption.adopters(8);

        Assert.equal(adopter, expected, "Owner of pet ID 8 should be recorded.");
    }

    // 所有的测试 所有的领养者
    function testGetAdopterAddressByPetIdInArray() public {

        address expected = this;

        address[16] memory adopters = adoption.getAdopters();

        Assert.equal(adopters[8], expected, "Owner of pet ID 8 should be recorded.");
    }


}