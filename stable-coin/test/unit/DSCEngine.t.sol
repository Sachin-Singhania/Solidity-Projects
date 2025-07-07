// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {DSCEngine} from "../../src/DSCengine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DecentralizedStableCoinScript} from "../../script/DeployDSC.s.sol";
import { ERC20Mock } from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/mocks/ERC20Mock.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import { MockV3Aggregator } from "../mocks/MockV3Aggregator.m.sol";
contract DSCEngineTest is Test {
    DSCEngine public dSC_Engine;
    DecentralizedStableCoinScript public deployDSC;
    HelperConfig public helperConfig;
    DecentralizedStableCoin public dSC;
    address ethUSDPriceFeed;
    address btcUSDPriceFeed;
    address weth;
    address wbtc;
    address public USER= makeAddr("user");
    uint256 public constant AMOUNT_COLLATORAL= 10 ether;
 uint256 amountCollateral = 10 ether;
    uint256 amountToMint = 100 ether;
    uint256 public constant STARTING_COLLATORAL= 10 ether;
    function setUp() public {
        deployDSC = new DecentralizedStableCoinScript();
        (dSC,dSC_Engine,helperConfig) = deployDSC.run();
        ( ethUSDPriceFeed,btcUSDPriceFeed,weth,wbtc,) = helperConfig.activenetworkConfigs();
        ERC20Mock(weth).mint(USER,STARTING_COLLATORAL);
    }
   
    //////////////////////////
    ///////Constrcutor Test //
    //////////////////////////
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;
     function testRevertifLengthDoesntMatch() public{
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUSDPriceFeed);
        priceFeedAddresses.push(btcUSDPriceFeed);
        vm.expectRevert( DSCEngine.DSC__TOKENADDRESSLENGTHMUSTBEEQUALTOPRICEFEEDADD.selector);
        new DSCEngine( tokenAddresses, priceFeedAddresses,address(dSC_Engine));
     }
    //////////////////////////
    ///////PriceTest /////////
    //////////////////////////
    function testGetUSDValue()  public view {
        uint256 amount= 1e18;
        uint256 expectedUSD= 2000e18;
        uint256 actualUSD= dSC_Engine.getUSDvalue(weth,amount);
        assertEq(actualUSD,expectedUSD);
    }
    function testgetTokenAmountFromUSD() public view {
        uint256 usdamount= 100 ether;
        uint256 expectedTokenAmount= 0.05 ether;
        uint256 actualTokenAmount= dSC_Engine.getTokenAmountFromUSD(weth,usdamount);
        assertEq(actualTokenAmount,expectedTokenAmount);
    }
    ///////////////////////////
    ////DepositCollateralTest//
    ///////////////////////////
     modifier depositCollatoral(){ 
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dSC_Engine), AMOUNT_COLLATORAL);
        dSC_Engine.depositCollateral(weth, AMOUNT_COLLATORAL);
         vm.stopPrank();
         _;
    }
    //~~~~~~~~~~~~
    //FUNCTIONS
    //~~~~~~~~~~~~
    function testRevertsifCollateralZero() public{
        vm.startPrank(USER);
        // vm.deal(USER,1 ether); without this we also get revert of exceed balance as balance is zero but user is trying to send something
        ERC20Mock(weth).approve(address(dSC_Engine), AMOUNT_COLLATORAL);
        vm.expectRevert(DSCEngine.DSC__NEEDSMORETHANZERO.selector);
        dSC_Engine.depositCollateral(weth,0);    
        vm.stopPrank();
    }
    function testRevertifInvalidToken() public {
        vm.startPrank(USER);
        ERC20Mock ranToken= new ERC20Mock( "RanToken", "RanToken", USER,AMOUNT_COLLATORAL );
        vm.expectRevert(DSCEngine.DSC__TOKENNOTALLOWED.selector);
        dSC_Engine.depositCollateral(address(ranToken),AMOUNT_COLLATORAL);
        vm.stopPrank();
    }
    function testCanDepoCollatoralandGetAccInfo() public depositCollatoral{
       (uint256 totalDSCMinted, uint256 collateralValinUSD) =  dSC_Engine.getAccountInfo(USER); 
       uint256 expectedMInted= 0;
       uint256 expectedAmount=  dSC_Engine.getTokenAmountFromUSD(weth, collateralValinUSD);
       assertEq(totalDSCMinted,expectedMInted);
       assertEq(AMOUNT_COLLATORAL,expectedAmount);
    }
    ///////////////////////////
    ////Redeem DepositedCollateralTest//
    ///////////////////////////
    //  function redeemCollateral(
    //     address tokenCollateralAddress,
    //     uint256 amountCollateral
    // )
    function testCantWithdrawCollateralZero() public depositCollatoral{
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSC__NEEDSMORETHANZERO.selector);
        dSC_Engine.redeemCollateral(weth, 0);
    }
    function testRevertifInvalidTokenWithdraw() public{
        vm.startPrank(USER);
        ERC20Mock ranToken= new ERC20Mock( "RanToken", "Ran Token", USER,AMOUNT_COLLATORAL );
        vm.expectRevert(DSCEngine.DSC__TOKENNOTALLOWED.selector);
        dSC_Engine.redeemCollateral(address(ranToken),AMOUNT_COLLATORAL);
    }
    function testCanWithdrawCollateral() public depositCollatoral{
        uint256 expectedAmount=  AMOUNT_COLLATORAL;
        vm.prank(USER);
        dSC_Engine.redeemCollateral(weth, AMOUNT_COLLATORAL);
        assertEq(ERC20Mock(weth).balanceOf(USER),expectedAmount);
    }
    function testEmitRedeemedCollateral() public depositCollatoral{
        vm.startPrank(USER);
         vm.expectEmit(true, true, true, false); 
        emit DSCEngine.DSC__CollateralRedeemed(USER, USER, weth, AMOUNT_COLLATORAL);
        dSC_Engine.redeemCollateral(weth, AMOUNT_COLLATORAL);
        vm.stopPrank();
    }
    function testCantWithdrawCollateralWithoutDeposit() public {
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSC__AMOUNTTOSWAPISZERO.selector);
        dSC_Engine.redeemCollateral(weth, AMOUNT_COLLATORAL);
    }
    function testCantWithdrawCollateralWithMoreAmount() public depositCollatoral{
        vm.prank(USER);
        vm.expectRevert(DSCEngine.DSC__AMOUNTTOSWAPISZERO.selector);
        dSC_Engine.redeemCollateral(weth, AMOUNT_COLLATORAL*2);
    }
      ///////////////////////////////////////
    // depositCollateralAndMintDsc Tests //
    ///////////////////////////////////////
    function testRevertsIfMintedDscBreaksHealthFactor() public{
         (, int256 price,,,) = MockV3Aggregator(ethUSDPriceFeed).latestRoundData();
          amountToMint = (amountCollateral * (uint256(price) * dSC_Engine.getAdditionalFeedPrecision())) / dSC_Engine.getPrecision();
           vm.startPrank(USER);
            ERC20Mock(weth).approve(address(dSC_Engine), amountCollateral);
            uint256 expectedHealthFactor =dSC_Engine.calculateHealthFactor(amountToMint, dSC_Engine.getUSDvalue(weth, amountCollateral));
             vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSC__HEALTHFACTORBROKEN.selector, expectedHealthFactor));
             dSC_Engine.depositCollateralandMintDsc(weth, amountCollateral,amountToMint  );
             vm.stopPrank();
    }
    modifier DepositAndMint(){
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dSC_Engine), AMOUNT_COLLATORAL);
        dSC_Engine.depositCollateralandMintDsc(weth, AMOUNT_COLLATORAL ,amountToMint  );
        vm.stopPrank();
        _;
    }
    function testCanMintWithDepositCollateral() public DepositAndMint{
        assertEq(dSC.balanceOf(USER), amountToMint);
        
    }
  
}
