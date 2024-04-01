// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";


contract JigzawNftSetPool is JigzawNftTestBase {
  function test_SetPoolWhenOwner_Succeeds() public {
    vm.prank(owner1);
    jigzawNft.setPool(address(0x789));
    assertEq(jigzawNft.pool(), address(0x789));
  }

  function test_SetPoolWhenNotOwner_Fails() public {
    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    jigzawNft.setPool(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    jigzawNft.setPool(address(0x789));
  }
}
