// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

library LibErrors {
  /**
  * @dev Only pool is allowed to call this.
  */
  error UnauthorizedMustBePool(address caller);

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

  /**
  * @dev The sender provided insufficient funds.
  */
  error InsufficientSenderFunds(address sender, uint fundsRequired, uint fundsProvided);

  /**
  * @dev The sender has an insufficient NFT balance.
  */
  error InsufficientSenderNfts(address sender, uint balanceRequired, uint balanceAvailable);

  /**
  * @dev The token id is out of range.
   */
  error TokenIdOutOfRange(address caller, uint tokenId);

  /**
   * @dev Invalid batch operation array lengths.
   */
  error InvalidBatchLengths(uint length1, uint length2);

  /**
   * @dev Invalid token input list.
   */
  error InvalidTokenList();

  /**
  * @dev Invalid mint starting price.
  */
  error InvalidStartPrice(uint price);

  /**
  * @dev Invalid mint start id.
  */
  error InvalidMintStartId(uint id);

  /**
  * @dev Invalid mint end id.
  */
  error InvalidMintEndId(uint id);
}