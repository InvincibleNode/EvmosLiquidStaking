// const InviCoreContractV2 = await ethers.getContractFactory("InviCoreV2");
// const inviCoreContractV2 = await upgrades.upgradeProxy(inviCoreContract.address, InviCoreContractV2);
// await inviCoreContractV2.deployed();

import hre from "hardhat";
import { ethers, upgrades } from "hardhat";
import address from "./address.json";

async function main() {
  // deploy contract
  const StakeStBfcContract = await ethers.getContractFactory("StakeStBfc");
  const stakeStBfcContract = await upgrades.upgradeProxy(address.stakeStBfcContractAddress, StakeStBfcContract);

  await stakeStBfcContract.deployed();
  console.log("deployed StakeStBfcContract address: ", stakeStBfcContract.address);

  // set init condition
  const [deployer] = await ethers.getSigners();
  let nonce = await ethers.provider.getTransactionCount(deployer.address);

  //   let tx = await inviCoreContract.connect(deployer).setStakeNFTContract(stakeNFTContract.address, { nonce: nonce++ });
  //   await tx.wait();

  console.log("StakeStBfc init condition set");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
