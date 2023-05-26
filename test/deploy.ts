import { Contract, Wallet } from "ethers";
import { ethers, upgrades } from "hardhat";
import addresses from "../scripts/address.json";

const validatorAddress: String = "evmosvaloper10t6kyy4jncvnevmgq6q2ntcy90gse3yxa7x2p4";

// deploy test stKlay contract
export const deployStEvmos = async () => {
  const StEvmosContract = await ethers.getContractFactory("StEvmos");
  const stEvmosContract = await upgrades.deployProxy(StEvmosContract, [], { initializer: "initialize" });
  await stEvmosContract.deployed();

  return stEvmosContract;
};

// deploy PriceManager contract
export const deployEvmosLiquidStaking = async (stEvmosContract: Contract) => {
  const EvmosLiquidStakingContract = await ethers.getContractFactory("EvmosLiquidStaking");
  const evmosLiquidStakingContract = await upgrades.deployProxy(
    EvmosLiquidStakingContract,
    [stEvmosContract.address, addresses.stakeManager, validatorAddress],
    {
      initializer: "initialize",
    }
  );
  await evmosLiquidStakingContract.deployed();

  return evmosLiquidStakingContract;
};

// deploy entire contract with setting
export const deployAllWithSetting = async () => {
  const [deployer, stakeManager, LP, userA, userB, userC] = await ethers.getSigners();

  // ==================== token contract ==================== //
  // deploy stKlay contract
  const stEvmosContract = await deployStEvmos();

  // ==================== service contract ==================== //
  // deploy stakeNFT contract
  const evmosLiquidStakingContract = await deployEvmosLiquidStaking(stEvmosContract);

  // ==================== set init condition ==================== //
  // set stEvmos init condition
  await stEvmosContract.connect(deployer).setLiquidStakingAddress(evmosLiquidStakingContract.address);

  return {
    stEvmosContract,
    evmosLiquidStakingContract,
  };
};
