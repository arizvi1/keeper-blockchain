const hre = require("hardhat");
require("dotenv").config();

async function main() {

  const keeper = await hre.ethers.deployContract("KEEPER");

  const keeperNft = await hre.ethers.deployContract("KeeperNFT");

  await keeper.waitForDeployment();

  await keeperNft.waitForDeployment();

  const keeperTB = await hre.ethers.deployContract("KeeperTB",[keeper.target, keeperNft.target, process.env.METAMASK_ADDRESS]);

  await keeperTB.waitForDeployment();
  
  console.log("Keeper deployed on address : ", keeper.target);
  console.log("Keeper NFT deployed on address : ", keeperNft.target);
  console.log("Keeper TB deployed on address : ", keeperTB.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});