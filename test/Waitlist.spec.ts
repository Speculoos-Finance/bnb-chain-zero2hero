import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

const REGISTRATION_FEE = ethers.utils.parseEther("0.1");
const REFUND_TIME_SPAN = 60 * 60 * 24 * 3;

describe("Waitlist", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployWaitlistFixture() {
    const registrationFee = REGISTRATION_FEE;
    const refundTimeSpan = REFUND_TIME_SPAN;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Waitlist = await ethers.getContractFactory("Waitlist");
    const waitlist = await upgrades.deployProxy(Waitlist, [
      registrationFee,
      refundTimeSpan,
      [],
      [],
      [],
    ]);

    return { waitlist, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right registration fee", async function () {
      const { waitlist } = await loadFixture(deployWaitlistFixture);

      expect(await waitlist.registrationFee()).to.equal(
        REGISTRATION_FEE
      );
    });

    it("Should set the right refund time span", async function () {
        const { waitlist } = await loadFixture(deployWaitlistFixture);
  
        expect(await waitlist.refundTimeSpan()).to.equal(
          REFUND_TIME_SPAN
        );
      });
  
    it("Should set the right owner", async function () {
      const { waitlist, owner } = await loadFixture(deployWaitlistFixture);

      expect(await waitlist.owner()).to.equal(owner.address);
    });

    it("Should set the right waitlist", async function () {
      const { waitlist } = await loadFixture(deployWaitlistFixture);

      expect(await waitlist.waitlistLength()).to.equal(0);
    });

    it("Should fail if discount codes incorrectly added", async function () {
      // We don't use the fixture here because we want a different deployment
      const Waitlist = await ethers.getContractFactory("Waitlist");
      await expect(
        upgrades.deployProxy(Waitlist, [
            REGISTRATION_FEE,
            REFUND_TIME_SPAN,
            [],
            [5000],
            [],
          ])
      ).to.be.revertedWith("Mismatch in array lengths");
    });
  });
});
