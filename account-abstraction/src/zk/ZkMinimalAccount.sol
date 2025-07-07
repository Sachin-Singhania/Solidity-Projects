// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IAccount,ACCOUNT_VALIDATION_SUCCESS_MAGIC} from "../../lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {Transaction,MemoryTransactionHelper} from "../../lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from "../../lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

/**
 * Lifecycle of a type 113 (0x71) transaction
 * msg.sender is the bootloader system contract
 *
 * Phase 1 Validation
 * 1. The user sends the transaction to the "zkSync API client" (sort of a "light node")
 * 2. The zkSync API client checks to see the the nonce is unique by querying the NonceHolder system contract
 * 3. The zkSync API client calls validateTransaction, which MUST update the nonce
 * 4. The zkSync API client checks the nonce is updated
 * 5. The zkSync API client calls payForTransaction, or prepareForPaymaster & validateAndPayForPaymasterTransaction
 * 6. The zkSync API client verifies that the bootloader gets paid
 *
 * Phase 2 Execution
 * 7. The zkSync API client passes the validated transaction to the main node / sequencer (as of today, they are the same)
 * 8. The main node calls executeTransaction
 * 9. If a paymaster was used, the postTransaction is called
 */
contract ZkMinimalAccount is IAccount,Ownable {
    using MemoryTransactionHelper for Transaction;

    error ZK__NOTENOUGHBALANCE();
    error ZK__SIGNATUREFAILED();
    error ZK__OnlybootloaderCanCall();
    error ZK__TXEXECUTIONFAILED();
    error ZK__OnlybootloaderOrOwnerCanCall();
    
    modifier onlyBootloader() {
        if(msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZK__OnlybootloaderCanCall();
            }
            _;
    }
    modifier onlyBootloaderOrOwner() {
        if(msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert ZK__OnlybootloaderOrOwnerCanCall();
            }
            _;
    }
     
     constructor () Ownable(msg.sender)   {
     }
    // Similar like validateUserOp
    function validateTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external 
        payable onlyBootloader
        returns (bytes4 magic){
            return _validateTransaction(_transaction);
        }

    function executeTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable  onlyBootloaderOrOwner
        {
        _executeTransaction( _transaction);
        }

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable{
       bytes4 magic= _validateTransaction(_transaction);
       if(magic!=ACCOUNT_VALIDATION_SUCCESS_MAGIC) revert ZK__SIGNATUREFAILED();
        _executeTransaction(_transaction);
    }

    function payForTransaction(bytes32 _txHash, bytes32 _suggestedSignedHash, Transaction calldata _transaction)
        external
        payable{
             bool sucess = _transaction.payToTheBootloader();
        }

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable{}
    function _validateTransaction (Transaction calldata _transaction) internal
      returns (bytes4 magic){
            //inc nonce
            SystemContractsCaller.systemCallWithPropagatedRevert(uint32(gasleft()), address(NONCE_HOLDER_SYSTEM_CONTRACT), 0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals,(_transaction.nonce))
             );
             //check fee to pay
             uint256 total_req_bal= _transaction.totalRequiredBalance();
             if (total_req_bal>address(this).balance){
                revert ZK__NOTENOUGHBALANCE();
             }

             //check the signature
             bytes32 txhash=  _transaction.encodeHash();
            address signer = ECDSA.recover(txhash, _transaction.signature);
            bool isValidSign= signer == owner();
               if (isValidSign) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }

    }
     function _executeTransaction(Transaction memory _transaction) internal {
             //to, value, data
            address to =  address(uint160(_transaction.to));
            uint128 value = Utils.safeCastToU128(_transaction.value);
            bytes memory data = _transaction.data;
            if (to == address(DEPLOYER_SYSTEM_CONTRACT)){
                uint32 gas= Utils.safeCastToU32(gasleft());
                SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
            }else{
                bool success;
                assembly {
                    success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
                }
                if(!success) {
                    revert ZK__TXEXECUTIONFAILED();
                }
            }
     }
}