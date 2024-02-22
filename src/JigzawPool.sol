// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IMintable } from "./IMintable.sol";
import { PoolCurve, PoolStatus } from "./Structs.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";

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
contract JigzawPool is Ownable {
  IMintable public nft;
  PoolCurve[] public curves;
  PoolStatus[] public statuses;

  // Constructor

  /**
   * @dev Configuration parameters.
   */
  struct Config {
    /** JigzawNFT contractx. */
    address nft;
    /** Owner. */
    address owner;
    /** Price curves (and thus liquidity pools) */
    PoolCurve[] curves;
  }

  constructor(Config memory _config)
    Ownable(_config.owner)
  {
    nft = IMintable(_config.nft);

    for (uint i = 0; i < _config.curves.length; i++) {      
      curves.push(PoolCurve({
        mintStartId: _config.curves[i].mintStartId,
        mintEndId: _config.curves[i].mintEndId,
        startPriceWei: _config.curves[i].startPriceWei,
        expDeltaBips: _config.curves[i].expDeltaBips
      }));

      statuses.push(PoolStatus({
        lastTokenMinted: 0,
        priceWei: _config.curves[i].startPriceWei
      }));
    }
  }

  // Buy

  function buy() public payable {
    // Buy
  }

  // Sell

  function sell() public {
    // Buy
  }
}
