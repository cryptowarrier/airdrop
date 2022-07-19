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
  await token.setAirdropAddress(airdrop.address);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// token =>  0xfF21ef921c80c40B33f5bc486530682Cc64e91AA
// airdrop =>  0x41133d300D99eaF956C85c67C1e1cfD6E132C8B9