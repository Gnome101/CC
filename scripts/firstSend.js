const { deployContract } = require("ethereum-waffle");
const { ethers, network } = require("hardhat");
async function main() {
  const ZKCaptcha = await ethers.getContract("ZKCaptcha");
  accounts = await ethers.getSigners(); // could also do with getNamedAccounts
  deployer = accounts[0];
  console.log((await ZKCaptcha.requests()).toString());
  console.log(await ZKCaptcha.validResponse());
  console.log(await ZKCaptcha.arbNovaDID());
  console.log(await ZKCaptcha.cookieGame());

  // console.log((await gameClient.num()).toString())
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
