// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase, GoodERC721Receiver } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract NftMintingByPool is NftTestBase {
  address wallet = address(0x888);

  function test_MintByPool_Succeeds() public {
    vm.prank(pool1);
    t.batchMint(wallet, 1, 2);

    assertEq(t.ownerOf(1), wallet);
    assertEq(t.ownerOf(2), wallet);

    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet), 2);

    assertEq(t.tokenByIndex(0), 1);
    assertEq(t.tokenByIndex(1), 2);

    assertEq(t.tokenOfOwnerByIndex(wallet, 0), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet, 1), 2);
  }

  function test_MintByPool_InvokesReceiver() public {
    GoodERC721Receiver good = new GoodERC721Receiver();

    vm.prank(pool1);
    t.batchMint(address(good), 1, 2);

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
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, owner1));
    t.batchMint(wallet, 1, 2);

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, minter1));
    t.batchMint(wallet, 1, 2);

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, revealer1));
    t.batchMint(wallet, 1, 2);
  }

  function test_MintEmpty_Fails() public {
    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidBatchSize.selector, uint(0)));
    t.batchMint(wallet, 1, 0);
  }

  function test_MintToZeroAddress_Fails() public {
    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721ZeroAddress.selector));
    t.batchMint(address(0), 1, 1);
  }

  function test_MintAlreadyMintedToken_Fails() public {
    vm.prank(pool1);
    t.batchMint(wallet, 1, 3);

    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721TokenAlreadyMinted.selector, uint(3)));
    t.batchMint(wallet, 3, 1);
  }
}
