// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;


/**
 * @dev Configuration parameters.
 */
struct Config {
  /** Owner. */
  address owner;
  /** Minter. */
  address minter;
  /** Revealer. */
  address revealer;
  /** Royalty fee */
  uint96 royaltyFeeBips;
  /** Default token image as a data URI. */
  string defaultImage;
}

struct Signature {
  /** Signature bytes. */
  bytes signature;
  /** Deadline (block timestamp) */
  uint256 deadline;
}
