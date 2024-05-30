const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Bet contract", function () {
  it("Deployment should setting the total supply of tokens to the smartBet contract and smartBetSwap contract", async function () {
    const [smartBetAddr, smartBetSwapAddr] = await ethers.getSigners();
    const InitialSmartBetBalance = 400000;
    const InitialSmartBetSwapBalance = 100000;

    const Bet = await ethers.deployContract("Bet", [
      smartBetAddr.address,
      // smartBetSwapAddr.address,
      InitialSmartBetBalance,
      // InitialSmartBetSwapBalance,
    ]);

    const ExpectedSmartBetBalance = 40000000000;
    const ExpectedSmartBetSwapBalance = 10000000000;

    const smartBetBalance = await Bet.balanceOf(smartBetAddr.address);
    // const smartBetSwapBalance = await Bet.balanceOf(smartBetSwapAddr.address);
    
    expect(smartBetBalance).to.equal(ExpectedSmartBetBalance);
    // expect(smartBetSwapBalance).to.equal(ExpectedSmartBetSwapBalance);
  });
});