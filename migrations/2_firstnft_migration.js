const NFT = artifacts.require("NFT");

module.exports = function (deployer) {
  deployer.deploy(NFT, [
    {
      id: 0,
      amount: 5,
      to: "0x0834CFdf2b36cE1CC1f8Ec33BaacCaE12F82d9c9",
    },
    {
      id: 1,
      amount: 50,
      to: "0xE4E55FF87ac76E581570bB007885b93621C7C8FD",
    },
    {
      id: 2,
      amount: 1,
      to: "0x0834CFdf2b36cE1CC1f8Ec33BaacCaE12F82d9c9",
    }
  ]);
};
