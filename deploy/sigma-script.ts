import { Provider } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load contract artifact. Make sure to compile first!
import * as ContractArtifact from "../artifacts-zk/contracts/SIGMAV1.sol/Sigma.json";

const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// Address of the contract on zksync testnet
const CONTRACT_ADDRESS = "0x62B31D8ED2544975C6F95c5DBfB4db172c6e68dF";

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

  // send transaction to update the message
  const uniAddr = await contract.uniswapV2Pair();
  console.log("Transaction get uniAddr!",uniAddr);
  console.log("Transaction get contract.uniswapV2Router;!",await contract.uniswapV2Router());
  console.log("Transaction get await version!",await contract.poolHandler());
  
  const tx = await contract.updateOpenCreate(true);
  console.log("Transaction message sent!");
  await tx.wait();

  // Read message after transaction
}
