const { deployContract } = require("ethereum-waffle");
const { ethers, network } = require("hardhat");
async function main() {
  const cookieClicker = await ethers.getContract("CookieClicker");
  accounts = await ethers.getSigners(); // could also do with getNamedAccounts
  deployer = accounts[0];
  console.log((await cookieClicker.worked()).toString());
  console.log((await cookieClicker.user()).toString());
  console.log((await cookieClicker.numRes()).toString());

  console.log(
    (await cookieClicker.userCaptchaInfo(deployer.address)).toString()
  );
  console.log(cookieClicker.address);
  // console.log((await gameClient.num()).toString())
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
