// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {CreateSubscription,FundSubscription,AddConsumers} from "./Interactions.s.sol";

contract RaffleScript is Script {
    function run() public {
        DeployRaffle();
    }
    function DeployRaffle() public returns (Raffle, HelperConfig) {
        HelperConfig helperconfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperconfig
            .getNetworkConfigs();

        if (config.subscriptionId == 0) {
            //create
            CreateSubscription helper = new CreateSubscription();
            (config.subscriptionId, config.vrfaddress) = helper
                .createSubscription(config.vrfaddress,config.account);
            //fundit
            FundSubscription fund = new FundSubscription();
            fund.fundSubscription(config.vrfaddress,config.subscriptionId,config.link,config.account);

        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfaddress,
            config.keyhash,
            config.subscriptionId,
            config.callbackgaslimit
        );
        vm.stopBroadcast();
        //consumer
        AddConsumers add = new AddConsumers();
        add.addConsumer(config.vrfaddress,address(raffle),config.subscriptionId,config.account);
        return (raffle, helperconfig);
    }
}
