// 导入需要部署的合约, 注意是合约名，非脚本名
// 脚本中有几个合约就写几行
var Adoption = artifacts.require("Adoption");

module.exports = function(deployer) {
  deployer.deploy(Adoption);
};
