import { ethers,upgrades } from "hardhat";
import { expect } from "chai";

import { APLPresale } from "../artifacts-zk/contracts/PresaleSig.sol";
import { MockERC20 } from "../artifacts-zk/contracts/";

describe("APLPresale", function () {
  let owner: any;
  let user1: any;
  let user2: any;
  let user3: any;
  let user4: any;
  let user5: any;
  let mainUser: any;
  let token: any;
  let sigma: any;
  let presale: any;
  console.log("plop 0/");

  const RATE = 100;
  const TOTAL_SUPPLY = ethers.utils.parseEther("1000000");
  const PRESALE_SUPPLY = ethers.utils.parseEther("150000");

  const VESTING_DURATION = 345600; // 4 days

  beforeEach(async function () {
    [owner, user1, user2, user3, user4,user5,mainUser] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("MockERC20");
    console.log("owner address",owner.address)
    token = (await Token.deploy(TOTAL_SUPPLY));
    console.log("token token.address ",token.address)


    const Presale = await ethers.getContractFactory("APLPresale");
    presale = (await Presale.deploy(token.address, TOTAL_SUPPLY));
    
    await token.transfer(presale.address, PRESALE_SUPPLY);



    const Sigma = await ethers.getContractFactory("Sigma");
    sigma = await upgrades.deployProxy(Sigma,[
        [user1.address,user2.address,user3.address,presale.address,user5.address], //treasuryWall  distributionPool  poolHandler   privateSellContract ;  partenerShipWallet 
        [75000,580000,75000,250000,20000], 
        [20,55,15], //future|reward|liquid|
        10000,
        "0x2fFAa0794bf59cA14F268A7511cB6565D55ed40b"], {initializer: "initialize" }
      );

      await presale.setToken(sigma.address);



  });

  it("should allow users to buy tokens", async function () {

    console.log("in it 1");
    await presale.addToWhitelist([user1.address]);
    await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    const user1Balance = await ethers.provider.getBalance(user1.address);
    console.log("User1 balance:", ethers.utils.formatEther(user1Balance));
    await presale.connect(user1).buyTokens(ethers.utils.parseEther("1"),{value: ethers.utils.parseEther("0.001")})

    console.log("passed");
  });


  it("should prevent non-whitelisted users from buying tokens", async function () {
    await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    await expect(presale.connect(user1).buyTokens(ethers.utils.parseEther("1"),{value: ethers.utils.parseEther("0.001")})).to.be.revertedWith(
      "Not whitelisted"
    );
  });

  it("should prevent users from buying more tokens than available in the presale", async function () {
    await presale.addToWhitelist([mainUser.address]);
    await presale.changeRemainingSupply(ethers.utils.parseEther("100"));
    
    await sigma.connect(mainUser).approve(presale.address, TOTAL_SUPPLY);
    await expect(presale.connect(mainUser).buyTokens(ethers.utils.parseEther("200"),{value: ethers.utils.parseEther("999")})).to.be.revertedWith(
      "Not enough tokens left for sale"
    );
  });

  it("should allow users to withdraw tokens after the vesting period has started", async function () {
    await presale.addToWhitelist([mainUser.address]);

    const contractTokenBlalance = await sigma.balanceOf(presale.address);
    //console.log("contractTokenBlalance withdraw",contractTokenBlalance);


    //await token.connect(user1).approve(presale.address, ethers.utils.parseEther("1"));
    await presale.connect(mainUser).buyTokens(ethers.utils.parseEther("100"),{value: ethers.utils.parseEther("0.1")});
    const vestedToken = await presale.connect(mainUser).getVestedAmount(user1.address);
    //console.log("user vestedToken Amount",vestedToken);

    //const getVestingInfo = await presale.connect(user1).getVestingInfo(user1.address);
    //console.log("user vestedToken Amount",getVestingInfo);
  

    const calculateAmountWithdrawn = await presale.connect(mainUser).calculateAmountWithdrawn(mainUser.address);
    //console.log("user calculateAmountWithdrawn Amount",calculateAmountWithdrawn);

    
    await ethers.provider.send("evm_increaseTime", [VESTING_DURATION]);
    await ethers.provider.send("evm_mine", []);
  
   // console.log("after VESTING_DURATION")

    const user1BalanceBefore = await sigma.balanceOf(mainUser.address);
    //console.log("user1BalanceBefore withdraw",user1BalanceBefore);

    await presale.connect(mainUser).withdrawTokens();
    //await presale.withdrawTokens({ from: user1 });
    const user1BalanceAfter = await sigma.balanceOf(mainUser.address);
    //console.log("user1BalanceAfter withdraw",user1BalanceAfter);


    expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("15"));
  });


  it("should Wthdraw 1,4 % * Days tokens ", async function () {
    await presale.addToWhitelist([mainUser.address]);
    await presale.setRate(100,250);
    const contractTokenBlalance = await sigma.balanceOf(presale.address);
    console.log("contractTokenBlalance withdraw",contractTokenBlalance);


    await sigma.connect(mainUser).approve(presale.address, ethers.utils.parseEther("1"));
    await presale.connect(mainUser).buyTokens(ethers.utils.parseEther("100"),{value: ethers.utils.parseEther("0.1")});
    const vestedToken = await presale.connect(mainUser).getVestedAmount(mainUser.address);
    console.log("user vestedToken Amount",vestedToken);

  

    
    await presale.connect(mainUser).withdrawTokens();
    //await presale.withdrawTokens({ from: user1 });
    const user1BalanceAfter = await sigma.balanceOf(mainUser.address);
    console.log("FIRST withdraw",user1BalanceAfter);


    const time_value = 5184000; // 60 days
   // const time_value = 5270400; // 50 days

    await ethers.provider.send("evm_increaseTime", [time_value]);
    await ethers.provider.send("evm_mine", []);
  
    console.log("after 60 days")
  

    const calculateAmountWithdrawn2 = await presale.connect(mainUser).calculateAmountWithdrawn(mainUser.address);
    console.log("user calculateAmountWithdrawn AFTER 24h",calculateAmountWithdrawn2);
    await presale.connect(mainUser).withdrawTokens();

    console.log("user1 balance 1#",await sigma.connect(mainUser).balanceOf(mainUser.address));
    const time_valueBis = 864000; // 10 days

    await ethers.provider.send("evm_increaseTime", [time_valueBis]);
    await ethers.provider.send("evm_mine", []);

    console.log("after 10 days")




    const calculateAmountWithdrawn3 = await presale.connect(mainUser).calculateAmountWithdrawn(mainUser.address);
    console.log("user calculateAmountWithdrawn 3#",calculateAmountWithdrawn3);
    await presale.connect(mainUser).withdrawTokens();

    console.log("user1 balance 2#",await sigma.connect(mainUser).balanceOf(mainUser.address));

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