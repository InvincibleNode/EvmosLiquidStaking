import { ethers } from "hardhat";
import { Contract } from "ethers";
import address from "./address.json";

const main = async () => {
  const [deployer] = await ethers.getSigners();
  let nonce = await ethers.provider.getTransactionCount(deployer.address);
  let tx;
  console.log("base Nonce : ", nonce);

  // token contracts
  const stBFCContract = await ethers.getContractAt("StBFC", address.stBFCContractAddress);
  const blkContract = await ethers.getContractAt("Blk", address.blkContractAddress);

  // service contracts
  const bfcLiquidStakingContract = await ethers.getContractAt("BfcLiquidStaking", address.bfcLiquidStakingContractAddress);
  const stakeStBfcContract = await ethers.getContractAt("StakeStBfc", address.stakeStBfcContractAddress);

  // set stBfc init condition
  tx = await stBFCContract.connect(deployer).setLiquidStakingAddress(bfcLiquidStakingContract.address, { nonce: nonce++ });
  await tx.wait();
  console.log("stBFC init condition set at " + nonce);

  // set blk init condition
  tx = await blkContract.connect(deployer).setStakeStBfcAddress(stakeStBfcContract.address, { nonce: nonce++ });
  await tx.wait();
  console.log("blk init condition set at " + nonce);

  // set bfcLiquidStaking init condition
  tx = await bfcLiquidStakingContract.connect(deployer).initialStake({ value: ethers.utils.parseEther("1000"), nonce: nonce++ });
  await tx.wait();
  console.log("bfcLiquidStaking init condition set at " + nonce);
};

main();
