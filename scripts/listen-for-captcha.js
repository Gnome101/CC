const { ethers, network, getNamedAccounts } = require("hardhat");
require("dotenv").config();

async function listenCaptcha() {
  const cookieClicker = await ethers.getContract("CookieClicker");
  const address = await cookieClicker.captchaContract();

  console.log("Waiting for event...");
  cookieClicker.on("captchaNeededForUser", async (user) => {
    console.log("Captcha Needed", user);
    let httpProvider = new ethers.providers.JsonRpcProvider(
      process.env.SEPOLIA_RPC_URL
    );
    const tokenArtifact = await artifacts.readArtifact("CaptchaPoints");
    const sepCaptcha = new ethers.Contract(
      address,
      tokenArtifact.abi,
      httpProvider
    );
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, httpProvider);
    const signer = wallet.provider.getSigner(wallet.address);
    const rawTx = {
      nonce: _hex_nonce,
      from: wallet.address,
      to: address,
      gasPrice: 23000000000,
      gasLimit: 50000,
      gas: 10000,
      value: "0x0",
      data: sepCaptcha.methods.giveUserCaptcha(user),
    };

    const tx = new Tx(rawTx, { chain: "ropsten" });
    tx.sign(privateKey);

    var serializedTx = "0x" + tx.serialize().toString("hex");
    web3.eth.sendSignedTransaction(
      serializedTx.toString("hex"),
      function (err, hash) {
        if (err) {
          reject(err);
        } else {
          resolve(hash);
        }
      }
    );
    await sepCaptcha.giveUserCaptcha(user);
  });
  //I need to call on the zkCaptcha contract
}

listenCaptcha().catch((error) => {
  console.error(error);
  process.exit(1);
});
//
