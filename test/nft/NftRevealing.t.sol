// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Signature } from "src/Common.sol";
import { LibErrors } from "src/LibErrors.sol";

contract NftRevealing is NftTestBase {
  address caller = address(0x999);
  address wallet = address(0x888);

  function setUp() virtual override public {
    super.setUp();

    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet, ids), 
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.mint(wallet, ids, sig);
  }

  function test_RevealWithRevealerAuthorisation_Succeeds() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    assertEq(t.tokenURI(1), "uri1");
    assertEq(t.tokenURI(2), "uri2");

    assertEq(t.revealed(1), true);
    assertEq(t.revealed(2), true);
    assertEq(t.revealed(3), false);
  }

  function test_RevealWithNotRevealerAuthorisation_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.reveal(ids, uris, sigOwner);

    Signature memory sigMinter = _computeOwnerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.reveal(ids, uris, sigMinter);
  }

  function test_RevealWithExpiredSignature_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp - 1 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, caller));
    t.reveal(ids, uris, sig);
  }

  function test_RevealWhenSignatureAlreadyUsed_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    string[] memory uris = new string[](1);
    uris[0] = "uri1";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, caller));
    t.reveal(ids, uris, sig);
  }

  function test_RevealWhenAlreadyRevealed_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    uint[] memory ids2 = new uint[](1);
    ids2[0] = 2;

    string[] memory uris2 = new string[](1);
    uris2[0] = "uri3";

    Signature memory sig2 = _computeRevealerSig(
      abi.encodePacked(ids2),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.AlreadyRevealed.selector, 2));
    t.reveal(ids2, uris2, sig2);
  }

  function test_RevealNonMintedToken_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 3;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri3";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 3));
    t.reveal(ids, uris, sig);
  }
}
