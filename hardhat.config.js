require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@typechain/hardhat");
require("hardhat-gas-reporter");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */

const {
  GOERLI_PRIVATE_KEY,
  REACT_APP_ALCHEMY_API_KEY,
  YOUR_ETHERSCAN_API_KEY,
  QUICKNODE_API_KEY,
} = process.env;

module.exports = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      url: `https://eth-goerli.alchemyapi.io/v2/${REACT_APP_ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
    bsctest: {
      url: `https://radial-wispy-dinghy.bsc-testnet.discover.quiknode.pro/${QUICKNODE_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: YOUR_ETHERSCAN_API_KEY,
  },
};
