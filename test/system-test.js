const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const fetch = require("node-fetch"); // const bigDecimal = require("js-big-decimal");
describe("Cookie Clicker ", function () {
  //This is every contract or that we will call on/use
  let cookieClicker, deployer;
  const brick = ethers.utils.parseEther("100000");
  const stack = ethers.utils.parseEther("10000");
  const band = ethers.utils.parseEther("1000");
  const hundy = ethers.utils.parseEther("100");

  beforeEach(async () => {
    accounts = await ethers.getSigners(); // could also do with getNamedAccounts
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["all"]);
    cookieClicker = await ethers.getContract("CookieClicker");
  });

  describe("Deployment", function () {
    it("deployed all contracts, all address exist ", async () => {
      assert(cookieClicker.address);
    });
  });
  describe("Constructor", function () {});

  describe("User Actions ", function () {
    it("user can click", async () => {
      await cookieClicker.click();
      const cookieInfo = await cookieClicker.userCookie(deployer.address);
      console.log(cookieInfo.totalClicks.toString());
    });
    it("user can purchase an upgrade", async () => {
      await clickThisMany(10);
      await cookieClicker.purchaseUpgrade("1");
    });
    it("user can start a session", async () => {
      //First the user needs to create a hash
      const browserID = 123;
      const sessionHash = await cookieClicker.createHash(
        browserID,
        deployer.address
      );
      await cookieClicker.startSession(sessionHash, 100);
      // console.log(
      //   (await cookieClicker.mostRecentUserSession(deployer.address)).toString()
      // );
      //We can verify that our browserID is correct
      const valid = await cookieClicker.verifySession(
        browserID,
        deployer.address
      );
      assert.ok(valid);
    });
    beforeEach(async () => {
      //Before each I want you to create a hash
      const browserID = 123;
      const sessionHash = await cookieClicker.createHash(
        browserID,
        deployer.address
      );
      await cookieClicker.startSession(sessionHash, 1000);
    });
    describe("User Game Actions ", function () {
      it("we can submit clicks during a session", async () => {
        await cookieClicker.addClick(deployer.address, "100");
        // console.log(
        //   (
        //     await cookieClicker.getUserCookieBalance(deployer.address)
        //   ).toString()
        // );
      });
      it("we can submit clicks during a session and then end it", async () => {
        //Might make it so that only the clicking is done abstracted
        //Make it so that the other stuff is just submitted by us but not included in the bundle
        await cookieClicker.addClick(deployer.address, "100");
        const updatedCookieClicker = {
          totalClicks: 19,
          totalSpent: 10,
          cookiePerSecond: 1,
          interestLastComputed: 2,
          clickModifier: 3,
        };
        await cookieClicker.completeSession(
          123,
          deployer.address,
          updatedCookieClicker
        );
      });
      it("user can submit clicks, purchase upgrade, and end it 121", async () => {
        //Might make it so that only the clicking is done abstracted
        //Make it so that the other stuff is just submitted by us but not included in the bundle
        await cookieClicker.addClick(deployer.address, "100");
        //User now has 100 cookies in their browsers cookie
        console.log(
          ("Interest Before:",
          await cookieClicker.getSessionUserInterest(
            deployer.address
          )).toString()
        );
        await cookieClicker.purchaseUpgradeForUser(deployer.address, 1);
        const timeStamp = (await ethers.provider.getBlock("latest")).timestamp;

        await ethers.provider.send("evm_mine", [timeStamp + 100]);
        console.log(
          ("Interest After:",
          await cookieClicker.getSessionUserInterest(
            deployer.address
          )).toString()
        );
        console.log(
          "Current Reward Per Click:",
          (await cookieClicker.simulateClick(deployer.address)).toString()
        );
        await cookieClicker.purchaseUpgradeForUser(deployer.address, 2);
        console.log(
          "Current Reward Per Click:",
          (await cookieClicker.simulateClick(deployer.address)).toString()
        );
        //await cookieClicker.addClick(deployer.address, "100");
        console.log(
          (await cookieClicker.userCookie(deployer.address)).toString()
        );
        await cookieClicker.addClick(deployer.address, "200");
        await cookieClicker.completeSession(123, deployer.address);
        console.log(
          (await cookieClicker.userCookie(deployer.address)).toString()
        );
      });
      it("we can give a captcha, user can solve it 33", async () => {
        await cookieClicker.giveUserCaptcha(deployer.address);
        const accounts = config.networks.hardhat.accounts;
        const index = 0; // first wallet, increment for next wallets
        const wallet1 = ethers.Wallet.fromMnemonic(
          accounts.mnemonic,
          accounts.path + `/${index}`
        );
        console.log("PublicKey:", wallet1.publicKey);
        const response = await getCaptcha();
        const fs = require("fs");

        const base64Code = response;

        const imageBuffer = Buffer.from(base64Code, "base64");

        // Write the buffer to a file
        fs.writeFile("output.jpg", imageBuffer, (err) => {
          if (err) throw err;
          console.log("JPG photo has been generated successfully!");
        });

        const ans = await askQuestion("What is it saying: ");
        console.log(ans);
        const proof = await getProof(
          "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
          ans
        );
        const destinationID = 421613;
        const amount = await cookieClicker.getGasQuote(destinationID, 100000);
        console.log(amount.toString());
        await cookieClicker.submitCaptcha(
          destinationID,
          "0x480D8978316a3cceCcaA78f16fb57A63cd51Da81",
          0,
          proof,
          { value: "0" }
        );

        //rough sketch of sending args to the prover
      });
      it("user can mint a bond 24", async () => {
        console.log((await cookieClicker.returnedNum()).toString());
        console.log((await cookieClicker.worked()).toString());
      });
    });
  });
  async function clickThisMany(num) {
    for (let i = 0; i < num; i++) {
      await cookieClicker.click();
    }
  }
  // rough sketch of querying the API
  async function getCaptcha() {
    const captchaAPI =
      "https://sx2mbwnkk9.execute-api.us-east-2.amazonaws.com/default/zkaptcha-py";
    try {
      const response = await fetch(captchaAPI);
      if (!response.ok) {
        throw new Error(`HTTP error! Status: ${response.status}`);
      }
      const resptext = await response.text();
      const b64data = JSON.parse(resptext).png;
      const pngData = b64data.replace(/-/g, "+").replace(/_/g, "/");
      return pngData;
    } catch (error) {
      console.error("Error fetching captcha:", error);
      return null;
    }
  }
  const readline = require("readline");

  function askQuestion(query) {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    return new Promise((resolve) =>
      rl.question(query, (ans) => {
        rl.close();
        resolve(ans);
      })
    );
  }
  // rough sketch of sending args to the prover

  const proverAPI =
    "https://urrc4cdvzg.execute-api.us-east-2.amazonaws.com/default/zkaptchaprover";
  const getProof = async (pkey, captcha_text) => {
    return await fetch(proverAPI, {
      method: "POST",
      // ex: pkey = "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B"
      // ex: captcha_text = "z4Tlw1"
      body: JSON.stringify({ pkey: pkey, preimage: captcha_text }),
    })
      .then((response) => {
        if (!response.ok) {
          console.log("error121");

          throw new Error("Network response was not ok");
        }
        console.log("Here:", response);
        return response.text();
      })
      .then((data) => {
        const parsedData = JSON.parse(data);
        console.log(data);
        const decodedProof = Buffer.from(parsedData["proof"], "base64");
        console.log("DecodedProof:", decodedProof);
        return decodedProof;
      })
      .catch((error) => {
        console.error("Error during POST request:", error);
      });
  };
});
