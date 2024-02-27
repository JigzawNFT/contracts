// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { console2 as c } from "forge-std/Test.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

contract NftSetDefaultImage is NftTestBase {
  address wallet = address(0x8888887);

  function test_SetDefaultImageWhenOwner_Succeeds() public {
    vm.prank(owner1);
    t.setDefaultImage("newImage");
    assertEq(t.defaultImage(), "newImage");
  }

  function test_SetDefaultImageWhenOwner_EmitsEvent() public {
    t.mint(wallet, 1, "uri", _computeMinterSig(
      abi.encodePacked(wallet, uint256(1), "uri"), 
      block.timestamp + 10 seconds
    ));

    vm.recordLogs();

    vm.prank(t.owner());
    t.setDefaultImage("ten");

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(entries[0].topics.length, 1, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("BatchMetadataUpdate(uint256,uint256)"),
        "Invalid event signature"
    );
    (uint256 from, uint256 to) = abi.decode(entries[0].data, (uint256, uint256));
    assertEq(from, 1);
    assertEq(to, 1);
  }

  function test_SetDefaultImageWhenNotOwner_Fails() public {
    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    t.setDefaultImage("newImage");

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    t.setDefaultImage("newImage");

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    t.setDefaultImage("newImage");
  }
}
