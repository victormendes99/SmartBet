const { ethers } = require("hardhat");
const { expect } = require("chai");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");

describe("SmartBet contract", function () {
  async function deployContractFixture() {
    const [smartBetFunctionsContract, anySigner] = await ethers.getSigners();

    const smartBet = await ethers.deployContract("SmartBet", [
      smartBetFunctionsContract.address,
    ]);

    await smartBet.waitForDeployment();

    return { smartBetFunctionsContract, smartBet, anySigner };
  }

  async function createInitialMatchesFixture() {
    const { smartBetFunctionsContract, smartBet, anySigner } =
      await loadFixture(deployContractFixture);
    await smartBet.createNewMatch(
      "Bahia",
      "Vitória",
      "Fonte Nova",
      1716865104,
      150,
      300,
      400
    );

    await smartBet.createNewMatch(
      "Bahia",
      "Flamengo",
      "Fonte Nova",
      1716865104,
      200,
      300,
      200
    );

    return { smartBet, anySigner };
  }

  describe("Deployment", function () {
    it("Should grant FUNCTIONS_ROLE to the specified address after deployment", async function () {
      const { smartBetFunctionsContract, smartBet } = await loadFixture(
        deployContractFixture
      );

      const FUNCTIONS_ROLE = ethers.keccak256(
        ethers.toUtf8Bytes("FUNCTIONS_ROLE")
      );
      const hasRole = await smartBet.hasRole(
        FUNCTIONS_ROLE,
        smartBetFunctionsContract.address
      );

      expect(hasRole).to.equal(true);
    });
  });

  // describe("Internal Functions", function(){
  //   it("Should return if value exists on list or not", async function(){
  //     const { smartBetFunctionsContract, smartBet, anySigner } = await loadFixture(deployContractFixture);

  //     expect(await smartBet._contains(1, [0,1,3])).to.equal([true, "1"]);
  //   })
  // })

  describe("Transactions", function () {
    it("Should create correctly a new Match", async function () {
      const { smartBetFunctionsContract, smartBet, anySigner } =
        await loadFixture(deployContractFixture);

      await expect(
        smartBet.createNewMatch(
          "Bahia",
          "Vitória",
          "Fonte Nova",
          1716865104,
          150,
          300,
          400
        )
      )
        .to.emit(smartBet, "SmartBet_NewMatchCreated")
        .withArgs(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          "Bahia",
          "Vitória",
          "Fonte Nova",
          1716865104,
          150,
          300,
          400,
          1
        );

      await expect(
        smartBet
          .connect(anySigner)
          .createNewMatch(
            "Bahia",
            "Vitória",
            "Fonte Nova",
            1716865104,
            150,
            300,
            400
          )
      ).to.be.reverted;

      await expect(
        smartBet.createNewMatch(
          "Bahia",
          "Vitória",
          "Fonte Nova",
          1716865104,
          150,
          300,
          400
        )
      ).to.be.revertedWith("The match already exist.");

      await expect(
        smartBet.createNewMatch(
          "Bahia",
          "Vitória",
          "Fonte Nova",
          1716865105,
          150,
          300,
          400
        )
      )
        .to.emit(smartBet, "SmartBet_NewMatchCreated")
        .withArgs(
          "0x5a31aadb48c235d9c1f3999a7613f8aa9e91c3eab4b15a5d8decfeaa719b146b",
          "Bahia",
          "Vitória",
          "Fonte Nova",
          1716865105,
          150,
          300,
          400,
          2
        );
    });

    it("Should return correctly upComingMatches", async function () {
      const { smartBetFunctionsContract, smartBet, anySigner } =
        await loadFixture(deployContractFixture);
      let upComingMatches;

      await expect(smartBet.getUpcomingMatches()).to.be.revertedWith(
        "No upcoming matches to bet on currently."
      );

      await smartBet.createNewMatch(
        "Bahia",
        "Vitória",
        "Fonte Nova",
        1716865104,
        150,
        300,
        400
      );

      upComingMatches = await smartBet.getUpcomingMatches();
      expect(upComingMatches.length).to.equal(1);

      await smartBet.createNewMatch(
        "Bahia",
        "Flamengo",
        "Fonte Nova",
        1716865104,
        200,
        300,
        200
      );

      upComingMatches = await smartBet.getUpcomingMatches();
      expect(upComingMatches.length).to.equal(2);

      expect(upComingMatches[0][1]).to.equal("Bahia");
      expect(upComingMatches[1][2]).to.equal("Flamengo");
    });

    it("Should correctly update a match status", async function () {
      const { smartBet, anySigner } = await loadFixture(
        createInitialMatchesFixture
      );

      upComingMatches = await smartBet.getUpcomingMatches();
      expect(upComingMatches.length).to.equal(2);

      await expect(
        smartBet
          .connect(anySigner)
          .updateMatchStatus(
            "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
            0
          )
      ).to.be.reverted;

      await expect(
        smartBet.updateMatchStatus(
          "0x333d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344a555",
          0
        )
      ).to.be.revertedWith("The match does not exist.");

      await expect(
        smartBet.updateMatchStatus(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          0
        )
      ).to.be.revertedWith("Match cannot be updated to Upcoming status.");

      await expect(
        smartBet.updateMatchStatus(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          2
        )
      ).to.be.revertedWith(
        "Match must be in the Live list to be updated to Finished."
      );

      await expect(
        smartBet.updateMatchStatus(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          1
        )
      )
        .to.emit(smartBet, "SmartBet_MatchStatusUpdated")
        .withArgs("Bahia", "Vitória", "Fonte Nova", 1716865104, 1);

      upComingMatches = await smartBet.getUpcomingMatches();
      expect(upComingMatches.length).to.equal(1);

      await expect(
        smartBet.updateMatchStatus(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          0
        )
      ).to.be.revertedWith("Match cannot be updated to Upcoming status.");

      await expect(
        smartBet.updateMatchStatus(
          "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29",
          2
        )
      )
        .to.emit(smartBet, "SmartBet_MatchStatusUpdated")
        .withArgs("Bahia", "Vitória", "Fonte Nova", 1716865104, 2);

      await expect(
        smartBet.updateMatchStatus(
          "0x5eda3b9e970ea779dbb98de40e2caf36f96244db7d0b4c327aa5926033fb36fb",
          1
        )
      )
        .to.emit(smartBet, "SmartBet_MatchStatusUpdated")
        .withArgs("Bahia", "Flamengo", "Fonte Nova", 1716865104, 1);

      await expect(smartBet.getUpcomingMatches()).to.revertedWith(
        "No upcoming matches to bet on currently."
      );
    });

    it("Should correctly return a existing match", async function () {
      const { smartBet } = await loadFixture(createInitialMatchesFixture);

      await expect(
        smartBet.getMatch(
          "0x333d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29"
        )
      ).to.be.revertedWith("The match does not exist.");

      match = await smartBet.getMatch(
        "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29"
      );
      await expect(match.hash).to.equal(
        "0xed0d24d337c50a9d85550241190ceee7fda72fad5daa82e50ac0df5e8344ad29"
      );

      match = await smartBet.getMatch(
        "0x5eda3b9e970ea779dbb98de40e2caf36f96244db7d0b4c327aa5926033fb36fb"
      );
      await expect(match.hash).to.equal(
        "0x5eda3b9e970ea779dbb98de40e2caf36f96244db7d0b4c327aa5926033fb36fb"
      );
    });
  });
});
