// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { TestBaseTop } from "./utils/TestBaseTop.sol";
import { Signature } from "../src/Structs.sol";
import { LibErrors } from "../src/LibErrors.sol";
import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";

contract MintingByPool is TestBaseTop {
  address wallet = address(0x888);

  function test_MintByPool_Succeeds() public {
    vm.prank(pool1);
    t.mint(wallet, 1, 2);

    assertEq(t.ownerOf(1), wallet);
    assertEq(t.ownerOf(2), wallet);

    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet), 2);

    assertEq(t.tokenByIndex(0), 1);
    assertEq(t.tokenByIndex(1), 2);

    assertEq(t.tokenOfOwnerByIndex(wallet, 0), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet, 1), 2);
  }

  function test_MintByNotPool_Fails() public {
    vm.prank(owner1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, owner1));
    t.mint(wallet, 1, 2);

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, minter1));
    t.mint(wallet, 1, 2);

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.UnauthorizedMustBePool.selector, revealer1));
    t.mint(wallet, 1, 2);
  }

  function test_MintEmpty_Succeeds() public {
    vm.prank(pool1);
    t.mint(wallet, 1, 0);
    assertEq(t.totalSupply(), 0);
  }

  function test_MintAlreadyMintedToken_Fails() public {
    vm.prank(pool1);
    t.mint(wallet, 1, 3);

    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidSender.selector, address(0)));
    t.mint(wallet, 3, 1);
  }
}
