// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNftTestBase, GoodERC721Receiver } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftMintingByPool is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    t.setPool(pool1);
  }

  function test_MintByPool_Succeeds() public {
    vm.prank(pool1);
    t.batchMint(wallet1, 2);

    assertEq(t.ownerOf(1), wallet1);
    assertEq(t.ownerOf(2), wallet1);

    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet1), 2);

    assertEq(t.tokenByIndex(0), 1);
    assertEq(t.tokenByIndex(1), 2);

    assertEq(t.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet1, 1), 2);
  }

  function test_MintByPool_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    vm.prank(pool1);
    t.batchMint(address(good), 2);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived(0);
    assertEq(r.operator, pool1);
    assertEq(r.from, address(0));
    assertEq(r.tokenId, 1);
    assertEq(r.data, "");

    r = GoodERC721Receiver(good).getReceived(1);
    assertEq(r.operator, pool1);
    assertEq(r.from, address(0));
    assertEq(r.tokenId, 2);
    assertEq(r.data, "");
  }

  function test_MintByNotPool_Fails() public {
    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, owner1));
    t.batchMint(wallet1, 2);

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, minter1));
    t.batchMint(wallet1, 2);

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.Unauthorized.selector, revealer1));
    t.batchMint(wallet1, 2);
  }

  function test_MintEmpty_Fails() public {
    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidBatchSize.selector, uint(0)));
    t.batchMint(wallet1, 0);
  }

  function test_MintToZeroAddress_Fails() public {
    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    t.batchMint(address(0), 1);
  }
}
