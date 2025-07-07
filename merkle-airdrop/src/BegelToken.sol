// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
contract BegelToken is ERC20,Ownable {
    constructor() ERC20("BegelToken", "BEG") Ownable(msg.sender)  {
    }
    function  mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
        }
}