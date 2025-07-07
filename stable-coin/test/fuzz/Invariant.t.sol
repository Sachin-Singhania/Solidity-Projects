 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import { ERC20Mock } from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DSCEngine} from "../../src/DSCengine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DecentralizedStableCoinScript} from "../../script/DeployDSC.s.sol";

import {Handler} from "./Handler.t.sol";
contract InvariantTest is  StdInvariant, Test {
DecentralizedStableCoinScript public deployer;
DSCEngine public dsce;
HelperConfig public config;
DecentralizedStableCoin public dscToken;
    address ethUSDPriceFeed;
    address btcUSDPriceFeed;
    address weth;
    address wbtc;
Handler handler;
 function setUp() external{
    deployer = new DecentralizedStableCoinScript();
    (dscToken,dsce,config)= deployer.run();
    ( ethUSDPriceFeed,btcUSDPriceFeed,weth,wbtc,) = config.activenetworkConfigs();
    handler = new Handler(dsce,dscToken);
    
    targetContract(address(handler));
 }
 function protocolMusthaveMoreValuethantotalSupply() public view{
    uint256 totalSupply = dscToken.totalSupply();
    uint256 totalWethDeposited= IERC20(weth).balanceOf(address(dsce));
    uint256 totalWbtcDeposited= IERC20(wbtc).balanceOf(address(dsce));
    uint256 wethVal= dsce.getUSDvalue(weth,totalWethDeposited);
    uint256 wbtcVal= dsce.getUSDvalue(wbtc,totalWbtcDeposited);
      console.log("WBTC:",wbtc);
      console.log("WETH",weth);
    assert(wethVal + wbtcVal >= totalSupply);
 }
}
   