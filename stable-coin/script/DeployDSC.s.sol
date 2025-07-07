// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DecentralizedStableCoin.sol";
import {DSCEngine} from "../src/DSCengine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DecentralizedStableCoinScript is Script {
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
    DecentralizedStableCoin public decentralizedStableCoin;
    DSCEngine public DSC_Engine;
    function run() external returns (DecentralizedStableCoin, DSCEngine,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        (
            address wethUsdPriceFeed,
            address wbtcUsdPriceFeed,
            address weth,
            address wbtc,
            uint256 deployerKey
        ) = helperConfig.activenetworkConfigs();
        tokenAddresses = [weth, wbtc];
        priceFeedAddresses = [wethUsdPriceFeed, wbtcUsdPriceFeed];
        vm.startBroadcast();
        decentralizedStableCoin = new DecentralizedStableCoin();
        DSC_Engine = new DSCEngine(tokenAddresses, priceFeedAddresses,address(decentralizedStableCoin));
        decentralizedStableCoin.transferOwnership(address(DSC_Engine));
        vm.stopBroadcast();
        return (decentralizedStableCoin, DSC_Engine ,helperConfig);
    }
}
