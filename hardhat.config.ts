import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-gas-reporter';
import 'solidity-coverage';
import './tasks/deploy';
import './tasks/signer';

import * as dotenv from 'dotenv';
import { HardhatUserConfig, task } from 'hardhat/config';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.15",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      mining: {
        auto: false,
        interval: 500,
      },
    },
    mumbai: {
      url: process.env.MUMBAI_RPC || "",
      accounts: {
        mnemonic: process.env.MUMBAI_MNEMONIC,
      },
    },
    polygon: {
      url: process.env.POLYGON_RPC || "",
      accounts: {
        mnemonic: process.env.POLYGON_MNEMONIC,
      },
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};

export default config;
