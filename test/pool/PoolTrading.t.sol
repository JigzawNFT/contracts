// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { console2 as c } from "forge-std/Test.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { LibErrors } from "src/LibErrors.sol";
import { PoolCurve, PoolStatus, QuoteError, BuyQuote, SellQuote } from "src/Common.sol";

contract PoolTrading is PoolTestBase {

  // getTotalNftsForSale - initial

  function test_GetTotalNftsForSale_Initial() public {
    assertEq(p.getTotalNftsForSale(), 11);
  }

  // getBuyQuote - initial

  function test_GetBuyQuote_Initial_BuyOne() public {
    BuyQuote memory q = p.getBuyQuote(1);
    assertEq(uint(q.error), uint(QuoteError.NONE));
    assertEq(q.newSpotPrice, 2 gwei);

    uint inputValue = 2 gwei;

    uint fee = inputValue / 10;
    assertEq(q.fee, fee);
    assertEq(q.inputValue, inputValue + fee);
  }

  function test_GetBuyQuote_Initial_BuyAll() public {
    BuyQuote memory q = p.getBuyQuote(11);
    assertEq(uint(q.error), uint(QuoteError.NONE));
    assertEq(q.newSpotPrice, 2048 gwei /* 2^11 */);

    uint inputValue = 
      2 gwei +
      4 gwei +
      8 gwei +
      16 gwei +
      32 gwei +
      64 gwei +
      128 gwei +
      256 gwei +
      512 gwei +
      1024 gwei +
      2048 gwei; // 4094 gwei

    uint fee = inputValue / 10;
    assertEq(q.fee, fee, "fee");
    assertEq(q.inputValue, inputValue + fee, "total");
  }

  function test_GetBuyQuote_Initial_BuyTooMuch() public {
    BuyQuote memory q = p.getBuyQuote(12);
    assertEq(uint(q.error), uint(QuoteError.INSUFFICIENT_NFTS));
  }

  // buy - initial

  function test_Buy_Initial_BuyOne() public {
    BuyQuote memory q = p.getBuyQuote(1);

    wallet1.transfer(q.inputValue); // exact funds
    vm.prank(wallet1);
    p.buy{value: wallet1.balance}(1);

    // check NFTs minted
    assertEq(nft.totalSupply(), 1, "nft supply");
    assertEq(nft.tokenByIndex(0), 10, "token at index 0");

    // check caller funds
    assertEq(wallet1.balance, 0);
    // check caller nfts
    assertEq(nft.balanceOf(wallet1), 1);
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 0), 10, "token of owner at index 0");

    // check pool NFTs
    assertEq(p.getTotalNftsForSale(), 10);
    // check pool funds
    assertEq(address(p).balance, q.inputValue - q.fee);
    
    // check fee receiver funds
    assertEq(owner1.balance, q.fee);
  }

  function test_Buy_Initial_BuyAll() public {
    BuyQuote memory q = p.getBuyQuote(11);

    wallet1.transfer(1 ether);
    vm.prank(wallet1);
    p.buy{value: wallet1.balance}(11);

    // check NFTs minted
    assertEq(nft.totalSupply(), 11, "nft supply");
    assertEq(nft.tokenByIndex(0), 10, "token at index 0");
    assertEq(nft.tokenByIndex(1), 11, "token at index 1");
    assertEq(nft.tokenByIndex(10), 20, "token at index 10");

    // check caller funds
    assertEq(wallet1.balance, 1 ether - q.inputValue);
    // check caller nfts
    assertEq(nft.balanceOf(wallet1), 11);
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 0), 10, "token of owner at index 0");
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 1), 11, "token of owner at index 1");
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 10), 20, "token of owner at index 10");

    // check pool NFTs
    assertEq(p.getTotalNftsForSale(), 0);
    // check pool funds
    assertEq(address(p).balance, q.inputValue - q.fee);
    
    // check fee receiver funds
    assertEq(owner1.balance, q.fee);
  }


  function test_Buy_Initial_BuyOne_InsufficientFunds() public {
    BuyQuote memory q = p.getBuyQuote(1);

    wallet1.transfer(q.inputValue - 1);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InsufficientSenderFunds.selector, wallet1, q.inputValue, wallet1.balance));
    p.buy{value: wallet1.balance}(1);
  }

  function test_Buy_Initial_BuyOne_TooMuchFunds() public {
    BuyQuote memory q = p.getBuyQuote(1);

    wallet1.transfer(q.inputValue + 1);
    vm.prank(wallet1);
    p.buy{value: wallet1.balance}(1);

    // check caller funds to ensure extra got returned
    assertEq(wallet1.balance, 1);
  }

  function test_Buy_Initial_BuyTooMuch() public {
    wallet1.transfer(1 ether);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.BadQuote.selector, QuoteError.INSUFFICIENT_NFTS));
    p.buy{value: wallet1.balance}(12);
  }
}

