const { network } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  //const decim = ethers.utils.parseEther("1");
  let args = [
    "0x4f543bcd78b481Ae004De7fA02034950E80F2747", //Address of Cookie Game
  ];
  const ZKCaptcha = await deploy("ZKCaptcha", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
  console.log(ZKCaptcha.address);
  log("------------------------------------------------------------");
};
module.exports.tags = ["all", "ZKCaptcha"];
