import { ethers, upgrades } from "hardhat";

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const refundTimeSpan = 60 * 60 * 24 * 7;

  const registrationFee = ethers.utils.parseEther("0.1");

  const Waitlist = await ethers.getContractFactory("Waitlist");
  const instance = await await upgrades.deployProxy(Waitlist, [registrationFee, refundTimeSpan]);

  await instance.deployed();

  console.log(
    `Waitlist  deployed to ${instance.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
