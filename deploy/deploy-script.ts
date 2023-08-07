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
  const address = ["0xFC959DE533fB7D3e3F483E465aa303950aaa87F8","0x620c393c4a61AEa12B847506280575C5c5f7AB35","0x98CE3D98606be03c396361894780De2Fc6df9DC8","0xABe622EbfA3bF354410B4B71eB4AEc6aDb3eC081","0x575156Afaa5140f674C1a914b542C3106A7382eE"]
    const balanceRep = [160000,600000,145000,35000,60000]
    const fees =[20,55,15,10] //future|reward|liquid|swap
   const swapAmount = 1000
   const pairTokenAddress =  "0x72906f3bC8AE0768Dd0B5791c2D69309C8DF2836"
   const decRouterAddress =  "0x2da10A1e27bF85cEdD8FFb1AbBe97e53391C0295"
  
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

  const init = await contractDeployed.initialize(address,balanceRep,fees,swapAmount,pairTokenAddress,decRouterAddress)

  console.log("Résultat de la fonction 'init' :", init);
 


  


  //const nodeHandler = await deployer.loadArtifact("IterableNodeTypeMapping");
  //const nodeHandlerContract = await deployer.deploy(artifact, [],);

}
