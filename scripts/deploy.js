// scripts/deploy.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("Deploying HealthcareUpgradeable contract...");

  // Get the contract factory
  const HealthcareUpgradeable = await ethers.getContractFactory(
    "HealthcareUpgradeable"
  );

  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy as upgradeable
  const healthcareContract = await upgrades.deployProxy(
    HealthcareUpgradeable,
    [deployer.address], // Initialize with deployer as initial owner
    {
      initializer: "initialize",
      kind: "uups",
    }
  );

  // Wait for deployment to complete
  await healthcareContract.waitForDeployment();

  // Get the deployed address
  const healthcareAddress = await healthcareContract.getAddress();

  console.log("HealthcareUpgradeable deployed to:", healthcareAddress);
  console.log("Contract owner:", deployer.address);

  // Export contract addresses to a file for easy reference
  const fs = require("fs");
  const contractAddresses = {
    HealthcareUpgradeable: healthcareAddress,
    owner: deployer.address,
  };

  fs.writeFileSync(
    "./contract-addresses.json",
    JSON.stringify(contractAddresses, null, 2)
  );
  console.log("Contract addresses saved to contract-addresses.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
