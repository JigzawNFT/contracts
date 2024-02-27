// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { IERC165 } from "openzeppelin/interfaces/IERC165.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC721Metadata } from "openzeppelin/interfaces/IERC721Metadata.sol";
import { IERC721Enumerable } from "openzeppelin/interfaces/IERC721Enumerable.sol";
import { IERC2981 } from "openzeppelin/interfaces/IERC2981.sol";
import { IERC4906 } from "openzeppelin/interfaces/IERC4906.sol";

contract NftInterface is NftTestBase {
  function test_SupportsInterfaces() public {
    // Test that the contract supports the ERC165 interface
    assertEq(t.supportsInterface(type(IERC165).interfaceId), true, "erc165");
    // Test that the contract supports the ERC721 interface
    assertEq(t.supportsInterface(type(IERC721).interfaceId), true, "erc721");
    // Test that the contract supports the ERC721Metadata interface
    assertEq(t.supportsInterface(type(IERC721Metadata).interfaceId), true, "erc721metadata");
    // Test that the contract supports the ERC721Enumerable interface
    assertEq(t.supportsInterface(type(IERC721Enumerable).interfaceId), true, "erc721enumerable");
    // Test that the contract supports the ERC721Royalty interface
    assertEq(t.supportsInterface(type(IERC2981).interfaceId), true, "erc2981");
    // Test that the contract supports the ERC721Royalty interface
    assertEq(t.supportsInterface(type(IERC4906).interfaceId), true, "erc4906");
  }
}