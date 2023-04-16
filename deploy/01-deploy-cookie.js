const { network } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  //const decim = ethers.utils.parseEther("1");
  let args = ["0x963C7950B97e2ce301Eb49Fb1928aA5C7fe8e8eC"];

  const CookieClicker = await deploy("CookieClicker", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
  console.log(CookieClicker.address);
  log("------------------------------------------------------------");
};
module.exports.tags = ["all", "Cookie"];
