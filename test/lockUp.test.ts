import { Contract, Wallet } from "ethers";
import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import { deployAllWithSetting } from "./deploy";
import addresses from "../scripts/address.json";
import BfcLiquidStkaingJSON from "../artifacts/contracts/BfcLiquidStaking.sol/BfcLiquidStaking.json";
import stBFCJSON from "../artifacts/contracts/tokens/StBFC.sol/StBFC.json";

describe("Bifrost lock up service test", function () {
  let blkContract: Contract;
  let stBFCContract: Contract;
  let stakeStBfcContract: Contract;
  let bfcLiquidStakingContract: Contract;

  this.beforeEach(async () => {
    // get contract object
    blkContract = await ethers.getContractAt("Blk", addresses.blkContractAddress);
    stakeStBfcContract = await ethers.getContractAt("StakeStBfc", addresses.stakeStBfcContractAddress);
    bfcLiquidStakingContract = await ethers.getContractAt("BfcLiquidStaking", addresses.bfcLiquidStakingContractAddress);
    stBFCContract = await ethers.getContractAt("StBFC", addresses.stBFCContractAddress);
  });

  it("Test lock up(stake) function", async () => {
    const [deployer, userA] = await ethers.getSigners();
    console.log("deployer: ", deployer.address);
    console.log("blk contract: ", blkContract.address);
    console.log("stBFC contract: ", stBFCContract.address);
    console.log("stakeStBfc contract: ", stakeStBfcContract.address);
    console.log("bfcLiquidStaking contract: ", bfcLiquidStakingContract.address);

    let nonce = await ethers.provider.getTransactionCount(userA.address);
    console.log("base Nonce : ", nonce);
    let tx;
    const balance: BigNumber = await userA.getBalance();
    console.log("before balance : ", balance.div(BigNumber.from("1000000000000000000")));

    const stakeAmount = ethers.utils.parseEther("1");

    //* given
    tx = await bfcLiquidStakingContract.connect(userA).stake({ value: ethers.utils.parseEther("1"), nonce: nonce++ });
    await tx.wait();
    console.log("stake bfc at " + nonce);

    //* when
    tx = await stBFCContract.connect(userA).approve(stakeStBfcContract.address, stakeAmount, { nonce: nonce++ });
    await tx.wait();
    console.log("approve at " + nonce);
    tx = await stakeStBfcContract.connect(userA).stake(stakeAmount, { nonce: nonce++ });
    await tx.wait();
    console.log("stake stBfc at " + nonce);
    tx = await stakeStBfcContract.connect(deployer).distributeBlk();
    await tx.wait();
    console.log("distribute at " + nonce);
    tx = await stakeStBfcContract.connect(userA).claimBlk({ nonce: nonce++ });
    await tx.wait();
    console.log("claim at " + nonce);

    //* then
    const blkBalance = await blkContract.balanceOf(userA.address);
    console.log("blk balance : ", blkBalance.div(BigNumber.from("1000000000000000000")));
  });
});
