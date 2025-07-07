// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract BasicNFT is ERC721{
     uint256 private s_counterToken;
     mapping(uint256 => string) private s_tokenidtoURI;
    constructor() ERC721("Heyi","Hy"){
             s_counterToken = 0;
    }
    function mintNft(string memory _tokenURI) public {
         s_tokenidtoURI[s_counterToken]= _tokenURI;
        _safeMint(msg.sender, s_counterToken);
         s_counterToken++; 
    }
    function tokenURI(uint256 _tokenId) public view override returns(string memory){
        return s_tokenidtoURI[_tokenId];
    }
}
