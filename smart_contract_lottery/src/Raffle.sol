// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract Raffle is VRFConsumerBaseV2Plus {
    // Errors
    error Raffle__NotEnoughEth();
    error Raffle__TooEarly();
    error Raffle__NotOpen();
    error Raffle__TransferFailed();
    error Raffle__UpkeepNotNeeded(uint256 balance,uint256 playersLength,uint256 RaffleState);

    //Enums
    enum RaffleState {
        Open,
        Calculating
    }
    //Var Declaration
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    uint256 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyhash;
    address payable[] private s_players;
    uint256 private s_lastTimestamp;
    address private s_RecentWinner;
    RaffleState private s_raffleState;

    //events
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);
    // Constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfaddress,
        bytes32 keyhash,
        uint256 subscriptionId,
        uint32 callbackgaslimit
    ) VRFConsumerBaseV2Plus(vrfaddress) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        i_keyhash = keyhash;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackgaslimit;
        s_raffleState = RaffleState.Open;
    }

    //Functions
    function Buyraffle() external payable {
        //  require(msg.value >= i_entranceFee, "Not enough Ether!");
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughEth();
        }
        if (s_raffleState != RaffleState.Open) revert Raffle__NotOpen();
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }

    function checkUpkeep(
        bytes memory
    ) public view returns (bool upkeedneeded, bytes memory) {

        bool timehaspassed = block.timestamp - s_lastTimestamp >= i_interval;
        bool israffleopen = s_raffleState == RaffleState.Open;
        bool hasbalance = address(this).balance > 0;
        bool hasplayers = s_players.length > 0;
        upkeedneeded =
            timehaspassed &&
            israffleopen &&
            hasbalance &&
            hasplayers;
        return (upkeedneeded, "");
    }
    function performUpKeep(bytes calldata) external {
        (bool upkeepneeded, ) = checkUpkeep("");
        if (!upkeepneeded) revert Raffle__UpkeepNotNeeded(address(this).balance,s_players.length,uint256(s_raffleState));
        s_raffleState = RaffleState.Calculating;
        //GET A RANDOM NUMBER
        uint256 requestId= s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyhash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            })
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] calldata randomWords
    ) internal override {
        uint256 winner = randomWords[0] % s_players.length;
        address payable RecentWinner = payable(s_players[winner]);
        s_RecentWinner = RecentWinner;
        s_raffleState = RaffleState.Open;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit WinnerPicked(s_RecentWinner);

        (bool success, ) = RecentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
    }
    /**Getter Funcitons  */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }
    function getPlayer(uint256 indexofplayer) external view returns (address) { return s_players[indexofplayer];}
    
     function getRecentWinner() external view returns (address) { return s_RecentWinner;}
    function getLastTimestamp () external view returns (uint256) { return s_lastTimestamp;}
    
}
