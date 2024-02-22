// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { TestBaseTop } from "./utils/TestBaseTop.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { Config, Signature } from "../src/Structs.sol";


contract SetMinter is TestBaseTop {
  function test_SetMinterWhenOwner_Succeeds() public {
    vm.prank(owner1);
    t.setMinter(address(0x789));
    assertEq(t.minter(), address(0x789));
  }

  function test_SetMinterWhenNotOwner_Fails() public {
    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    t.setMinter(address(0x789));

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    t.setMinter(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    t.setMinter(address(0x789));
  }
}
