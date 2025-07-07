// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Test} from "forge-std/Test.sol";
import {DeployBasicNft} from "script/DeployBasicNft.s.sol";
import {BasicNFT} from "src/BasicNft.sol";
contract BasicNfttest is Test{
    DeployBasicNft public deployNft;    
    BasicNFT public basicNFT;
    address public USER= makeAddr("uesr");
    string public constant TOKEN_URI = "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    function setUp() public {
    deployNft= new DeployBasicNft();
    basicNFT=deployNft.run();
    }
    function testNameisCorrect () public {
    string memory expectedName="Heyi";
    string memory actualName=basicNFT.name();
    assertEq(keccak256(bytes(expectedName)),keccak256(bytes(actualName)));
    } 
    function testCanmintandhaveaBalance() public {
        vm.prank(USER);
        basicNFT.mintNft(TOKEN_URI);
        assert(basicNFT.balanceOf(USER)==1);
        assert(keccak256(abi.encodePacked(TOKEN_URI))==keccak256(abi.encodePacked(basicNFT.tokenURI(0))));
    }
 }