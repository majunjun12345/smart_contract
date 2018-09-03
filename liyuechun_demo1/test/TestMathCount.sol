import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MathContract.sol";

contract TestMathCount {
    function testAMulToBISRight() public {
        MathContract math = MathContract(DeployedAddresses.MathContract());

        Assert.equal(math.mulAToB(3,4), 12, "3*4 should be 12.");
    }

}