// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract ManualToken {
    mapping(address=>uint256) public s_balances;
    function name() public pure returns (string memory) {
        return "Manual Token";
    }
    function totalSupply() public pure returns (uint256) {
        return 1000000;
        }
    function decimals() public pure returns (uint8) {
        return 18;
        }
    function balanceOf( address _owner ) public view returns (uint256) {
        return s_balances[_owner];
        }
    function transfer( address _to, uint256 _value ) public {
        uint256 prevbal= balanceOf(msg.sender)+balanceOf(_to);
        s_balances[msg.sender]-= _value;
        s_balances[_to]+= _value;
        require(prevbal==balanceOf(msg.sender)+balanceOf(_to),"Error");
    }

}
