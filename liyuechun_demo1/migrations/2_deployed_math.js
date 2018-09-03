var MathContract = artifacts.require("./MathContract.sol");

module.exports = function(deployer) {
  deployer.deploy(MathContract);
};
