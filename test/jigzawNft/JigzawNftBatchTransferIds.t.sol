// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { GoodERC721Receiver } from "../utils/TestBase01.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftBatchTransferIds is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    jigzawNft.setPool(pool1);

    vm.startPrank(pool1);
    jigzawNft.batchMint(wallet1, 1, 2);
    jigzawNft.batchMint(wallet2, 3, 1);
    vm.stopPrank();
  }

  function _getIdsToTransfer() internal pure returns (uint[] memory) {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;
    return ids;
  }

  function test_JigzawNftBatchTransferIds_ByOwner_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet1);
    jigzawNft.batchTransferIds(wallet1, wallet2, ids);

    assertEq(jigzawNft.ownerOf(1), wallet2);
    assertEq(jigzawNft.ownerOf(2), wallet2);
    assertEq(jigzawNft.ownerOf(3), wallet2);

    assertEq(jigzawNft.totalSupply(), 3);
    assertEq(jigzawNft.balanceOf(wallet1), 0);
    assertEq(jigzawNft.balanceOf(wallet2), 3);

    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet1, 0), 0);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 0), 3);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 1), 1);
    assertEq(jigzawNft.tokenOfOwnerByIndex(wallet2, 2), 2);
  }

  function test_JigzawNftBatchTransferIds_ByPool_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(pool1);
    jigzawNft.batchTransferIds(wallet1, wallet2, ids);

    assertEq(jigzawNft.ownerOf(1), wallet2);
    assertEq(jigzawNft.ownerOf(2), wallet2);
  }

  function test_JigzawNftBatchTransferIdsIfNotAuthorised_Fails() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 1));
    jigzawNft.batchTransferIds(wallet1, wallet2, ids);
  }

  function test_JigzawNftBatchTransferIds_IfAllAuthorised_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.startPrank(wallet1);
    jigzawNft.approve(wallet2, 1);
    jigzawNft.approve(wallet2, 2);
    vm.stopPrank();

    vm.prank(wallet2);
    jigzawNft.batchTransferIds(wallet1, wallet2, ids);

    assertEq(jigzawNft.ownerOf(1), wallet2);
    assertEq(jigzawNft.ownerOf(2), wallet2);
  }

  function test_JigzawNftBatchTransferIds_IfNotAllAuthorised_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.startPrank(wallet1);
    jigzawNft.approve(wallet2, 1);
    vm.stopPrank();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 2));
    jigzawNft.batchTransferIds(wallet1, wallet2, ids);
  }

  function test_JigzawNftBatchTransferIds_ToZeroAddress_Fails() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    jigzawNft.batchTransferIds(wallet1, address(0), ids);
  }

  function test_JigzawNftBatchTransfer_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    uint[] memory ids = _getIdsToTransfer();

    vm.prank(pool1);
    jigzawNft.batchTransferIds(wallet1, address(good), ids);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived(0);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 1);
    assertEq(r.data, "");

    r = GoodERC721Receiver(good).getReceived(1);
    assertEq(r.operator, pool1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 2);
    assertEq(r.data, "");
  }
}
