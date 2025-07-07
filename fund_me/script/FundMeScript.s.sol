// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        HelperConfig helper= new HelperConfig();
        address deployer =helper.activenetworkconfig(); 
        vm.startBroadcast();
         FundMe fundMe = new FundMe(deployer);
         vm.stopBroadcast();
         return fundMe;
    }
}
