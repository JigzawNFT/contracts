// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";

contract NftTokenUri is NftTestBase {
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

  function test_TokenUriReturnsDefaultUri() public {
    assertEq(t.tokenURI(1), _buildDefaultTokenUri(1));
    assertEq(t.tokenURI(2), _buildDefaultTokenUri(2));
  }

  function test_TokenUriReturnsRevealedUri() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 2;

    string[] memory uris = new string[](1);
    uris[0] = "uri2";

    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    assertEq(t.tokenURI(1), _buildDefaultTokenUri(1));
    assertEq(t.tokenURI(2), "uri2");
  }
}
