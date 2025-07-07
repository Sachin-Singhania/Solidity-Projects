// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
abstract contract CodeConstant {
            uint96 public MOCK_BASE_FEE = 0.50 ether;
    uint96 public MOCK_GAS_PRICE_LINK = 1e9;
    // LINK / ETH price
    int256 public MOCK_WEI_PER_UINT_LINK = 4e15;
    uint256 public constant ETH_SEPOLIA_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
}
contract HelperConfig is CodeConstant, Script {
        error HelperConfig__CHAIN_ID_INVALID();
    struct NetworkConfig {
        uint256 entranceFee;
        uint256 interval;
        address vrfaddress;
        bytes32 keyhash;
        uint256 subscriptionId;
        uint32 callbackgaslimit;
        address link;
        address account;
    }
    NetworkConfig public localNetwork;

    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_ID] = getSepoliaEthConfig();
    }

    function getConigbyChainId(
        uint256 chainId
    ) public returns (NetworkConfig memory) {
        if(networkConfigs[chainId].vrfaddress !=address(0)){
        return networkConfigs[chainId];
        }else if(chainId==LOCAL_CHAIN_ID){
                return getorCreateAnvilconfig();
        }else{
                revert HelperConfig__CHAIN_ID_INVALID();
        }
    }
    function getNetworkConfigs() public  returns (NetworkConfig memory) {
     return getConigbyChainId(block.chainid);
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfaddress: 0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B,
                keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                callbackgaslimit: 500000,link:0x779877A7B0D9E8603169DdbD7836e478b4624789, 
                account:0x1853Bdd6BDdC2480Df881BD9723412F661d59740
            });
    }
    function getorCreateAnvilconfig() public returns (NetworkConfig memory) {
        if(localNetwork.vrfaddress!=address(0)) return localNetwork;

        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCordinatorMock= new VRFCoordinatorV2_5Mock(MOCK_BASE_FEE, MOCK_GAS_PRICE_LINK, MOCK_WEI_PER_UINT_LINK);
        LinkToken link = new LinkToken();
        // uint256 subscriptionId = vrfCordinatorMock.createSubscription();
        vm.stopBroadcast();
        localNetwork=  NetworkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                vrfaddress: address(vrfCordinatorMock),
                keyhash: 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae,
                subscriptionId: 0,
                callbackgaslimit: 500000,
                link: address(link),
                 account:0x1853Bdd6BDdC2480Df881BD9723412F661d59740
            });
            
        return localNetwork;
    }
}
