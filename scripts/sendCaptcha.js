const { deployContract } = require("ethereum-waffle");
const { ethers, network } = require("hardhat");
const fs = require("fs");
const fetch = require("node-fetch"); // const bigDecimal = require("js-big-decimal");

async function main() {
  const cookieClicker = await ethers.getContract("CookieClicker");
  accounts = await ethers.getSigners(); // could also do with getNamedAccounts
  deployer = accounts[0];

  await cookieClicker.giveUserCaptcha(deployer.address);

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
  await cookieClicker.submitCaptcha(
    destinationID,
    "0x2C19584d70F17256014B8215e3C299E7Ae62Be78",
    0,
    proof,
    deployer.address
  );
}
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
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
