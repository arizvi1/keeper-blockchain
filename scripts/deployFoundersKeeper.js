const hre = require("hardhat");
require("dotenv").config();

async function main() {

  const foundersMynt = await hre.ethers.deployContract("FoundersMynt", [process.env.PRIVATE_SAFE_ADDRESS, process.env.TEAM_TOKENS_ADDRESS, process.env.TREASURE_BOX_AND_GAMIFICATION_ADDRESS]);

  await foundersMynt.waitForDeployment();

  console.log("Founders Mynt : ", foundersMynt.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});