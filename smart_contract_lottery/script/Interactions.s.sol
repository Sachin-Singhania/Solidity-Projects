// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig,CodeConstant} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract CreateSubscription is Script{
  
    function createSubscriptionconfig() public returns(uint256,address) {
        HelperConfig config = new HelperConfig();
       address vrfcordinator= config.getNetworkConfigs().vrfaddress;
       address account=config.getNetworkConfigs().account;
        (uint256 subId,)=createSubscription(vrfcordinator,account);
        
        return (subId,vrfcordinator);

    }
    function createSubscription(address vrfcordinator,address account) public returns(uint256 , address){
         console.log("Creating subscription on chainId: ", block.chainid);
        vm.startBroadcast(account);
         uint256 subId= VRFCoordinatorV2_5Mock(vrfcordinator).createSubscription();
         vm.stopBroadcast();
          console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in HelperConfig.s.sol");
         console.log("Your subscription id is" ,subId);
         return (subId,vrfcordinator);
    }
      function run() external {
        createSubscriptionconfig();
    }
}

contract FundSubscription is Script, CodeConstant{
    uint96 public constant FUND_AMOUNT=3 ether;
    function fundSubscriptionConig() public{
        HelperConfig helperConfig= new HelperConfig();
        address vrfCordinator= helperConfig.getNetworkConfigs().vrfaddress;
        uint256 subId=helperConfig.getNetworkConfigs().subscriptionId;
        address linktoken=  helperConfig.getNetworkConfigs().link;
       address account=helperConfig.getNetworkConfigs().account;

        fundSubscription(vrfCordinator,subId,linktoken,account);
    }
    function fundSubscription(address vrfCordinator,uint256 subId,address linktoken,address account) public{
        console.log("Funding subscription: ", subId);
        console.log("Using vrfCoordinator: ", vrfCordinator);
        console.log("On ChainID: ", block.chainid);
        if(block.chainid==LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCordinator).fundSubscription(subId, FUND_AMOUNT*100);
            vm.stopBroadcast();
        }else{
            console.log(LinkToken(linktoken).balanceOf(msg.sender));
            console.log(msg.sender);
            console.log(LinkToken(linktoken).balanceOf(address(this)));
            console.log(address(this));
            vm.startBroadcast(account);
            LinkToken(linktoken).transferAndCall(vrfCordinator, FUND_AMOUNT, abi.encode(subId));
             vm.stopBroadcast();
        }

    }
    function run()public {fundSubscriptionConig();}
}
contract AddConsumers is Script{
    function addConsumerConfig(address mostRecentDeployed) public{
        HelperConfig helperConfig= new HelperConfig();
        address vrfCordinator= helperConfig.getNetworkConfigs().vrfaddress;
        uint256 subId= helperConfig.getNetworkConfigs().subscriptionId;      
         address account=helperConfig.getNetworkConfigs().account;

        addConsumer(vrfCordinator,mostRecentDeployed,subId,account);
        }
        function addConsumer(address vrfCordinator,address contractoaddtovrf,uint256 subId,address account) public{
             console.log("Adding consumer contract: ", contractoaddtovrf);
        console.log("Using vrfCoordinator: ", vrfCordinator);
        console.log("On ChainID: ", block.chainid);
            vm.startBroadcast(account);
            VRFCoordinatorV2_5Mock(vrfCordinator).addConsumer(subId,contractoaddtovrf);
            vm.stopBroadcast();
        }
    function run()public {
        address mostrecentdeployed= DevOpsTools.get_most_recent_deployment("Raffle",block.chainid);
        addConsumerConfig(mostrecentdeployed);
    }

}