// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "lib/openzepplin-contracts/contracts/access/Ownable.sol";
import {MessageHashUtils} from "lib/openzepplin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "../lib/openzepplin-contracts/contracts/utils/cryptography/ECDSA.sol";
contract MinimalAccount is IAccount, Ownable  {
    constructor() Ownable(msg.sender){

    }
        function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData){
        _validateSignature(userOp,userOpHash);
    }
    function _validateSignature ( PackedUserOperation calldata userOp,bytes32 userOpHash) external returns (uint256 validationData) {
        bytes32 ethSignedMessageHash= MessageHashUtils.
         

    }
}
