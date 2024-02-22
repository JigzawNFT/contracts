// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { TestBaseTop } from "./utils/TestBaseTop.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { Config, Signature } from "../src/Structs.sol";


contract SetDefaultImage is TestBaseTop {
  function test_SetDefaultImageWhenOwner_Succeeds() public {
    vm.prank(owner1);
    t.setDefaultImage("newImage");
    assertEq(t.defaultImage(), "newImage");
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
