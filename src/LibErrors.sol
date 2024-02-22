// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

library LibErrors {
  /**
  * @dev The caller tried to mint an already minted token.
  */
  error AlreadyMinted(address caller, uint tokenId);

  /**
  * @dev The caller tried to mint nothing.
  */
  error MintEmpty(address caller);

  /**
   * @dev The token has already been revealed.
   */
  error AlreadyRevealed(uint256 tokenId);

  /**
   * @dev The caller supplied an expired signature.
   */
  error SignatureExpired(address caller);

  /**
   @dev The caller supplied an invalid signature.
   */
  error SignatureInvalid(address caller);

  /**
   * @dev The caller supplied an already used signature.
   */
  error SignatureAlreadyUsed(address caller);
}