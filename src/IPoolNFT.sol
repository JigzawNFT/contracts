// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Signature } from "./Common.sol";
import { IERC721 } from "openzeppelin/token/ERC721/IERC721.sol";
import { IERC2981 } from "openzeppelin/interfaces/IERC2981.sol";

/**
 * @dev Pool NFT.
 */
interface IPoolNFT is IERC721 {
  /**
   * @dev Mint tokens to the address.
   *
   * @param _to The address which will own the minted tokens.
   * @param _startId The id to start mint from.
   * @param _count No. of tokens to mint.
   */
  function mint(address _to, uint _startId, uint _count) external;

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
  function getRoyaltyInfo() external returns (address receiver, uint feeBips);
}
