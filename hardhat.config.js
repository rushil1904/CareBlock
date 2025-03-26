require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-chai-matchers");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    development: {
      url: process.env.DEV_NETWORK_URL || "http://127.0.0.1:7545",
      accounts: process.env.PRIVATE_KEYS
        ? JSON.parse(process.env.PRIVATE_KEYS)
        : [],
    },
  },
};
