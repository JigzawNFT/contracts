// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { TestBaseTop } from "test/utils/TestBaseTop.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";


contract SetRoyaltyFee is TestBaseTop {
  function test_SetRoyaltyFeeWhenOwner_Succeeds() public {
    vm.prank(t.owner());
    t.setRoyaltyFee(address(0x789), 200 /* 2% */);
    (address r1, uint r2) = t.royaltyInfo(0, 100);
    assertEq(r1, address(0x789));
    assertEq(r2, 2);
  }

  function test_SetRoyaltyFeeWhenNotOwner_Fails() public {
    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    t.setRoyaltyFee(address(0x789), 200);

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    t.setRoyaltyFee(address(0x789), 200);

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    t.setRoyaltyFee(address(0x789), 200);
  }
}
