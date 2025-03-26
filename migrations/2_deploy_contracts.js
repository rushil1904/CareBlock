const Healthcare = artifacts.require("Healthcare");

module.exports = function (deployer, network, accounts) {
  const initialOwner = accounts[0]; // use the first account as the owner
  deployer.deploy(Healthcare, initialOwner);
};
