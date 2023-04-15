const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

// const bigDecimal = require("js-big-decimal");
describe("Leveraged V3 Manager ", function () {
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
      await cookieClicker.startSession(sessionHash, 100);
    });
    describe("User Game Actions 121", function () {
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
    });
  });
  async function clickThisMany(num) {
    for (let i = 0; i < num; i++) {
      await cookieClicker.click();
    }
  }
});
