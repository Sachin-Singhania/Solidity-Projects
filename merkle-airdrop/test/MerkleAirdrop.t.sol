// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BegelToken} from "../src/BegelToken.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkle.s.sol"; 
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
contract MerkleAirdroptest is Test,ZkSyncChainChecker {
    MerkleAirdrop public merkleAirdrop;
    BegelToken public begelToken;
    bytes32 public ROOT=0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address gasPayer;
    address user;
    uint256 userPrivKey;
    
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF= [proofOne,proofTwo];
    uint256 public amount= 25 *1e18;

    function setUp() public {
        if(!isZkSyncChain()) {
             DeployMerkleAirdrop deploy = new DeployMerkleAirdrop();
             (merkleAirdrop,begelToken) = deploy.deployMerkle();
        }else{
        begelToken = new BegelToken();
        merkleAirdrop = new MerkleAirdrop(begelToken,ROOT);
        begelToken.mint(begelToken.owner(),amount*4); 
        begelToken.transfer(address(merkleAirdrop),amount*4);
        }
        (user, userPrivKey ) = makeAddrAndKey("user");
        gasPayer = makeAddr("gasPayer");
    }
    function test_UserCanClaim() public {
        uint256 startingBal= begelToken.balanceOf(user);
        console.log(startingBal);
        bytes32 digest = merkleAirdrop.getMessage(user,amount);
        (uint8 v , bytes32 r, bytes32 s  )=vm.sign(userPrivKey,digest);

        vm.prank(gasPayer);    
        merkleAirdrop.claim(user, amount ,PROOF, v, r, s);
        uint256 endingBal= begelToken.balanceOf(user);
        console.log(endingBal);
        assertEq(endingBal- startingBal , amount);
    }
}
