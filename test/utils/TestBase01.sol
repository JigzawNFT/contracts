// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Signature } from "src/Structs.sol";

import {Test, console2 as c} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract TestBase01 is Test {
  constructor() payable {
    c.log("\n Test SETUP:");
    c.log("Test contract address", address(this));
    c.log("msg.sender", msg.sender);
  }

  // Helper methods

  function _computeSig(uint _key, bytes memory _data, uint _deadline) internal pure returns (Signature memory) {
    bytes32 sigHash = keccak256(abi.encodePacked(_data, _deadline));
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(_key, sigHash);
    return Signature({
      signature: abi.encodePacked(r, s, v),
      deadline: _deadline
    });
  }

  // to exclude this file from coverage report
  function testTestBase01_ExcludeFromCoverage() public {}  
}
