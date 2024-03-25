// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNftTestBase, GoodERC721Receiver } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftBatchTransferRange is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    t.setPool(pool1);

    vm.startPrank(pool1);
    t.batchMint(wallet1, 4);
    t.batchMint(wallet2, 1);
    vm.stopPrank();
  }

  function test_JigzawNftBatchTransferRange_ByOwner_Succeeds() public {
    vm.prank(wallet1);
    t.batchTransferRange(wallet1, wallet2, 2);

    assertEq(t.ownerOf(1), wallet1);
    assertEq(t.ownerOf(2), wallet1);
    assertEq(t.ownerOf(3), wallet2);
    assertEq(t.ownerOf(4), wallet2);
    assertEq(t.ownerOf(5), wallet2);

    assertEq(t.totalSupply(), 5);
    assertEq(t.balanceOf(wallet1), 2);
    assertEq(t.balanceOf(wallet2), 3);

    assertEq(t.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet1, 1), 2);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 0), 5);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 1), 4);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 2), 3);
  }

  function test_JigzawNftBatchTransferRange_ByPool_Succeeds() public {
    vm.prank(pool1);
    t.batchTransferRange(wallet1, wallet2, 2);

    assertEq(t.ownerOf(4), wallet2);
    assertEq(t.ownerOf(3), wallet2);
  }

  function test_JigzawNftBatchTransferRangeIfNotAuthorised_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 4));
    t.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_JigzawNftBatchTransferRange_IfAllAuthorised_Succeeds() public {
    vm.startPrank(wallet1);
    t.approve(wallet2, 4);
    t.approve(wallet2, 3);
    vm.stopPrank();

    vm.prank(wallet2);
    t.batchTransferRange(wallet1, wallet2, 2);

    assertEq(t.ownerOf(4), wallet2);
    assertEq(t.ownerOf(3), wallet2);
  }

  function test_JigzawNftBatchTransferRange_IfNotAllAuthorised_Fails() public {
    vm.startPrank(wallet1);
    t.approve(wallet2, 4);
    vm.stopPrank();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 3));
    t.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_JigzawNftBatchTransferRange_ToZeroAddress_Fails() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    t.batchTransferRange(wallet1, address(0), 2);
  }

  function test_JigzawNftBatchTransfer_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    vm.prank(pool1);
    t.batchTransferRange(wallet1, address(good), 2);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived(0);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 4);
    assertEq(r.data, "");

    r = GoodERC721Receiver(good).getReceived(1);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 3);
    assertEq(r.data, "");
  }
}
