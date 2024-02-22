// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Signature } from "./Structs.sol";

/**
 * @dev A mintable NFT token, using authorisation signatures.
 */
interface IMintable {
  /**
   * @dev Mint tokens to the address.
   *
   * @param _to The address which will own the minted tokens.
   * @param _ids token ids to mint.
   * @param _sig minter authorisation signature.
   */
  function mint(address _to, uint[] calldata _ids, Signature calldata _sig) external;
}
