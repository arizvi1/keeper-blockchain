require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
require("dotenv").config();

module.exports = {
  networks: {
    hardhat: {
      chainId: 31337,
      allowUnlimitedContractSize: true,
    },
    mainnet: {
      url: process.env.ETHERSCAN_INFURA_API_URL,
      accounts: [process.env.METAMASK_SECRET_KEY],
      allowUnlimitedContractSize: true, 
    },
    sepolia: {
      url: process.env.SEPOLIA_API_URL,
      accounts: [process.env.METAMASK_SECRET_KEY],
      allowUnlimitedContractSize: true, 
    },
    bsctestnet: {
      url: process.env.BSCSCAN_TESTNET_API_URL,
      chainId: 97,
      accounts: [process.env.METAMASK_SECRET_KEY],
      allowUnlimitedContractSize: true, 
    }
  },
  etherscan: {
    apiKey: {
      bscTestnet: process.env.BSCSCAN_TESTNET_API_KEY,
      sepolia: process.env.ETHERSCAN_API_KEY,
      mainnet:  process.env.ETHERSCAN_API_KEY
    }
  },
  solidity: {
    compilers: [
      {
        version:  "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: `paris`
        },
      },{
        version:  "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          evmVersion: `paris`
        },
      }
    ]
  },
  gasReporter:{
    enabled: true,
    currency: "USD",
    outputFile: "gas-reporter.txt",
    coinmarketcap: process.env.COIN_MARKET_CAP_API_KEY,
    token: "BNB"
  }
};