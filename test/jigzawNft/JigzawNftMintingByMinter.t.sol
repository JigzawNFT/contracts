// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;


import {console2 as c} from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";

contract JigzawNftMintingByMinter is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.prank(owner1);
    t.setLotteryTicketNFT(address(l));
  }

  function test_MintWithMinterAuthorisation_Succeeds() public {
    uint id = 2;
    string memory uri = "uri2";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    t.mint(id, uri, sig);

    assertEq(t.ownerOf(2), wallet1);
    assertEq(t.totalSupply(), 1);
    assertEq(t.balanceOf(wallet1), 1);
    assertEq(t.tokenByIndex(0), 2);
    assertEq(t.tokenOfOwnerByIndex(wallet1, 0), 2);
    assertEq(t.tokenURI(2), "uri2");

    id = 3;
    uri = "uri3";

    sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    t.mint(id, uri, sig);

    assertEq(t.ownerOf(3), wallet1);
    assertEq(t.totalSupply(), 2);
    assertEq(t.balanceOf(wallet1), 2);
    assertEq(t.tokenByIndex(1), 3);
    assertEq(t.tokenOfOwnerByIndex(wallet1, 1), 3);
    assertEq(t.tokenURI(3), "uri3");
  }

  function test_MintWithMinterAuthorisation_EmitsEvent() public {
    vm.recordLogs();

    vm.prank(wallet1);
    t.mint(1, "uri", _computeMinterSig(
      abi.encodePacked(wallet1, uint256(1), "uri"), 
      block.timestamp + 10 seconds
    ));

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 2, "Invalid entry count");
    assertEq(entries[1].topics.length, 1, "Invalid event count");
    assertEq(
        entries[1].topics[0],
        keccak256("MetadataUpdate(uint256)"),
        "Invalid event signature"
    );
    (uint256 tokenId) = abi.decode(entries[1].data, (uint256));
    assertEq(tokenId, 1, "Invalid token id");
  }

  function test_MintWithNotMinterAuthorisation_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, wallet1));
    t.mint(id, uri, sigOwner);

    Auth.Signature memory sigRevealer = _computeRevealerSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, wallet1));
    t.mint(id, uri, sigRevealer);
  }

  function test_MintBadSignature_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = Auth.Signature({
      signature: bytes(""),
      deadline: block.timestamp + 10 seconds
    });

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, wallet1));
    t.mint(id, uri, sig);
  }

  function test_MintExpiredSignature_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp - 1 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, wallet1));
    t.mint(id, uri, sig);
  }

  function test_MintSignatureAlreadyUsed_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    t.mint(id, uri, sig);

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, wallet1));
    t.mint(id, uri, sig);
  }

  function test_MintAlreadyMintedToken_Fails() public {
    uint id = 1;
    string memory uri = "uri";

    Auth.Signature memory sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    t.mint(id, uri, sig);

    uri = "uri2";

    sig = _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721TokenAlreadyMinted.selector, 1));
    t.mint(id, uri, sig);
  }
}
