// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BegelToken} from "../src/BegelToken.sol";

contract DeployMerkleAirdrop is Script{
     MerkleAirdrop public merkleAirdrop;
     BegelToken public begelToken;
    bytes32 public ROOT=0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    function run() public returns (MerkleAirdrop,BegelToken){
       return deployMerkle();
    }
    function deployMerkle() public returns (MerkleAirdrop,BegelToken){
        vm.startBroadcast();
        begelToken = new BegelToken();
        merkleAirdrop = new MerkleAirdrop(IERC20(address(begelToken )),ROOT);
        begelToken.mint(begelToken.owner(),25e18);
        begelToken.transfer(address(merkleAirdrop),25e18);
        vm.stopBroadcast();
        return (merkleAirdrop,begelToken);
    }
}

