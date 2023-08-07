import { ethers } from "hardhat";

import * as hre from "hardhat";
import { expect } from "chai";
import { Wallet, Provider, Contract } from "zksync-web3";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { APLPresale } from "../artifacts-zk/contracts/PresaleSig.sol";
import { MockERC20 } from "../artifacts-zk/contracts/";

describe("APLPresale", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let token: any;
  let presale: any;
  let user3: any;
  let deployer: any;
  let userBis: any;
  console.log("plop 0/");

  const RATE = 100;
  const TOTAL_SUPPLY = ethers.utils.parseEther("1000000");
  const PRESALE_SUPPLY = ethers.utils.parseEther("150000");

  const VESTING_DURATION = 345600; // 4 days


  const RICH_WALLET_PK1 = "0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110";
  const RICH_WALLET_PK2 = "0xac1e735be8536c6534bb4f17f06f6afc73b2b5ba84ac2cfb12f7461b20c0bbe3";
  const RICH_WALLET_PK3 = "0xd293c684d884d56f8d6abd64fc76757d3664904e309a0645baf8522ab6366d9e";


  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
    const provider = Provider.getDefaultProvider();


    const wallet = new Wallet(RICH_WALLET_PK3, provider);
    
    deployer = new Deployer(hre, wallet);


    const ownerWallet = Wallet.createRandom().connect(provider);
    console.log("ownerWallet",ownerWallet.address);

    //const user1Wallet = await Wallet.fromEthSigner(user1, syncProvider);
    //const user2Wallet = await Wallet.fromEthSigner(user2, syncProvider);
    //const newDep =  new Deployer(hre, user1);

   // const user1Balance = await ethers.provider.getBalance(ownerWallet.getBalance);
    
   //const ethBalance = await ownerWallet.getBalance();
   //console.log("ownerWalletBalance",ethBalance);


    
    user3 = new Wallet(RICH_WALLET_PK2, provider);
    userBis  = new Deployer(hre, user3);

       
    console.log("deployerBalance",await wallet.getBalance());

    const artifact = await deployer.loadArtifact("MockERC20");
    token = await  deployer.deploy(artifact, [TOTAL_SUPPLY]);

    console.log("token token.address ",token.address)

    const PresaleArtifact = await deployer.loadArtifact("APLPresale");
    presale = await deployer.deploy(PresaleArtifact, [(token.address),(TOTAL_SUPPLY)]);

    console.log("After Presale Contract Init",presale.address)

    //const tx = await token.approve(presale.address,PRESALE_SUPPLY);
    //await tx.wait();
      
    await token.transfer(presale.address, PRESALE_SUPPLY);

    console.log("balance of contract",await token.balanceOf(presale.address));




  });

  it("should allow users to buy tokens", async function () {


    //console.log("in it 1");
    await presale.addToWhitelist([user3.address]);
    //console.log("user3.address",user3.address);
    console.log("user3",await user3.getBalance());

    //await token.connect(user3).approve(presale.address, ethers.utils.parseEther("1"));
   // await presale.connect(deployer).buyTokens(ethers.utils.parseEther("10"),{value: ethers.utils.parseEther("0.001")})
   // const vestedToken = await presale.getVestedAmount(user1.address);
    //console.log("user vestedToken Amount",vestedToken);
    //const user2SigmaBalance = await token.balanceOf(user2.address)
    //console.log("user1SigmaBalance:", user2SigmaBalance);

    console.log("passed  buy tokens");
  });

