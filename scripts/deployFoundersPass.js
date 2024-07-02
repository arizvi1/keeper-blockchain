const hre = require("hardhat");
require("dotenv").config();

async function main() {

  const foundersPass = await hre.ethers.deployContract("FoundersPass", [process.env.USDT_ADDRESS, process.env.TIER1_METADATA, process.env.TIER2_METADATA]);

  await foundersPass.waitForDeployment();

  console.log("Founders Pass : ", foundersPass.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});