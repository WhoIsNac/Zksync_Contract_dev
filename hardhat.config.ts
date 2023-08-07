import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
module.exports = {
  zksolc: {
    version: "1.3.5",
    compilerSource: "binary",
    settings: {

    },
    defaultNetwork: "zkSyncTestnet",
  },

  networks: {
    zkSyncTestnet: {
      accounts: ['1a55b5d50260ab2c40bc60276a096a4c36780dfd29dea1c16984bb6df367b2bf'],
      url: "https://testnet.era.zksync.dev",
      ethNetwork: "goerli", // Can also be the RPC URL of the network (e.g. `https://goerli.infura.io/v3/<API_KEY>`)
      zksync: true,
        },
  
  },
  solidity: {
    version: "0.8.17",
  },
};
