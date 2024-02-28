// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase, GoodERC721Receiver } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract NftBatchTransferIds is NftTestBase {
  address wallet1 = address(0x888);
  address wallet2 = address(0x888111);

  function setUp() public override {
    super.setUp();

    vm.startPrank(pool1);
    t.batchMint(wallet1, 1, 2);
    t.batchMint(wallet2, 3, 1);
    vm.stopPrank();
  }

  function _getIdsToTransfer() internal pure returns (uint[] memory) {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;
    return ids;
  }

  function test_NftBatchTransferIds_ByOwner_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet1);
    t.batchTransferIds(wallet1, wallet2, ids);

    assertEq(t.ownerOf(1), wallet2);
    assertEq(t.ownerOf(2), wallet2);
    assertEq(t.ownerOf(3), wallet2);

    assertEq(t.totalSupply(), 3);
    assertEq(t.balanceOf(wallet1), 0);
    assertEq(t.balanceOf(wallet2), 3);

    assertEq(t.tokenOfOwnerByIndex(wallet1, 0), 0);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 0), 3);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 1), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet2, 2), 2);
  }

  function test_NftBatchTransferIds_ByPool_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(pool1);
    t.batchTransferIds(wallet1, wallet2, ids);

    assertEq(t.ownerOf(1), wallet2);
    assertEq(t.ownerOf(2), wallet2);
  }

  function test_NftBatchTransferIdsIfNotAuthorised_Fails() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NotAuthorized.selector, wallet1, wallet2, 1));
    t.batchTransferIds(wallet1, wallet2, ids);
  }

  function test_NftBatchTransferIds_IfAuthorised_Succeeds() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.startPrank(wallet1);
    t.approve(wallet2, 1);
    t.approve(wallet2, 2);
    vm.stopPrank();

    vm.prank(wallet2);
    t.batchTransferIds(wallet1, wallet2, ids);

    assertEq(t.ownerOf(1), wallet2);
    assertEq(t.ownerOf(2), wallet2);
  }

  function test_NftBatchTransferIds_ToZeroAddress_Fails() public {
    uint[] memory ids = _getIdsToTransfer();

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    t.batchTransferIds(wallet1, address(0), ids);
  }

  function test_NftBatchTransfer_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    uint[] memory ids = _getIdsToTransfer();

    vm.prank(pool1);
    t.batchTransferIds(wallet1, address(good), ids);

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
