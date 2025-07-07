// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol" ;
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol" ;
contract Box is Ownable{
    uint256 private s_value;
    event NewValue(uint256 newValue );
    function store(uint256 _value) public onlyOwner{
        s_value = _value;
        emit NewValue(_value);
    }
    function getNumber() public view returns (uint256) {
        return s_value;
    }
}
