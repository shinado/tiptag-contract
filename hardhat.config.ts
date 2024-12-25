import { config as dotEnvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

dotEnvConfig();

/** @type import('hardhat/config').HardhatUserConfig */
const config: HardhatUserConfig = {
  defaultNetwork: "localhost", // sepolia
  networks: {
    localhost: {
    },
    hashkeyTestnet: {
      url: "https://hashkeychain-testnet.alt.technology" || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      chainId: 133
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
      {
        version: "0.8.4",
        settings: {},
      },
      {
        version: "0.5.0",
        settings: {},
      },
      {
        version: "0.6.12",
        settings: {},
      },
    ],
  },
};

export default config;