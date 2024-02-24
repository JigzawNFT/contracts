// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";


contract NftSetRevealer is NftTestBase {
  function test_SetRevealerWhenOwner_Succeeds() public {
    vm.prank(owner1);
    t.setRevealer(address(0x789));
    assertEq(t.revealer(), address(0x789));
  }

  function test_SetRevealerWhenNotOwner_Fails() public {
    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    t.setRevealer(address(0x789));

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    t.setRevealer(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    t.setRevealer(address(0x789));
  }
}
