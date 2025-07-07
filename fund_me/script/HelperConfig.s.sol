 // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script, console} from "forge-std/Script.sol";

contract HelperConfig is Script{
    struct NetworkConfig{
        address priceFeed;
    }
    NetworkConfig public activenetworkconfig;
    constructor(){
        if(block.chainid==11155111){
            activenetworkconfig=getSepoliaEthConfig();
        }else{
            activenetworkconfig= getAnvilEthConfig();
        }
    }
    function getSepoliaEthConfig() public pure returns(NetworkConfig memory){
        NetworkConfig memory sepoliaconfig= NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaconfig;
    }

    function getAnvilEthConfig() public pure returns(NetworkConfig memory){

    }
}