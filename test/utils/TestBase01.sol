// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { Auth } from "src/Auth.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";  
import { LotteryNFT } from "src/LotteryNFT.sol";

import {Test, console2 as c} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract TestBase01 is Test {
  uint public owner1_key = 0x123;
  address payable owner1 = payable(vm.addr(owner1_key));

  uint public minter1_key = 0x1234;
  address payable minter1 = payable(vm.addr(minter1_key));

  uint public revealer1_key = 0x12345;
  address payable revealer1 = payable(vm.addr(revealer1_key));

  address payable wallet1 = payable(address(0x1234567890));
  address payable wallet2 = payable(address(0x1234567890123));

  constructor() payable {
    c.log("\n Test SETUP:");
    c.log("Test contract address", address(this));
    c.log("msg.sender", msg.sender);
  }

  // Helper methods

  function _getDefaultJigzawNftConfig() internal view returns (JigzawNFT.Config memory) {
    return JigzawNFT.Config({
      owner: owner1,
      minter: minter1,
      revealer: revealer1,
      devRoyaltyFeeBips: 1000, /* 1000 bips = 10% */
      defaultImage: "img",
      devRoyaltyReceiver: owner1,
      lotteryPotFeeBips: 1000, /* 1000 bips = 10% */
      lotteryDeadline: block.timestamp,
      lotteryRevealThreshold: 10
    });
  }  

  function _getDefaultLotteryNftConfig(JigzawNFT t) internal view returns (LotteryNFT.Config memory) {
    return LotteryNFT.Config({
      minter: address(t),
      defaultImage: "img",
      royaltyReceiver: owner1,
      royaltyFeeBips: 1000
    });
  }

  function _computeMinterSig(bytes memory _data, uint _deadline) internal view returns (Auth.Signature memory) {
    return _computeSig(minter1_key, _data, _deadline);
  }

  function _computeRevealerSig(bytes memory _data, uint _deadline) internal view returns (Auth.Signature memory) {
    return _computeSig(revealer1_key, _data, _deadline);
  }

  function _computeOwnerSig(bytes memory _data, uint _deadline) internal view returns (Auth.Signature memory) {
    return _computeSig(owner1_key, _data, _deadline);
  }

  function _computeSig(uint _key, bytes memory _data, uint _deadline) internal pure returns (Auth.Signature memory) {
    bytes32 sigHash = MessageHashUtils.toEthSignedMessageHash(abi.encodePacked(_data, _deadline));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, sigHash);
    return Auth.Signature({
      signature: abi.encodePacked(r, s, v),
      deadline: _deadline
    });
  }

  function _toBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  // to exclude this file from coverage report
  function testTestBase01_ExcludeFromCoverage() public {}  
}
