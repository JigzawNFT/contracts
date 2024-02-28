// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IPoolNFT } from "./IPoolNFT.sol";
import { LibErrors } from "./LibErrors.sol";
import { PoolCurve, PoolStatus, QuoteError } from "./Common.sol";
import { ExponentialCurve } from "./ExponentialCurve.sol";
import { IERC721TokenReceiver } from "./ERC721.sol";

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
contract JigzawPool is IERC721TokenReceiver, ExponentialCurve {
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
    if (!validateSpotPrice(_config.curve.startPriceWei)) {
      revert LibErrors.InvalidStartPrice(_config.curve.startPriceWei);
    }

    if (_config.curve.mintStartId < 1) {
      revert LibErrors.InvalidMintStartId(_config.curve.mintStartId);
    }

    if (_config.curve.mintEndId < _config.curve.mintStartId) {
      revert LibErrors.InvalidMintEndId(_config.curve.mintEndId);
    }

    nft = IPoolNFT(_config.nft);
    
    curve = _config.curve;
    
    status = PoolStatus({
      lastMintId: _config.curve.mintStartId - 1,
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

    if (quote.error == QuoteError.NONE) {
      // check sender funds
      if (quote.inputValue > msg.value) {
        revert LibErrors.InsufficientSenderFunds(sender, quote.inputValue, msg.value);
      }

      // transfer from balance first
      uint balance = nft.balanceOf(address(this));
      if (balance > 0) {
        uint toTransfer = balance < numItems ? balance : numItems;
        nft.batchTransferRange(address(this), sender, toTransfer);
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
    
    // check NFTs available
    uint nftsAvailable = getTotalNftsForSale(); 
    if (numItems > nftsAvailable) {
      quote.error = QuoteError.INSUFFICIENT_NFTS;
    }
  }

  // ---------------------------------------------------------------
  // Selling
  // ---------------------------------------------------------------


  function sell(uint[] calldata tokenIds) external {
    address sender = payable(msg.sender);
    (SellQuote memory quote, address feeReceiver) = getSellQuote(tokenIds.length);

    if (quote.error == QuoteError.NONE) {
      // check balance
      uint tokenBal = nft.balanceOf(sender);
      if (tokenIds.length > tokenBal) {
        revert LibErrors.InsufficientSenderNfts(sender, tokenIds.length, tokenBal);
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
      nft.batchTransferIds(sender, address(this), tokenIds);

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

    // check that pool has enough balance to pay
    uint totalToPay = quote.outputValue + quote.fee;
    if (totalToPay > address(this).balance) {
      quote.error = QuoteError.INSUFFICIENT_FUNDS;
    }
  }

  // ---------------------------------------------------------------
  // IERC721TokenReceiver
  // ---------------------------------------------------------------

  function onERC721Received(
    address operator,
    address /*from*/,
    uint256 tokenId,
    bytes calldata /*data*/
  ) public view override returns (bytes4) {
    // check that the token id is within curve range
    if (tokenId < curve.mintStartId || tokenId > curve.mintEndId) {
      revert LibErrors.TokenIdOutOfRange(operator, tokenId);
    } else {
      return IERC721TokenReceiver.onERC721Received.selector;
    }
  }
}
