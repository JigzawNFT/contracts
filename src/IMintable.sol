// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Signature } from "./Common.sol";
import { IERC721 } from "openzeppelin/token/ERC721/IERC721.sol";

/**
 * @dev A mintable NFT.
 */
interface IMintable is IERC721 {
  /**
   * @dev Mint tokens to the address.
   *
   * @param _to The address which will own the minted tokens.
   * @param _startId The id to start mint from.
   * @param _count No. of tokens to mint.
   */
  function mint(address _to, uint _startId, uint _count) external;
}
