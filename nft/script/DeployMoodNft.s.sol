// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {Script,console} from "forge-std/Script.sol";
import {MoodNft} from "src/MoodNft.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";

contract DeployMoodNft is Script{
    function run() external returns(MoodNft) {
           string memory sadSvg = vm.readFile("./img/sad.svg");
        string memory happySvg = vm.readFile("./img/happy.svg");
              vm.startBroadcast();
        MoodNft moodnft = new MoodNft(svgToImageURI(sadSvg),svgToImageURI(happySvg));
        vm.stopBroadcast(); 
        return moodnft;
    }
    function svgToImageURI(string memory svg) public pure returns (string memory) {
      string memory baseURI = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(
            bytes(string(abi.encodePacked(svg))) // Removing unnecessary type castings, this line can be resumed as follows : 'abi.encodePacked(svg)'
        );
        return string(abi.encodePacked(baseURI, svgBase64Encoded));
        }
}