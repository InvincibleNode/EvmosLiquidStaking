import { ethers, upgrades } from "hardhat";
import address from "./address.json";

async function main() {
  // deploy contract
  const BlkContract = await ethers.getContractFactory("Blk");
  const blkContract = await upgrades.deployProxy(BlkContract, [], {
    initializer: "initialize",
  });

  await blkContract.deployed();
  console.log("deployed BlkContract address: ", blkContract.address);

  // set init condition
  const [deployer] = await ethers.getSigners();
  let nonce = await ethers.provider.getTransactionCount(deployer.address);

  //   let tx = await blkContract.connect(deployer).setStakeStBfcAddress(address.stakeStBfcContractAddress, { nonce: nonce++ });
  //   await tx.wait();

  console.log("inviCore init condition set");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
