const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const SmartBetModule = buildModule("SmartBetModule", (m) => {
  const smartBet = m.contract("SmartBet", ['0x43b934e2a82AD40DD6f1De073A4723614b9741fB']);

  const bet = m.contract("Bet", [smartBet, 400000]);

  return { smartBet, bet };
});

module.exports = SmartBetModule;