const SimpleMarketplace = artifacts.require("SimpleMarketplace");

module.exports = function (deployer) {
  deployer.deploy(SimpleMarketplace);
};
