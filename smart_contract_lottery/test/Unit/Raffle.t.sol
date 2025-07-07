// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {Script, console} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {RaffleScript} from "script/DeployRaffle.s.sol";
import {HelperConfig,CodeConstant} from "script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract TestContract is Test,CodeConstant {
    Raffle public raffle;
    HelperConfig public helperconfig;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_BALANCE = 10 ether;

    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    uint256 entranceFee;
    uint256 interval;
    address vrfaddress;
    bytes32 keyhash;
    uint256 subscriptionId;
    uint32 callbackgaslimit;

    function setUp() external {
        // Deploy the Raffle contract
        RaffleScript raffleScript = new RaffleScript();
        (raffle, helperconfig) = raffleScript.DeployRaffle();
        HelperConfig.NetworkConfig memory config = helperconfig
            .getNetworkConfigs();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfaddress = config.vrfaddress;
        keyhash = config.keyhash;
        subscriptionId = config.subscriptionId;
        callbackgaslimit = config.callbackgaslimit;
        vm.deal(PLAYER, STARTING_BALANCE);
    }
    function testRaffleState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.Open);
    }

    function testRaffleRevertsWhenYouDontpay() public {
        //arange
        vm.prank(PLAYER);
        //act
        vm.expectRevert(Raffle.Raffle__NotEnoughEth.selector);
        raffle.Buyraffle();
    }

    function testRaffleRecordsWhenPlayerEnters() public {
        //arange
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        address playerrecorded = raffle.getPlayer(0);
        assert(playerrecorded == PLAYER);
    }
    function testEnteringRaffleEvent() public {
        //arange
        vm.prank(PLAYER);
        //act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
    }
    function testPlayerCantEnterWhileCalculating() public {
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        raffle.performUpKeep("");
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
    }
    function testCheckupkeepReturnsFalseifzeroBalance() public {
        //arange
        vm.warp(block.timestamp + interval + 1);
        //act
        (bool upkeepneeded, ) = raffle.checkUpkeep("");
        //asset
        assert(!upkeepneeded);
    }
    function testCheckupkeepReturnsFalseifrafflenotopen() public {
        //arange
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        raffle.performUpKeep("");
        //act
        (bool upkeepneeded, ) = raffle.checkUpkeep("");
        //asset
        assert(!upkeepneeded);
    }
    function testCheckupkeepreturnsfalseiftimenotpassed() public {
        //arange
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        //act
        (bool upkeepneeded, ) = raffle.checkUpkeep("");
        //asset
        assert(!upkeepneeded);
    }
    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
          //arange
    vm.prank(PLAYER);
    raffle.Buyraffle{value: entranceFee}();
    vm.warp(block.timestamp + interval + 1);
    //act
    (bool upkeepNeeded, ) = raffle.checkUpkeep("");
    //asset
    assert(upkeepNeeded);
    }

    //PERFORM UP KEEP

    function testPerformCheckupkeepcanonlyrunifcheckupkeepistrue() public {
        //arange
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        //act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(upkeepNeeded);
        raffle.performUpKeep("");
        assert(
            uint256(raffle.getRaffleState()) ==
                uint256(Raffle.RaffleState.Calculating)
        );
    }
    function testPerformCheckupkeeprevertsifcheckupkeepisfalse() public {
        //arange
        uint256 initialBalance = 0;
        uint256 players = 0;
        Raffle.RaffleState rstate = raffle.getRaffleState();
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        initialBalance = initialBalance + entranceFee;
        players = 1;
        //act/asset
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                initialBalance,
                players,
                rstate
            )
        );
        raffle.performUpKeep("");
    }
    modifier enterRaffle(){
        vm.prank(PLAYER);
        raffle.Buyraffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        _; 
    }
    function testPerformUpkeepUpdatesRaffleStateandEmitsRequestId() public enterRaffle{
        //arange
        
        //act
        vm.recordLogs();
        raffle.performUpKeep("");
        //asset 
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        assert(uint256(requestId) > 0);
        assert(uint256(raffle.getRaffleState()) == 1);
    }
    //~~~~~~~~~~~~~~~~~~~~~~~~~~FULLFILL RANDOM WORDS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    modifier skipfork(){
        if(block.chainid!=LOCAL_CHAIN_ID) return;
         _;
    }
    function testfullfillramdomwordsshouldcallafterperformupkeeptest(uint256 randomRequestId) public  enterRaffle skipfork{
         //arange
         vm.expectRevert( VRFCoordinatorV2_5Mock.InvalidRequest.selector);
         VRFCoordinatorV2_5Mock(vrfaddress).fulfillRandomWords(randomRequestId,address(raffle));
    }
    function testFullfillrandomewordsPicksawinnerresetsandSendsMoney() public  enterRaffle skipfork{
        //4 log entered raffle
        //performup keep called
        //got the requestId as well as ramdomword andcalls   fullfillrandomwords
        // fulfillrandomwords calls pickwinner and then resets the raffle state / winner and sends money
         //
         uint256 startingIndex=1;
         uint256 endingIndex= 3;
         address expectedWinner = address(1);
         for (uint256 i=startingIndex; i < startingIndex+ endingIndex; i++) {
             address newPlayer = address(uint160(i));
             hoax(newPlayer,1 ether);
             raffle.Buyraffle{value: entranceFee}();
         }
         uint256 expectedWinnerBal= expectedWinner.balance;
         uint256 lasttimestamp= raffle.getLastTimestamp();
        //act
        vm.recordLogs();
        raffle.performUpKeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
         VRFCoordinatorV2_5Mock(vrfaddress).fulfillRandomWords(uint256(requestId),address(raffle));
        //asset     
        address winner= raffle.getRecentWinner();

        Raffle.RaffleState rstate= raffle.getRaffleState();
        uint256 winnerBal=  winner.balance;
        uint256 prize= entranceFee *(endingIndex+1);
         uint256 finaltimestamp= raffle.getLastTimestamp();
            console.log(winnerBal);
            console.log(expectedWinnerBal+prize);
         assert(expectedWinner==winner);
         assert(uint256(rstate)==0);
         assert(winnerBal==expectedWinnerBal+prize);
         assert(finaltimestamp>lasttimestamp);
    }

}
