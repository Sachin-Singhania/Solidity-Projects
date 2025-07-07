// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FundMe} from "../src/FundMe.sol";
import {Test,console} from "forge-std/Test.sol";
import {DeployFundMe} from "script/FundMeScript.s.sol";
contract FundmeTest is Test {
    FundMe fundMe;
    function setUp() external{
        // fundMe=new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployfund= new DeployFundMe();
        fundMe=deployfund.run();
    }
    // function testMinUSDisfive() public{
    //     console.log(fundMe.MINIMUM_USD());
    //     assertEq(fundMe.MINIMUM_USD(),5e18);
    // }
    function testisVersionfour() public{
        uint256 version= fundMe.getVersion();
        console.log(version);
        assertEq(version,4);
    }
    function testOwnerisMsgsender() public{
         assertEq(fundMe.i_owner(), msg.sender);
    }
}
