// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.24;

// errors
error ERC721TokenNotMinted(uint256 id);
error ERC721TokenAlreadyMinted(uint256 id);
error ERC721ZeroAddress();
error ERC721InvalidBatchSize(uint size);
error ERC721InvalidOwner(address from, uint256 id);
error ERC721NotAuthorized(address sender, uint256 id);
error ERC721UnsafeTokenReceiver(address to, uint256 id);