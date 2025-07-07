// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20,SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "lib/openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop  is EIP712{
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event Claim(address _claimer, uint256 _amount );

    address[] claimer;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_Airdroptoken;
    mapping( address => bool ) private s_claimerMap;
    bytes32 private constant MESSAGE_TYPE_HASH= keccak256("AirdropClaim(address account,uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    constructor (IERC20 _token, bytes32 _merkleRoot) EIP712("MerkleAirdrop","1") {
        i_Airdroptoken = _token;
        i_merkleRoot = _merkleRoot; 
    }
    function claim(address _claimer,uint256 _amount, bytes32[] calldata _proof ,uint8 v, bytes32 r, bytes32 s) public {
        if(s_claimerMap[_claimer]==true) revert MerkleAirdrop__AlreadyClaimed();
        //check the sign
        if(!_isvalidSign( _claimer,getMessage(_claimer,_amount), v,r,s )) revert MerkleAirdrop__InvalidSignature();
        bytes32 leaf=keccak256(bytes.concat( keccak256(abi.encode(_claimer,_amount))));
        if(!MerkleProof.verify(_proof, i_merkleRoot,leaf)) revert MerkleAirdrop__InvalidProof();
        s_claimerMap[_claimer]=true;
        emit Claim(_claimer, _amount);
        i_Airdroptoken.safeTransfer(_claimer, _amount);
    }
    function getMessage(address _claimer,uint256 _amount) public view returns(bytes32){
         return _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPE_HASH,AirdropClaim({account:_claimer,amount:_amount}))));
    }
    function getMerkleRoot() public view returns(bytes32){
        return i_merkleRoot;
        }
    function getAirdropToken() public view returns(IERC20) {
        return i_Airdroptoken;
    }
    function _isvalidSign(address _claimer,bytes32 digest,uint8 v,bytes32 r, bytes32 s) internal pure returns(bool){
        (address actualSigner,,)= ECDSA.tryRecover(digest, v, r, s);
        return actualSigner==_claimer;
    }
}
