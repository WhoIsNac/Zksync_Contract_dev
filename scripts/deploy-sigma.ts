import { Wallet, utils } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for the Greeter contract`);

  // Initialize the wallet.
  const wallet = new Wallet("1a55b5d50260ab2c40bc60276a096a4c36780dfd29dea1c16984bb6df367b2bf");

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("Sigma");

  const deploymentFee = await deployer.estimateDeployFee(artifact, []);
  const address = ["0xd24af218338dc6a63706cCf7A30a3919DD34A951","0xd24af218338dc6a63706cCf7A30a3919DD34A951","0xd24af218338dc6a63706cCf7A30a3919DD34A951","0xd24af218338dc6a63706cCf7A30a3919DD34A951","0xd24af218338dc6a63706cCf7A30a3919DD34A951"]
    const balanceRep =  [75000,580000,75000,250000,20000]
    const fees =[20,55,15] //future|reward|liquid|
   const swapAmount = 1000
   const pairTokenAddress =  "0x2fFAa0794bf59cA14F268A7511cB6565D55ed40b"
   //const decRouterAddress =  "0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295"
  

 
  // Deploy this contract. The returned object will be of a `Contract` type, similarly to ones in `ethers`.
  // `greeting` is an argument for contract constructor.
  const parsedFee = ethers.utils.formatEther(deploymentFee.toString());
  console.log(`The deployment is estimated to cost ${parsedFee} ETH`);

  const contractDeployed = await deployer.deploy(artifact);

  //obtain the Constructor Arguments
  //console.log("constructor args:" + itterableContract.interface.encodeDeploy([]));

  // Show the contract info.
  const contractAddress = contractDeployed.address;
  console.log(`${artifact.contractName} was deployed to ${contractAddress}`);

  const init = await contractDeployed.initialize(address,balanceRep,fees,swapAmount,pairTokenAddress)

  console.log("Résultat de la fonction 'init' :", init);


  
 


  


  //const nodeHandler = await deployer.loadArtifact("IterableNodeTypeMapping");
  //const nodeHandlerContract = await deployer.deploy(artifact, [],);

}
