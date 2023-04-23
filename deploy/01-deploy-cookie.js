const { network } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  //const decim = ethers.utils.parseEther("1");
  // let args = [
  //   "0xCb0ba89F564e31180A101Df54b7971206e03ee9b", //Address of Arbitrum Goerli Mail Box Router
  //   "0x4266D8Dd66D8Eb3934c8942968d1e54214D072d3", //Address of Arbitrum Goerli Router
  //   "0xF90cB82a76492614D07B82a7658917f3aC811Ac1", //Address of Arbitrum Goerli Router
  // ];
  let args = [
    "0x89A35bc404a44c1493223079cD05a0d020076b06", //Address of Arbitrum Nova Mail Box Router
    "0x4266D8Dd66D8Eb3934c8942968d1e54214D072d3", //Address of Arbitrum Goerli Router
    "0xFc930571619B41A71a25b090eF1a9033ce93d3A8", //Address of Arbitrum Nova Router
  ];
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
