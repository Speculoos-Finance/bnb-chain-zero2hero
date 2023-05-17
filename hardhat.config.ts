import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

require('dotenv').config()

const config: HardhatUserConfig = {
  solidity: "0.8.18",
  defaultNetwork: "bscTestnet",
  networks: {
    ethereum: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      chainId: 1,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      }
    },
    bsc: {
      url: "https://bsc-dataseed4.defibit.io/",
      chainId: 56,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      }
    },
    bscTestnet: {
      url: `https://bsc.getblock.io/testnet/?api_key=${process.env.GET_BLOCK_API_KEY}`,
      chainId: 97,
      accounts: {
        mnemonic: process.env.MNEMONIC,
      }
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY 
  },
};

export default config;
