import { Provider } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load contract artifact. Make sure to compile first!
import * as ContractArtifact from "../artifacts-zk/contracts/nodeHandlerV2.sol/NodeHandlerV3.json";

const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// Address of the contract on zksync testnet
const CONTRACT_ADDRESS = "0xaB4850a791879a9c4b1f5a4Fe3E4bE677c87df3a";

if (!CONTRACT_ADDRESS) throw "⛔️ Contract address not provided";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running script to interact with contract ${CONTRACT_ADDRESS}`);

  // Initialize the provider.
  // @ts-ignore
  const provider = new Provider(hre.userConfig.networks?.zkSyncTestnet?.url);
  const signer = new ethers.Wallet(PRIVATE_KEY, provider);

  // Initialise contract instance
  const contract = new ethers.Contract(
    CONTRACT_ADDRESS,
    ContractArtifact.abi,
    signer
  );

  // Read message from contract
  //console.log(`The message is ${await contract.greet()}`);
  //const deploymentFee = await signer.estimateDeployFee(artifact, []);

  console.log("Transaction get contract.uniswapV2Router;!",await contract.token());
  const estimatedGas = await contract.estimateGas.addNodeType("tier1",[40,86400,40,40,20,30,2600,1,100000,100])
  console.log("estimatedGas",estimatedGas);

   // const tx = await contract.addNodeType("tier1",[40,86400,40,40,20,30,2600,1,100000,100]) //nodePirce|claimTime|rewardAmount|claimTaxBeforeTime|cashoutFees|Max|Maxlvlup|maxlvlupuser|burntime|parteairNodeprice

 // const tx = await contract.setToken("0x62B31D8ED2544975C6F95c5DBfB4db172c6e68dF");
  console.log("Transaction message sent!");
 // await tx.wait();

  //console.log("Transaction message sent!",tx);


  

  // Read message after transaction
}
