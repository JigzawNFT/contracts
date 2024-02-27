// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IPoolNFT } from "./IPoolNFT.sol";
import { LibErrors } from "./LibErrors.sol";
import { PoolCurve, PoolStatus, CurveQuoteError } from "./Common.sol";
import { ExponentialCurve } from "./ExponentialCurve.sol";

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
contract JigzawPool is ExponentialCurve {
  IPoolNFT public nft;
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
    nft = IPoolNFT(_config.nft);
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

  function buy(uint numItems) external payable {
    address sender = payable(msg.sender);
    (BuyQuote memory quote, address feeReceiver) = getBuyQuote(numItems);

    if (quote.error == CurveQuoteError.NONE) {
      // check input
      if (quote.inputValue > msg.value) {
        revert LibErrors.InsufficientFunds(sender, quote.inputValue, msg.value);
      }

      // check balance
      uint nftsAvailable = getTotalNftsForSale(); 
      if (numItems > nftsAvailable) {
        revert LibErrors.InsufficientBalance(address(this), numItems, nftsAvailable);
      }

      // transfer from balance first
      uint balance = nft.balanceOf(address(this));
      if (balance > 0) {
        uint toTransfer = balance < numItems ? balance : numItems;
        nft.batchTransferNumTokens(address(this), sender, toTransfer);
        numItems -= toTransfer;
      }

      // mint remaining
      if (numItems > 0) {
        nft.batchMint(sender, status.lastMintId + 1, numItems);
        status.lastMintId += numItems;
      }

      // pay fee
      payable(feeReceiver).transfer(quote.fee);

      // return excess payment to caller
      if (quote.inputValue < msg.value) {
        payable(sender).transfer(msg.value - quote.inputValue);
      }

      // update status
      status.priceWei = quote.newSpotPrice;
    }
  }

  /**
   * @dev Get total available NFTs for sale.
   */
  function getTotalNftsForSale() public view returns (uint) {
    return nft.balanceOf(address(this)) + (curve.mintEndId - status.lastMintId);
  }

  /**
   * inputValue is the amount of wei the buyer will pay, including the fee.
   */
  function getBuyQuote(uint numItems) public view returns (BuyQuote memory quote, address feeReceiver) {
    uint feeBips;
    (feeReceiver, feeBips) = nft.getRoyaltyInfo();
    quote = getBuyInfo(status.priceWei, curve.delta, numItems, feeBips);
  }

  // ---------------------------------------------------------------
  // Selling
  // ---------------------------------------------------------------


  function sell(uint[] calldata tokenIds) external {
    address sender = payable(msg.sender);
    (SellQuote memory quote, address feeReceiver) = getSellQuote(tokenIds.length);

    if (quote.error == CurveQuoteError.NONE) {
      // check balance
      uint tokenBal = nft.balanceOf(sender);
      if (tokenIds.length > tokenBal) {
        revert LibErrors.InsufficientBalance(sender, tokenIds.length, tokenBal);
      }

      // check that pool has enough balance to pay
      uint totalToPay = quote.outputValue + quote.fee;
      if (totalToPay > address(this).balance) {
        revert LibErrors.InsufficientFunds(address(this), totalToPay, address(this).balance);
      }

      // for each token
      for (uint i = 0; i < tokenIds.length; i++) {
        uint id = tokenIds[i];
        
        // must be within supported range
        if (id < curve.mintStartId || id > curve.mintEndId) {
          revert LibErrors.TokenIdOutOfRange(sender, id);
        }
      }

      // transfer NFTs to pool
      nft.batchTransferTokenIds(sender, address(this), tokenIds);

      // pay caller
      payable(sender).transfer(quote.outputValue);

      // pay fee
      payable(feeReceiver).transfer(quote.fee);
    }
  }

  /**
   * outputValue is the amount of wei the seller will receive, excluding the fee.
   */
  function getSellQuote(uint numItems) public view returns (SellQuote memory quote, address feeReceiver) {
    uint feeBips;
    (feeReceiver, feeBips) = nft.getRoyaltyInfo();
    quote = getSellInfo(status.priceWei, curve.delta, numItems, feeBips);
  }
}
