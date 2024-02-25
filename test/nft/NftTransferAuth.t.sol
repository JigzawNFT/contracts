// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { Signature } from "src/Common.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";

contract NftTransferAuth is NftTestBase {
  address wallet1 = address(0x8888);
  address wallet2 = address(0x9999);

  function setUp() public override {
    super.setUp();

    vm.prank(pool1);
    t.mint(wallet1, 1, 2);
  }

  function test_AnonTransfer_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, wallet2, 1));
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
