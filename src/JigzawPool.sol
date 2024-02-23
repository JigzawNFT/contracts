// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IMintable } from "./IMintable.sol";
import { PoolCurve, PoolStatus } from "./Structs.sol";

/**
 * @dev Jigzaw NFT liquidity pool.
 *
 * Inspired by ERC404 and SudoSwap, this provides a way for users to mint, buy and sell NFTs easily from/to a self-managed 
 * liquidity pool. To be fair, this has probably been done before somewhere else!
 *
 * Initially no NFTs are minted. The first purchase mints an NFT. The price of an NFT increases with each mint. A minted 
 * NFT can be sold back into the pool at the current mint price to get back liquidity. The price of an NFT decreases with 
 * every sale back to the pool. Subsequent buyers will then first recieve existing NFTs already held by the pool before a new 
 * ones are minted.
 *
 * Mint price follows an exponential bonding curve, meaning price increases by a fixed percentage with each purchase.
 *
 * Different ranges of NFTs (e.g token ids 1 to 20 could be one "range") can have different bonding curves. Each curve only 
 * has access to its own liquidity.
 */
contract JigzawPool {
  IMintable public nft;
  PoolCurve public curve;
  PoolStatus public status;

  // Constructor

  /**
   * @dev Configuration parameters.
   */
  struct Config {
    /** JigzawNFT contractx. */
    address nft;
    /** Price curves (and thus liquidity pools) */
    PoolCurve curve;
  }

  constructor(Config memory _config) {
    nft = IMintable(_config.nft);
    curve = _config.curve;
    status = PoolStatus({
      lastMintId: 0,
      priceWei: curve.startPriceWei
    });
  }

  // ---------------------------------------------------------------
  // Buying
  // ---------------------------------------------------------------

  function buy() public payable {
    address payable sender = payable(msg.sender);

    (uint numTokens, uint finalAmountWei) = getBuyInfo(msg.value);

    if (numTokens > 0) {
      // transfer from balance first
      uint balance = nft.balanceOf(address(this));
      if (balance > 0) {
        uint toTransfer = balance < numTokens ? balance : numTokens;
        nft.safeTransferFrom(address(this), sender, toTransfer);
        numTokens -= toTransfer;
      }

      // mint remaining
      if (numTokens > 0) {
        nft.mint(sender, status.lastMintId, numTokens);
        status.lastMintId += numTokens;
      }

      // return excess wei
      if (finalAmountWei < msg.value) {
        sender.transfer(msg.value - finalAmountWei);
      }
    }
  }

  function getBuyInfo(uint amountWei) public view returns (uint numTokens, uint finalAmountWei) {
    // TODO: optimize this, remove the loop

    /*
    Since price moves up by a % after each buy, it would be possible to 
    buy and then immediately sell for a profit. To avoid this we'll 
    place the buy to be at the next price up.
    */
    uint nextPrice;
    uint tokensAvailable = nft.balanceOf(address(this)) + (curve.mintEndId - status.lastMintId);
    while (numTokens < tokensAvailable) {
      nextPrice = status.priceWei * curve.delta / 1e18;
      if (nextPrice > amountWei) {
        break;
      }
      amountWei -= nextPrice;
      finalAmountWei += nextPrice;
      numTokens++;
    }
  }

  // ---------------------------------------------------------------
  // Selling
  // ---------------------------------------------------------------


  function sell() public {
    // Buy
  }

  function getSellInfo(uint amountWei) public view returns (uint) {
  }
}
