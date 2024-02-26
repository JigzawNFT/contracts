// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";

contract NftMintingByMinter is NftTestBase {
  address caller = address(0x999);
  address wallet = address(0x888);

  function test_MintWithMinterAuthorisation_Succeeds() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.batchMint(wallet, ids, sig);

    assertEq(t.ownerOf(1), wallet);
    assertEq(t.ownerOf(2), wallet);

    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet), 2);

    assertEq(t.tokenByIndex(0), 1);
    assertEq(t.tokenByIndex(1), 2);

    assertEq(t.tokenOfOwnerByIndex(wallet, 0), 1);
    assertEq(t.tokenOfOwnerByIndex(wallet, 1), 2);
  }

  function test_MintWithNotMinterAuthorisation_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    Auth.Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.batchMint(wallet, ids, sigOwner);

    Auth.Signature memory sigRevealer = _computeRevealerSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.batchMint(wallet, ids, sigRevealer);
  }

  function test_MintEmpty_Succeeds() public {
    uint[] memory ids = new uint[](0);

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.batchMint(wallet, ids, sig);

    assertEq(t.totalSupply(), 0);
  }

  function test_MintBadSignature_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    Auth.Signature memory sig = Auth.Signature({
      signature: bytes(""),
      deadline: block.timestamp + 10 seconds
    });

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.batchMint(wallet, ids, sig);
  }

  function test_MintExpiredSignature_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp - 1 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, caller));
    t.batchMint(wallet, ids, sig);
  }

  function test_MintSignatureAlreadyUsed_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.batchMint(wallet, ids, sig);

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, caller));
    t.batchMint(wallet, ids, sig);
  }

  function test_MintAlreadyMintedToken_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.batchMint(wallet, ids, sig);

    uint[] memory ids2 = new uint[](3);
    ids2[0] = 2;
    ids2[1] = 3;
    ids2[2] = 1; // should error coz already minted!

    Auth.Signature memory sig2 = _computeMinterSig(
      abi.encodePacked(wallet, ids2), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidSender.selector, address(0)));
    t.batchMint(wallet, ids2, sig2);
  }
}
