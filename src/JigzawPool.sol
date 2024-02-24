// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IMintable } from "./IMintable.sol";
import { LibErrors } from "./LibErrors.sol";
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
      lastMintId: curve.mintStartId - 1,
      priceWei: curve.startPriceWei
    });
  }


  function getCurveStatus() public view returns (PoolCurve memory, PoolStatus memory) {
    return (curve, status);
  }


  // ---------------------------------------------------------------
  // Buying
  // ---------------------------------------------------------------

  function buy() external payable {
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

  function getBuyInfo(uint amountWei) public view returns (uint numTokensBought, uint finalAmountWei) {
    /*
    Since price moves up by a % after each buy, it would be possible to 
    buy and then immediately sell for a profit. To avoid this we'll 
    place the buy to be at the next price up.
    */
    uint nextPrice = status.priceWei;
    uint tokensAvailable = nft.balanceOf(address(this)) + (curve.mintEndId - status.lastMintId);
    while (numTokensBought < tokensAvailable) {
      nextPrice = nextPrice * curve.delta / 1e18;
      if (nextPrice > amountWei) {
        break;
      }
      amountWei -= nextPrice;
      finalAmountWei += nextPrice;
      numTokensBought++;
    }
  }

  // ---------------------------------------------------------------
  // Selling
  // ---------------------------------------------------------------


  function sell(uint[] calldata tokenIds) external {
    address payable sender = payable(msg.sender);

    uint tokenBal = nft.balanceOf(sender);
    if (tokenIds.length > tokenBal) {
      revert LibErrors.InsufficientBalance(sender, tokenBal);
    }

    (uint numTokensSold, uint finalAmountWei) = getSellInfo(tokenIds.length);

    if (numTokensSold > 0) {
      // for each token
      for (uint i = 0; i < numTokensSold; i++) {
        uint id = tokenIds[i];
        
        // must be within supported range
        if (id < curve.mintStartId || id > curve.mintEndId) {
          revert LibErrors.TokenCannotBeSoldIntoPool(sender, id);
        }

        // transfer to pool
        nft.safeTransferFrom(sender, address(this), id);
      }

      // return wei
      sender.transfer(finalAmountWei);
    }
  }

  function getSellInfo(uint numTokens) public view returns (uint numTokensSold, uint finalAmountWei) {
    /*
    Since price down up by a % after each sell, it would be possible to 
    sell and then immediately buy for a profit. To avoid this we'll 
    place the sell to be at the next price down.
    */
    uint nextPrice = status.priceWei;
    uint bal = address(this).balance;
    while (bal > 0 && numTokens > 0) {
      nextPrice = nextPrice * 1e18 / curve.delta;
      if (nextPrice > bal) {
        break;
      }
      bal -= nextPrice;
      finalAmountWei += nextPrice;
      numTokensSold++;
      numTokens--;
    }
  }
}
