// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Base64} from "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
contract MoodNft is ERC721 {
    error MOODNFT__CantFlipMoodIsNotOwner();

    uint256 private s_tokenCounter;
    string private s_sadSvg;
    string private s_happySvg;

    enum Mood {
        SAD,
        HAPPY
    }
    mapping(uint256 => Mood) private s_tokenIdtoMood;
    constructor(
        string memory _sadSvg_imageuri,
        string memory _happySvg_imageuri
    ) ERC721("MoodNft", "MNFT") {
        s_tokenCounter = 0;
        s_sadSvg = _sadSvg_imageuri;
        s_happySvg = _happySvg_imageuri;
    }

    function mintNft() public {
        _safeMint(msg.sender, s_tokenCounter);
        s_tokenIdtoMood[s_tokenCounter] = Mood.HAPPY;
        s_tokenCounter++;
    }

    function _baseURI() internal pure override returns (string memory) {
         return "data:application/json;base64,"; 
    }
    function flipmood(uint256 tokenId) public {
        //only owner
        // if(!getApproved(msg.sender,tokenId)) revert MOODNFT__CantFlipMoodIsNotOwner();
         if (getApproved(tokenId) != msg.sender && ownerOf(tokenId) != msg.sender) {
            revert MOODNFT__CantFlipMoodIsNotOwner();
        }
        if(s_tokenIdtoMood[tokenId]==Mood.HAPPY) {
            s_tokenIdtoMood[tokenId] = Mood.SAD;
        }else{
            s_tokenIdtoMood[tokenId] = Mood.HAPPY;
        }
    }
    function tokenURI(
        uint256 tokenid
    ) public view override returns (string memory) {
        string memory imageURI;
        if (s_tokenIdtoMood[tokenid] == Mood.SAD) {
            imageURI = s_sadSvg;
        } else {
            imageURI = s_happySvg;
        }
        string memory tokenMetaData = string(
            abi.encodePacked(
                _baseURI(),
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name(),
                            '", "description":"An NFT that reflects the mood of the owner, 100% on Chain!", ',
                            '"attributes": [{"trait_type": "moodiness", "value": 100}], "image":"',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
        return tokenMetaData;
    }
}
