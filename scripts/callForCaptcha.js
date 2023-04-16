const { deployContract } = require("ethereum-waffle");
const { ethers, network } = require("hardhat");
async function main() {
  const cookieClicker = await ethers.getContract("CookieClicker");
  accounts = await ethers.getSigners(); // could also do with getNamedAccounts
  deployer = accounts[0];
  await cookieClicker.callForCaptcha(deployer.address);

  // console.log((await gameClient.num()).toString())
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
