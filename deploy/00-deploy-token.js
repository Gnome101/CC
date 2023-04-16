const { network } = require("hardhat");
module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [];
  const Cookie = await deploy("Cookie", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  log("------------------------------------------------------------");
};
module.exports.tags = ["all", "Token"];
