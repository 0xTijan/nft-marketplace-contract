const SimpleMarketPlace = artifacts.require("SimpleMarketPlace");

module.exports = function (deployer) {
  deployer.deploy(SimpleMarketPlace);
};
