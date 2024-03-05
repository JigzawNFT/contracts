// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract NftOwnersOf is NftTestBase {
  address wallet1 = address(0x888);
  address wallet2 = address(0x888111);

  function setUp() public override {
    super.setUp();

    vm.startPrank(pool1);
    t.batchMint(wallet1, 1, 4);
    t.batchMint(wallet2, 5, 1);
    vm.stopPrank();
  }

  function test_OwnersOf_ValidIds_Succeeds() public {
    uint[] memory ids_1 = new uint[](3);
    ids_1[0] = 1;
    ids_1[1] = 2;
    ids_1[2] = 5;

    address[] memory owners_1 = t.ownersOf(ids_1);

    assertEq(owners_1[0], wallet1);
    assertEq(owners_1[1], wallet1);
    assertEq(owners_1[2], wallet2);
  }

  function test_OwnersOf_InvalidIds_DoesNotThrow() public {
    uint[] memory ids_1 = new uint[](3);
    ids_1[0] = 1;
    ids_1[1] = 2;
    ids_1[2] = 6;

    address[] memory owners_1 = t.ownersOf(ids_1);

    assertEq(owners_1[0], wallet1);
    assertEq(owners_1[1], wallet1);
    assertEq(owners_1[2], address(0));
  }
}
