// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

enum CurveQuoteError {
  NONE,
  INVALID_NUMITEMS,
  SPOT_PRICE_OVERFLOW
}

struct PoolStatus {
  /** Id of last token minted. */
  uint256 lastMintId;
  /** Current price (in wei). */
  uint128 priceWei;
}

struct PoolCurve {
  /** Token id to mint from. */
  uint256 mintStartId;
  /** Token id to mint to. */
  uint256 mintEndId;
  /** Price at beginning (in wei). */
  uint128 startPriceWei;
  /** 
  Multipler/divisor to apply after each purchase/sale. 
  
  Raw value should be multiplied by 1^18 to get the stored value. For example:
  - 1.1 = 1.1 * 1^18 = 1100000000000000000
  - 1.0001 = 1.0001 * 1^18 = 1000100000000000000
  */
  uint128 delta;
}

struct Signature {
  /** Signature bytes. */
  bytes signature;
  /** Deadline (block timestamp) */
  uint256 deadline;
}
