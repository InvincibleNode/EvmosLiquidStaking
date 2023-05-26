import { ethers, upgrades } from "hardhat";
import { Contract, Wallet } from "ethers";
import { deployAllContract } from "./deployFunctions";

let stEvmosContract: Contract;
let evmosLiquidStakingContract: Contract;

const deploy = async () => {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  ({ stEvmosContract, evmosLiquidStakingContract } = await deployAllContract());

  // return contract addresses
  return {
    stEvmosContractAddress: stEvmosContract.address,
    evmosLiquidStakingContractAddress: evmosLiquidStakingContract.address,
  };
};

const main = async () => {
  console.log("deploying start ...");
  const ContractAddresses = await deploy();
  console.log("deploying end ...");
  console.log("ContractAddresses: ", ContractAddresses);
};

try {
  main();
} catch (e) {
  console.error(e);
  process.exitCode = 1;
}
