const hre = require("hardhat");
require("dotenv").config();

async function main() {

  const FoundersKeeper = await hre.ethers.deployContract("FoundersKeeper", [process.env.PRIVATE_SAFE_ADDRESS, process.env.TEAM_TOKENS_ADDRESS, process.env.TB_AND_GA]);

  await FoundersKeeper.waitForDeployment();

  console.log("Founders Keeper : ", FoundersKeeper.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});