const { ethers } = require("hardhat");

async function main() {
  const contractAddress = "0xDD3D9D3eb761f548EA0421AC06f64A26f38Ac693"; // Make sure this is your actual contract address

  console.log("Attempting to connect to contract at:", contractAddress);

  try {
    const Healthcare = await ethers.getContractFactory("HealthcareUpgradeable");
    console.log("Contract factory created");

    const contract = await Healthcare.attach(contractAddress);
    console.log("Contract attached");

    if (contract.interface) {
      console.log("Contract interface found");
      console.log("Contract functions:");
      Object.keys(contract.interface.functions).forEach((func) => {
        console.log(func);
      });
    } else {
      console.log("Contract interface is undefined");
    }

    // Test a specific function
    try {
      const owner = await contract.owner();
      console.log("Contract owner:", owner);
    } catch (error) {
      console.error("Error calling owner function:", error.message);
    }
  } catch (error) {
    console.error("Error in main function:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Unhandled error:", error);
    process.exit(1);
  });
