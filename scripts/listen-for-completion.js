const { ethers, network, getNamedAccounts } = require("hardhat");

require("dotenv").config();

async function listenCompletion() {
  const cookieClicker = await ethers.getContract("CookieClicker");
  const address = await cookieClicker.captchaContract();
  let httpProvider = new ethers.providers.JsonRpcProvider(
    process.env.SEPOLIA_RPC_URL
  );
  const tokenArtifact = await artifacts.readArtifact("CaptchaPoints");
  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, httpProvider);
  const signer = wallet.provider.getSigner(wallet.address);

  const sepCaptcha = new ethers.Contract(address, tokenArtifact.abi, signer);

  console.log("Waiting for event...");
  sepCaptcha.on("captchaCompleted", async (user, start, end) => {
    console.log("Captcha Needed", user, start, end);
    await cookieClicker.confirmCaptcha(user, start, end);
  });
}

listenCompletion().catch((error) => {
  console.error(error);
  process.exit(1);
});
//
