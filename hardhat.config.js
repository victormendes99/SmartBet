require("@nomicfoundation/hardhat-toolbox");
require('hardhat-docgen');

const { vars } = require("hardhat/config");


const INFURA_API_KEY = vars.get("INFURA_API_KEY");
const SEPOLIA_PRIVATE_KEY = vars.get("SEPOLIA_PRIVATE_KEY");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.25",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  docgen: {
    path: './docs', // Path to the output documentation directory
    clear: true,   // Clear the output directory before generating new docs
    runOnCompile: true, // Generate docs automatically on compilation
  },
};
