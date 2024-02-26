// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IERC721Errors } from "src/IERC721Errors.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";

contract NftRevealing is NftTestBase {
  address caller = address(0x999);
  address wallet = address(0x888);

  function setUp() virtual override public {
    super.setUp();

    uint id = 1;
    string memory uri = "";

    vm.prank(caller);
    t.mint(wallet, id, uri, _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    ));

    id = 2;
    uri = "";

    vm.prank(caller);
    t.mint(wallet, id, uri, _computeMinterSig(
      abi.encodePacked(wallet, id, uri), 
      block.timestamp + 10 seconds
    ));
  }

  function test_RevealWithRevealerAuthorisation_Succeeds() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    assertEq(t.tokenURI(1), "uri1");
    assertEq(t.tokenURI(2), "uri2");
  }

  function test_RevealWithNotRevealerAuthorisation_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Auth.Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, caller));
    t.reveal(ids, uris, sigOwner);

    Auth.Signature memory sigMinter = _computeOwnerSig(
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

    Auth.Signature memory sig = _computeRevealerSig(
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

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, caller));
    t.reveal(ids, uris, sig);
  }

  function test_RevealEmptyList_Fails() public {
    uint[] memory ids = new uint[](0);
    string[] memory uris = new string[](0);

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidTokenList.selector));
    t.reveal(ids, uris, sig);
  }

  function test_MismatchingBatchListLengths_Fails() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 1;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidBatchLengths.selector, 1, 2));
    t.reveal(ids, uris, sig);
  }

  function test_RevealWhenAlreadyRevealed_Fails() public {
    uint[] memory ids = new uint[](2);
    ids[0] = 1;
    ids[1] = 2;

    string[] memory uris = new string[](2);
    uris[0] = "uri1";
    uris[1] = "uri2";

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    uint[] memory ids2 = new uint[](1);
    ids2[0] = 2;

    string[] memory uris2 = new string[](1);
    uris2[0] = "uri3";

    Auth.Signature memory sig2 = _computeRevealerSig(
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

    vm.prank(caller);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721TokenNotMinted.selector, 3));
    t.reveal(ids, uris, _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    ));
  }
}
