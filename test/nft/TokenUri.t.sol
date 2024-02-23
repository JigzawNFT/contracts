// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";
import { TestBaseTop } from "test/utils/TestBaseTop.sol";
import { Signature } from "src/Structs.sol";
import { LibErrors } from "src/LibErrors.sol";

contract TokenUri is TestBaseTop {
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

  function test_TokenUriReturnsDefaultUri() public {
    assertEq(t.tokenURI(1), _buildDefaultTokenUri(1));
    assertEq(t.tokenURI(2), _buildDefaultTokenUri(2));
  }

  function test_TokenUriReturnsRevealedUri() public {
    uint[] memory ids = new uint[](1);
    ids[0] = 2;

    string[] memory uris = new string[](1);
    uris[0] = "uri2";

    Signature memory sig = _computeRevealerSig(
      abi.encodePacked(ids),
      block.timestamp + 10 seconds
    );

    vm.prank(caller);
    t.reveal(ids, uris, sig);

    assertEq(t.tokenURI(1), _buildDefaultTokenUri(1));
    assertEq(t.tokenURI(2), "uri2");
  }
}
