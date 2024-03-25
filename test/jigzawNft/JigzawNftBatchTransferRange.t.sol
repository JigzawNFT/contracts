// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { GoodERC721Receiver } from "../utils/TestBase01.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftBatchTransferRange is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    jigzawNft.setPool(pool1);

    vm.startPrank(pool1);
    jigzawNft.batchMint(wallet1, 1, 4);
    jigzawNft.batchMint(wallet2, 5, 1);
    vm.stopPrank();
  }

  function test_JigzawNftBatchTransferRange_ByOwner_Succeeds() public {
    vm.prank(wallet1);
    jigzawNft.batchTransferRange(wallet1, wallet2, 2);

    assertEq(jigzawNft.ownerOf(1), wallet1);
    assertEq(jigzawNft.ownerOf(2), wallet1);
    assertEq(jigzawNft.ownerOf(3), wallet2);
    assertEq(jigzawNft.ownerOf(4), wallet2);
    assertEq(jigzawNft.ownerOf(5), wallet2);

    assertEq(jigzawNft.totalSupply(), 5);
    assertEq(jigzawNft.balanceOf(wallet1), 2);
    assertEq(jigzawNft.balanceOf(wallet2), 3);

    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet1, 1), 2);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 0), 5);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 1), 4);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 2), 3);
  }

  function test_JigzawNftBatchTransferRange_ByPool_Succeeds() public {
    vm.prank(pool1);
    jigzawNft.batchTransferRange(wallet1, wallet2, 2);

    assertEq(jigzawNft.ownerOf(4), wallet2);
    assertEq(jigzawNft.ownerOf(3), wallet2);
  }

  function test_JigzawNftBatchTransferRangeIfNotAuthorised_Fails() public {
    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 4));
    jigzawNft.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_JigzawNftBatchTransferRange_IfAllAuthorised_Succeeds() public {
    vm.startPrank(wallet1);
    jigzawNft.approve(wallet2, 4);
    jigzawNft.approve(wallet2, 3);
    vm.stopPrank();

    vm.prank(wallet2);
    jigzawNft.batchTransferRange(wallet1, wallet2, 2);

    assertEq(jigzawNft.ownerOf(4), wallet2);
    assertEq(jigzawNft.ownerOf(3), wallet2);
  }

  function test_JigzawNftBatchTransferRange_IfNotAllAuthorised_Fails() public {
    vm.startPrank(wallet1);
    jigzawNft.approve(wallet2, 4);
    vm.stopPrank();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 3));
    jigzawNft.batchTransferRange(wallet1, wallet2, 2);
  }

  function test_JigzawNftBatchTransferRange_ToZeroAddress_Fails() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    jigzawNft.batchTransferRange(wallet1, address(0), 2);
  }

  function test_JigzawNftBatchTransfer_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    vm.prank(pool1);
    jigzawNft.batchTransferRange(wallet1, address(good), 2);

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
