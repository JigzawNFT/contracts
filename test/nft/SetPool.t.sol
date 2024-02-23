// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { TestBaseTop } from "test/utils/TestBaseTop.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";


contract SetPool is TestBaseTop {
  function test_SetPoolWhenOwner_Succeeds() public {
    vm.prank(owner1);
    t.setPool(address(0x789));
    assertEq(t.pool(), address(0x789));
  }

  function test_SetPoolWhenNotOwner_Fails() public {
    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    t.setPool(address(0x789));

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    t.setPool(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    t.setPool(address(0x789));
  }
}
