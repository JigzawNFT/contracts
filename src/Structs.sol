// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

struct PoolStatus {
  /** Id of last token minted. */
  uint256 lastTokenMinted;
  /** Current price (in wei). */
  uint256 priceWei;
}

struct PoolCurve {
  /** Token id which start the price curve. */
  uint256 startId;
  /** Price at beginning (in wei). */
  uint256 startPriceWei;
  /** Percentage to increase price by (in bips, 1 bip = 0.01%) for each purchase. */
  uint256 expDeltaBips;
}

struct Signature {
  /** Signature bytes. */
  bytes signature;
  /** Deadline (block timestamp) */
  uint256 deadline;
}
