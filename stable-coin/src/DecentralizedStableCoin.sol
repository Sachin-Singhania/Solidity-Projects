// This is considered an Exogenous, Decentralized, Anchored (pegged), Crypto Collateralized low volitility coin

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;
import {ERC20Burnable,ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/*
 * @title DecentralizedStableCoin
 * @author Sachin
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
* This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by the
DSCEngine smart contract.
 */

contract DecentralizedStableCoin is ERC20Burnable ,Ownable{
    error DSC__MUSTBEMORETHAN0();
    error DSC__BURNAMOUNTEXCEDBALANCE();
    error DSC__MINTTOZEROADDRESS();
    
    constructor() ERC20("DecentralizedStableCoin", "DSC") Ownable(msg.sender) {

    }
    function burn(uint256 _amount) public override onlyOwner{
        uint256 balance= balanceOf(msg.sender);
        if(_amount<=0) revert DSC__MUSTBEMORETHAN0();
        if(_amount>balance) revert DSC__BURNAMOUNTEXCEDBALANCE();
        super.burn(_amount);
    }
    
    function mint(address _to, uint256 _amount) external onlyOwner returns(bool){
        if(_to==address(0)) revert DSC__MINTTOZEROADDRESS();
        if(_amount<=0) revert DSC__MUSTBEMORETHAN0();
        _mint(_to, _amount);
        return true;
    }
}
