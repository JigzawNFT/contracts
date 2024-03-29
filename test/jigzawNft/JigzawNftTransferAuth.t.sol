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
    jigzawNft.setPool(pool1);

    vm.prank(pool1);
    jigzawNft.batchMint(wallet1, 1, 2);
  }

  function test_IsApprovedForAll_WithPool() public {
    assertEq(jigzawNft.isApprovedForAll(wallet1, pool1), true);
    assertEq(jigzawNft.isApprovedForAll(wallet2, pool1), true);
  }

  function test_AnonTransfer_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 1));
    jigzawNft.transferFrom(wallet1, wallet2, 1);
  }

  function test_ApprovedTransfer_Succeeds() public {
    vm.prank(wallet1);
    jigzawNft.approve(wallet2, 1);

    vm.prank(wallet2);
    jigzawNft.transferFrom(wallet1, wallet2, 1);

    assertEq(jigzawNft.ownerOf(1), wallet2);
    assertEq(jigzawNft.ownerOf(2), wallet1);
  }

  function test_PoolTransfer_Succeeds() public {
    vm.prank(pool1);
    jigzawNft.transferFrom(wallet1, wallet2, 1);

    assertEq(jigzawNft.ownerOf(1), wallet2);
    assertEq(jigzawNft.ownerOf(2), wallet1);
  }
}
