// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract NftMintingByMinter is NftTestBase {
  address caller = address(0x999);
  address wallet = address(0x888);

  function test_MintWithMinterAuthorisation_Succeeds() public {
    uint id = 2;
    string memory uri = "uri2";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.mint(wallet, id, uri, sig);

    assertEq(t.ownerOf(2), wallet);
    assertEq(t.totalSupply(), 1);
    assertEq(t.balanceOf(wallet), 1);
    assertEq(t.tokenByIndex(0), 2);
    assertEq(t.tokenOfOwnerByIndex(wallet, 0), 2);
    assertEq(t.tokenURI(2), "uri2");

    id = 3;
    uri = "uri3";

    sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.mint(wallet, id, uri, sig);

    assertEq(t.ownerOf(3), wallet);
    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet), 2);
    assertEq(t.tokenByIndex(1), 3);
    assertEq(t.tokenOfOwnerByIndex(wallet, 1), 3);
    assertEq(t.tokenURI(3), "uri3");
  }

  function test_MintWithNotMinterAuthorisation_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.mint(wallet, id, uri, sigOwner);

    Auth.Signature memory sigRevealer = _computeRevealerSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.mint(wallet, id, uri, sigRevealer);
  }

  function test_MintBadSignature_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = Auth.Signature({
      signature: bytes(""),
      deadline: block.timestamp + 10 seconds
    });

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.mint(wallet, id, uri, sig);
  }

  function test_MintExpiredSignature_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp - 1 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, caller));
    t.mint(wallet, id, uri, sig);
  }

  function test_MintSignatureAlreadyUsed_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.mint(wallet, id, uri, sig);

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, caller));
    t.mint(wallet, id, uri, sig);
  }

  function test_MintAlreadyMintedToken_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.mint(wallet, id, uri, sig);

    uri = "uri2";

    sig = _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721TokenAlreadyMinted.selector, 1));
    t.mint(wallet, id, uri, sig);
  }
}
