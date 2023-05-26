import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades";
import "dotenv/config";

const OWNER_KEY: string = process.env.OWNER_PRIVATE_KEY as string;
const USER_A_PRIVATE_KEY: string = process.env.USER_A_PRIVATE_KEY as string;
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    artifacts: "./artifacts",
  },
  networks: {
    bifrost_testnet: {
      url: process.env.BIFROST_TESTNET_URL,
      accounts: [OWNER_KEY, USER_A_PRIVATE_KEY],
    },
    evmos_testnet: {
      url: process.env.EVMOS_TESTNET_URL,
      accounts: [OWNER_KEY, USER_A_PRIVATE_KEY],
    },
    // klaytn_mainnet: {
    //   url: process.env.KLAYTN_MAINNET_URL,
    //   accounts: [OWNER_KEY],
    // },
  },
};

export default config;
