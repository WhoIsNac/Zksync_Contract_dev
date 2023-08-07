import { ethers } from "hardhat";
import { expect } from "chai";
import { Wallet, Provider, Contract } from "zksync-web3";

import { APLPresale } from "../artifacts-zk/contracts/PresaleSig.sol";
import { MockERC20 } from "../artifacts-zk/contracts/";
const RICH_WALLET_PK = "0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110";

describe("APLPresale", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let token: any;
  let presale: any;
  let user3 = "0x36615Cf349d7F6344891B1e7CA7C72883F5dc049";
  console.log("plop 0/");

  const RATE = 100;
  const TOTAL_SUPPLY = ethers.utils.parseEther("1000000");
  const PRESALE_SUPPLY = ethers.utils.parseEther("150000");

  const VESTING_DURATION = 345600; // 4 days

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
   // const provider = Provider.getDefaultProvider();
   // const wallet = new Wallet(RICH_WALLET_PK, provider);
    //const deployer = new Deployer(hre, wallet);

    const Token = await ethers.getContractFactory("MockERC20");
    console.log("owner address",owner.address)
    token = (await Token.deploy(TOTAL_SUPPLY));
    console.log("token token.address ",token.address)

    const Presale = await ethers.getContractFactory("APLPresale");
    presale = (await Presale.deploy(token.address, TOTAL_SUPPLY));
    
    await token.transfer(presale.address, PRESALE_SUPPLY);



  });

  it("should allow users to buy tokens", async function () {

    console.log("in it 1");
    await presale.addToWhitelist([user1.address]);
    //await token.connect(user3).approve(presale.address, ethers.utils.parseEther("1"));
    const user1Balance = await ethers.provider.getBalance(user1.address);
    console.log("User1 balance:", ethers.utils.formatEther(user1Balance));
    await presale.connect(user1).buyTokens(ethers.utils.parseEther("1"),{value: ethers.utils.parseEther("0.001")})
    const user1SigmaBalance = await token.connect(user1).balanceOf(user1.address)
    console.log("user1SigmaBalance:", user1SigmaBalance);

    console.log("passed");
  });


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
    */

   // expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("15"));
  });

});