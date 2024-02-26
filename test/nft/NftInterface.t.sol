// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { NftTestBase } from "./NftTestBase.sol";
import { IERC165 } from "openzeppelin/interfaces/IERC165.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC721Metadata } from "openzeppelin/interfaces/IERC721Metadata.sol";
import { IERC721Enumerable } from "openzeppelin/interfaces/IERC721Enumerable.sol";
import { IERC2981 } from "openzeppelin/interfaces/IERC2981.sol";

contract NftInterface is NftTestBase {
  function test_SupportsInterfaces() public {
    // Test that the contract supports the ERC165 interface
    assertTrue(t.supportsInterface(type(IERC165).interfaceId));
    // Test that the contract supports the ERC721 interface
    assertTrue(t.supportsInterface(type(IERC721).interfaceId));
    // Test that the contract supports the ERC721Metadata interface
    assertTrue(t.supportsInterface(type(IERC721Metadata).interfaceId));
    // Test that the contract supports the ERC721Enumerable interface
    assertTrue(t.supportsInterface(type(IERC721Enumerable).interfaceId));
    // Test that the contract supports the ERC721Royalty interface
    assertTrue(t.supportsInterface(type(IERC2981).interfaceId));
  }
}