// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ZkSyncChainChecker} from "../lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMinimal} from "../script/DeployMinimal.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {SendPackedUserOp,PackedUserOperation} from "../script/SendPackedUserops.s.sol";
import {MinimalAccount} from "../src/eth/MinimalAccount.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
 import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {IEntryPoint} from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";


contract MinimalAccountTest is Test ,ZkSyncChainChecker{
      using MessageHashUtils for bytes32;
      HelperConfig helperconfig;
      MinimalAccount minimalAccount;
      ERC20Mock usdc;
      SendPackedUserOp sendPackedUserOp;
      PackedUserOperation[] packedUserOperations;
      
       address randomuser = makeAddr("randomUser");
      uint256 public constant AMOUNT = 1e18;
      function setUp() public {
        DeployMinimal deploy = new DeployMinimal();
        (helperconfig, minimalAccount) = deploy.deployMinimalAccount();
        usdc= new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
      }
      function testMinimalAccount() public {
      //act
      assertEq(usdc.balanceOf(address(minimalAccount)),0);
      address dest = address(usdc);
      uint256 val=0;
      bytes memory funData= abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),AMOUNT);
      vm.prank(minimalAccount.owner());
      minimalAccount.execute(dest,val,funData);
      assertEq(usdc.balanceOf(address(minimalAccount)),AMOUNT);
      }
      function testNonOwnerCannotExecuteCommands() public{
      assertEq(usdc.balanceOf(address(minimalAccount)),0);
      address dest = address(usdc);
      uint256 val=0;
      bytes memory funData= abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),AMOUNT);
      vm.prank(randomuser);
      vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
      minimalAccount.execute(dest,val,funData);
      }
      function testPackedUserOpHash() public {
      assertEq(usdc.balanceOf(address(minimalAccount)),0);
      address dest = address(usdc);
      uint256 val=0;
      bytes memory funData= abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),AMOUNT);

      bytes memory executeFunData= abi.encodeWithSelector(MinimalAccount.execute.selector, dest,val,funData);
      
      PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeFunData,helperconfig.getConfig(), address(minimalAccount));
      
      bytes32 packedUserOpHash = IEntryPoint(helperconfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
      
      address ActualSigner= ECDSA.recover(packedUserOpHash.toEthSignedMessageHash(), packedUserOp.signature );
      
      assertEq(ActualSigner,minimalAccount.owner());


      }
    function testVaildateUserOp() public{
      assertEq(usdc.balanceOf(address(minimalAccount)),0);
      address dest = address(usdc);
      uint256 val=0;
      bytes memory funData= abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),AMOUNT);

      bytes memory executeFunData= abi.encodeWithSelector(MinimalAccount.execute.selector, dest,val,funData);
      
      PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeFunData,helperconfig.getConfig(), address(minimalAccount));
      bytes32 packedUserOpHash = IEntryPoint(helperconfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
      vm.startPrank(helperconfig.getConfig().entryPoint);
     uint256 validationData= minimalAccount.validateUserOp(packedUserOp, packedUserOpHash,1e18 );
     vm.stopPrank();
     assertEq(validationData, 0);

    }
    function testExecuteUserOp() public{
       assertEq(usdc.balanceOf(address(minimalAccount)),0);
      address dest = address(usdc);
      uint256 val;
      bytes memory funData= abi.encodeWithSelector(ERC20Mock.mint.selector,address(minimalAccount),AMOUNT);

      bytes memory executeFunData= abi.encodeWithSelector(MinimalAccount.execute.selector, dest,val,funData);
      
      PackedUserOperation memory packedUserOp = sendPackedUserOp.generateSignedUserOperation(executeFunData,helperconfig.getConfig(), address(minimalAccount));
        packedUserOperations.push( packedUserOp);
      bytes32 packedUserOpHash = IEntryPoint(helperconfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
      deal(address(minimalAccount), 1e18);
      vm.startPrank(randomuser);
        IEntryPoint(helperconfig.getConfig().entryPoint).handleOps(packedUserOperations, payable(randomuser));
     vm.stopPrank();
      console.log(address(minimalAccount).balance);
     assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
