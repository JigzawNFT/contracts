// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { MessageHashUtils } from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import { Auth } from "src/Auth.sol";

import {Test, console2 as c} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract TestBase01 is Test {
  constructor() payable {
    c.log("\n Test SETUP:");
    c.log("Test contract address", address(this));
    c.log("msg.sender", msg.sender);
  }

  // Helper methods

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
