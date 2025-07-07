// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {BasicNFT} from "src/BasicNft.sol";
import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
contract MintBasicNft is Script {
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";

    function run() external {
        address mostRecentdeployed= DevOpsTools.get_most_recent_deployment("BasicNFT", block.chainid);
        mintNftonContract(mostRecentdeployed);
    }
     function mintNftonContract(address contractAddress) internal {
        vm.startBroadcast();
        BasicNFT(contractAddress).mintNft(TOKEN_URI);
        vm.stopBroadcast();
        }
}