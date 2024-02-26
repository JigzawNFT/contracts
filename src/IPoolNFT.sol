// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IERC721 } from "openzeppelin/token/ERC721/IERC721.sol";

/**
 * @dev Pool NFT.
 *
 * All mutations should be protected such that only the pool can call them.
 */
interface IPoolNFT is IERC721 {
  /**
   * @dev Batch mint tokens to the address.
   *
   * @param _to The address which will own the minted tokens.
   * @param _startId The id to start mint from.
   * @param _count No. of tokens to mint.
   */
  function batchMint(address _to, uint _startId, uint _count) external;

  /**
   * @dev Batch transfer specific tokens to given address.
   *
   * @param _from The address to transfer from.
   * @param _to The address to transfer to.
   * @param _tokenIds token ids to transfer.
   */
  function batchTransferTokenIds(address _from, address _to, uint[] calldata _tokenIds) external;

  /**
   * @dev Batch transfer tokens to given address.
   *
   * @param _from The address to transfer from.
   * @param _to The address to transfer to.
   * @param _num num tokens to transfer.
   */
  function batchTransferNumTokens(address _from, address _to, uint _num) external;

  /**
  * @dev Get royalty info.
  */
  function getRoyaltyInfo() external view returns (address receiver, uint feeBips);
}
