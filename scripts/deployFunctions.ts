import { Contract, Wallet } from "ethers";
import { ethers, upgrades } from "hardhat";
import addresses from "../scripts/address.json";

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
  const evmosLiquidStakingContract = await upgrades.deployProxy(EvmosLiquidStakingContract, [stEvmosContract.address, addresses.stakeManager], {
    initializer: "initialize",
  });
  await evmosLiquidStakingContract.deployed();

  return evmosLiquidStakingContract;
};

// // deploy Blk contract
// export const deployBlk = async () => {
//   const BlkContract = await ethers.getContractFactory("Blk");
//   const blkContract = await upgrades.deployProxy(BlkContract, [], { initializer: "initialize" });
//   await blkContract.deployed();

//   return blkContract;
// };

// // deploy StakeStBfc contract
// export const deployStakeStBfc = async (blkContract: Contract, stBfcContract: Contract) => {
//   const StakeStBfcContract = await ethers.getContractFactory("StakeStBfc");
//   const stakeStBfcContract = await upgrades.deployProxy(StakeStBfcContract, [blkContract.address, stBfcContract.address], {
//     initializer: "initialize",
//   });
//   await stakeStBfcContract.deployed();

//   return stakeStBfcContract;
// };

// deploy entire contract with setting
export const deployAllContract = async () => {
  const [deployer, stakeManager, LP, userA, userB, userC] = await ethers.getSigners();

  // ==================== token contract ==================== //
  // deploy stKlay contract
  const stEvmosContract = await deployStEvmos();
  // deploy Blk contract
  // const blkContract = await deployBlk();

  // ==================== service contract ==================== //
  // deploy stakeNFT contract
  const evmosLiquidStakingContract = await deployEvmosLiquidStaking(stEvmosContract);
  // deploy stakeStBfc contract
  //const stakeStBfcContract = await deployStakeStBfc(blkContract, stBFCContract);

  return {
    stEvmosContract,
    evmosLiquidStakingContract,
  };
};
