// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import { ERC20Mock } from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {DSCEngine} from "../../src/DSCengine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DecentralizedStableCoinScript} from "../../script/DeployDSC.s.sol";
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.m.sol";
contract Handler is  Test {
     DSCEngine public dscEngine;
     DecentralizedStableCoin public dsc;
     ERC20Mock public weth;
     ERC20Mock public wbtc;
     uint256 public constant MAX_SUPPLY = type(uint96).max;
     address[] public addressesdepo;
     MockV3Aggregator public ethUsdPriceFeed;
    MockV3Aggregator public btcUsdPriceFeed;
    constructor(DSCEngine _dscEngine, DecentralizedStableCoin _dsc) public {
         dscEngine = _dscEngine;
         dsc = _dsc;
         address [] memory _addresses = dscEngine.getCollateralTokens();
         weth = ERC20Mock(_addresses[0]);
         wbtc = ERC20Mock(_addresses[1]);

          ethUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(weth)));
        btcUsdPriceFeed = MockV3Aggregator(dscEngine.getCollateralTokenPriceFeed(address(wbtc)));
    }
    
    function mintDsc( uint256 amtDsctoMinted,uint256 addressSeed)public{
      if(addressesdepo.length==0) return;
      address sender = addressesdepo[addressSeed%addressesdepo.length];
      (uint256 totalDscMinted, uint256 totalCollateralValueinUSD)= dscEngine.getAccountInfo(sender);
      int256 maxtomint=  int256(totalCollateralValueinUSD)/2 - int256(totalDscMinted);
      if(maxtomint<=0) return;
       amtDsctoMinted = bound(amtDsctoMinted,0,uint256(maxtomint));
      if(amtDsctoMinted==0) return;
      vm.prank(sender);
      dscEngine.mintDSC(amtDsctoMinted);
    }
    function depositCollateral( uint256 collateralSeed,uint256 amountCollateral ) public {
        ERC20Mock collateralToken= _getCollateralFromSeed(collateralSeed);
        console.log(address(collateralToken));
        amountCollateral= bound( amountCollateral, 1, MAX_SUPPLY);
        vm.startPrank(msg.sender);
        collateralToken.mint( msg.sender, amountCollateral);
        collateralToken.approve(address(dscEngine), amountCollateral);
        dscEngine.depositCollateral(address(collateralToken), amountCollateral);
        vm.stopPrank();
      addressesdepo.push(msg.sender);

    }
//     brea
//     function updateCollateralPrice(uint96 newPrice) public {
//      int256 newPriceInt= int265(uint256(newPrice));
//      ethUsdPriceFeed.updatePrice(newPriceInt);

//     }
   
   
   
    function redeemCollateral( uint256 collateralSeed,
        uint256 amountCollateral) public {
        ERC20Mock collateralToken= _getCollateralFromSeed(collateralSeed);
        uint256 maxtoken= dscEngine.getCollateralBalanceUser(msg.sender, address(collateralToken));
        amountCollateral= bound( amountCollateral, 0, maxtoken);
        if(amountCollateral==0) {
            return;
        }
        vm.prank(msg.sender);
        dscEngine.redeemCollateral(address(collateralToken), amountCollateral);

    }
    function _getCollateralFromSeed(uint256 collateralSeed) internal view returns (ERC20Mock) {
    if( collateralSeed %2 == 0) return weth;
    else return wbtc;
    }
}