import { Contract, Wallet } from "ethers";
import { ethers, upgrades } from "hardhat";
import { BigNumber } from "ethers";
import { deployAllWithSetting } from "./deploy";
import addresses from "../scripts/address.json";

describe("Bifrost staking service test", function () {
  let evmosLiquidStakingContract: Contract;
  let stEvmosContract: Contract;

  this.beforeEach(async () => {
    // ({ evmosLiquidStakingContract, stEvmosContract } = await deployAllWithSetting());
    evmosLiquidStakingContract = await ethers.getContractAt("BfcLiquidStaking", addresses.evmosLiquidStakingContractAddress);
    stEvmosContract = await ethers.getContractAt("StBFC", addresses.stEvmosContractAddress);
  });

  it("Test stake function", async () => {
    const [deployer, userA] = await ethers.getSigners();
    console.log("deployer: ", deployer.address);
    console.log("evmos liquid staking contract: ", evmosLiquidStakingContract.address);
    console.log("stEvmos contract: ", stEvmosContract.address);

    const balance: BigNumber = await deployer.getBalance();
    console.log("before balance : ", balance.div(BigNumber.from("1000000000000000000")));

    // stake
    const stake = await evmosLiquidStakingContract.connect(deployer).stake({ value: ethers.utils.parseEther("1") });
    console.log(stake);

    // check balance
    const balance2: BigNumber = await deployer.getBalance();
    console.log("after balance : ", balance2.div(BigNumber.from("1000000000000000000")));
  });
});
