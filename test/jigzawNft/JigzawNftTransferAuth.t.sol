// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftTransferAuth is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    t.setPool(pool1);

    vm.prank(pool1);
    t.batchMint(wallet1, 1, 2);
  }

  function test_IsApprovedForAll_WithPool() public {
    assertEq(t.isApprovedForAll(wallet1, pool1), true);
    assertEq(t.isApprovedForAll(wallet2, pool1), true);
  }

  function test_AnonTransfer_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 1));
    t.transferFrom(wallet1, wallet2, 1);
  }

  function test_ApprovedTransfer_Succeeds() public {
    vm.prank(wallet1);
    t.approve(wallet2, 1);

    vm.prank(wallet2);
    t.transferFrom(wallet1, wallet2, 1);

    assertEq(t.ownerOf(1), wallet2);
    assertEq(t.ownerOf(2), wallet1);
  }

  function test_PoolTransfer_Succeeds() public {
    vm.prank(pool1);
    t.transferFrom(wallet1, wallet2, 1);

    assertEq(t.ownerOf(1), wallet2);
    assertEq(t.ownerOf(2), wallet1);
  }
}
