const fs = require("fs-extra");
const path = require("path");

const srcDir = path.join(__dirname, "./artifacts/contracts/Healthcare.sol");
const destDir = path.join(__dirname, "./healthcare-dapp/src/artifacts");

fs.copy(srcDir, destDir, { overwrite: true }, (err) => {
  if (err) {
    console.error("Error copying artifacts:", err);
  } else {
    console.log("Artifacts copied successfully!");
  }
});
