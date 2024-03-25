// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";


contract JigzawNftSetRevealer is JigzawNftTestBase {
  function test_SetRevealerWhenOwner_Succeeds() public {
    vm.prank(owner1);
    jigzawNft.setRevealer(address(0x789));
    assertEq(jigzawNft.revealer(), address(0x789));
  }

  function test_SetRevealerWhenNotOwner_Fails() public {
    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    jigzawNft.setRevealer(address(0x789));

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    jigzawNft.setRevealer(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    jigzawNft.setRevealer(address(0x789));
  }
}
