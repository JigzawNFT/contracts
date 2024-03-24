// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { IERC721Errors } from "openzeppelin/interfaces/draft-IERC6093.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";

contract JigzawNftTokenUri is JigzawNftTestBase {
  function setUp() virtual override public {
    super.setUp();

    uint id = 1;
    string memory uri = "";

    vm.prank(wallet1);
    t.mint(id, uri, _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    ));
  }

  function test_TokenUriReturnsDefaultUri() public {
    assertEq(t.tokenURI(1), _buildDefaultTokenUri(1));
  }

  function test_TokenUriReturnsRevealedUri() public {
    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(uint(1), "uri"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    t.reveal(uint(1), "uri", sig);

    assertEq(t.tokenURI(1), "uri");
  }
}
