// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Bet is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");

    constructor(
        address _smartBetContract,
        // address _smartBetSwapContract,
        uint _initialSmartBetSupply
    )
        // uint _initialSwapSupply
        ERC20("Bet", "BET")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, _smartBetContract);
        _grantRole(MINTER_ROLE, _smartBetContract); // smartBet contract can mint new BETs if necessary
        _grantRole(BURN_ROLE, _smartBetContract); // smartBet contract can burn BETs
        // _grantRole(BURN_ROLE, _smartBetSwapContract); // smartBetSwap can burn Bets

        // start SmartBet Supply and SmartBet swap Supply
        _mint(_smartBetContract, _initialSmartBetSupply * 10 ** decimals());
        // _mint(_smartBetSwapContract, _initialSwapSupply * 10 ** decimals());
    }

    function mint(address _to, uint256 _amount) public onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }
}