/*  
  it("should prevent non-whitelisted users from buying tokens", async function () {
    await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    await presale.connect(user1).buyTokens(ethers.utils.parseEther("1"),{value: ethers.utils.parseEther("0.001")})
  });

  it("should prevent users from buying more tokens than available in the presale", async function () {
    await presale.addToWhitelist([user1.address]);
    await presale.changeRemainingSupply(ethers.utils.parseEther("100"));
    
    await token.connect(user1).approve(presale.address, TOTAL_SUPPLY);
    await expect(presale.connect(user1).buyTokens(ethers.utils.parseEther("200"),{value: ethers.utils.parseEther("999")})).to.be.revertedWith(
      "Not enough tokens left for sale"
    );
  });

  it("should allow users to withdraw tokens after the vesting period has started", async function () {
    await presale.addToWhitelist([user1.address]);

    const contractTokenBlalance = await token.balanceOf(presale.address);
    //console.log("contractTokenBlalance withdraw",contractTokenBlalance);


    await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    await presale.connect(user1).buyTokens(ethers.utils.parseEther("100"),{value: ethers.utils.parseEther("0.1")});
    const vestedToken = await presale.connect(user1).getVestedAmount(user1.address);
    //console.log("user vestedToken Amount",vestedToken);

    //const getVestingInfo = await presale.connect(user1).getVestingInfo(user1.address);
    //console.log("user vestedToken Amount",getVestingInfo);
  

    const calculateAmountWithdrawn = await presale.connect(user1).calculateAmountWithdrawn(user1.address);
    //console.log("user calculateAmountWithdrawn Amount",calculateAmountWithdrawn);

    
    await ethers.provider.send("evm_increaseTime", [VESTING_DURATION]);
    await ethers.provider.send("evm_mine", []);
  
   // console.log("after VESTING_DURATION")

    const user1BalanceBefore = await token.balanceOf(user1.address);
    console.log("user1BalanceBefore withdraw",user1BalanceBefore);

    await presale.connect(user1).withdrawTokens();
    //await presale.withdrawTokens({ from: user1 });
    const user1BalanceAfter = await token.balanceOf(user1.address);
    //console.log("user1BalanceAfter withdraw",user1BalanceAfter);


    expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("15"));
  });


  it("should Wthdraw 1,4 % * Days tokens ", async function () {
    await presale.addToWhitelist([user1.address]);
    await presale.setRate(100,250);
    const contractTokenBlalance = await token.balanceOf(presale.address);
    console.log("contractTokenBlalance withdraw",contractTokenBlalance);


    await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    await presale.connect(user1).buyTokens(ethers.utils.parseEther("100"),{value: ethers.utils.parseEther("0.1")});
    const vestedToken = await presale.connect(user1).getVestedAmount(user1.address);
    console.log("user vestedToken Amount",vestedToken);

  

    
    await presale.connect(user1).withdrawTokens();
    //await presale.withdrawTokens({ from: user1 });
    const user1BalanceAfter = await token.balanceOf(user1.address);
    console.log("FIRST withdraw",user1BalanceAfter);


    const time_value = 5184000; // 60 days
   // const time_value = 5270400; // 50 days

    await ethers.provider.send("evm_increaseTime", [time_value]);
    await ethers.provider.send("evm_mine", []);
  
    console.log("after 60 days")
  

    const calculateAmountWithdrawn2 = await presale.connect(user1).calculateAmountWithdrawn(user1.address);
    console.log("user calculateAmountWithdrawn AFTER 24h",calculateAmountWithdrawn2);
    await presale.connect(user1).withdrawTokens();

    console.log("user1 balance 1#",await token.connect(user1).balanceOf(user1.address));
    const time_valueBis = 864000; // 10 days

    await ethers.provider.send("evm_increaseTime", [time_valueBis]);
    await ethers.provider.send("evm_mine", []);

    console.log("after 10 days")




    const calculateAmountWithdrawn3 = await presale.connect(user1).calculateAmountWithdrawn(user1.address);
    console.log("user calculateAmountWithdrawn 3#",calculateAmountWithdrawn3);
    await presale.connect(user1).withdrawTokens();

    console.log("user1 balance 2#",await token.connect(user1).balanceOf(user1.address));

    /*
    const time_valueTres = 864000; // 10 days

    await ethers.provider.send("evm_increaseTime", [time_valueTres]);
    await ethers.provider.send("evm_mine", []);




    const calculateAmountWithdrawn4 = await presale.connect(user1).calculateAmountWithdrawn(user1.address);
    console.log("user calculateAmountWithdrawn 3#",calculateAmountWithdrawn4);
    await presale.connect(user1).withdrawTokens();

    console.log("user1 balance 3#",await token.connect(user1).balanceOf(user1.address));

   // expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("15"));
  });

*/
  
});