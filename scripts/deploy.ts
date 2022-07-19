import { ethers } from "hardhat";

async function main() {
  const Token = await ethers.getContractFactory("MockToken");
  const token = await Token.deploy();
  await token.deployed();
  console.log("token => ", token.address);

  const Airdrop = await ethers.getContractFactory("Airdrop");
  const airdrop = await Airdrop.deploy(token.address);
  await airdrop.deployed();
  console.log("airdrop => ", airdrop.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
