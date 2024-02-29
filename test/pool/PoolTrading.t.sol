// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { console2 as c } from "forge-std/Test.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { LibErrors } from "src/LibErrors.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";
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
    assertEq(nft.balanceOf(p_addr), 0);
    assertEq(p.getTotalNftsForSale(), 10);
    // check pool funds
    assertEq(p_addr.balance, q.inputValue - q.fee);
    
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
    assertEq(nft.balanceOf(p_addr), 0);
    assertEq(p.getTotalNftsForSale(), 0);
    // check pool funds
    assertEq(p_addr.balance, q.inputValue - q.fee);
    
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
    vm.expectRevert(abi.encodeWithSelector(LibErrors.BadQuote.selector, wallet1, QuoteError.INSUFFICIENT_NFTS));
    p.buy{value: wallet1.balance}(12);
  }

  // getSellQuote

  function test_GetSellQuote_SellOne() public {
    _buySomeNfts(1, 2 gwei);

    SellQuote memory q = p.getSellQuote(1);
    assertEq(uint(q.error), uint(QuoteError.NONE), "error code");
    assertEq(q.newSpotPrice, 1 gwei, "new spot price");

    uint outputValue = 2 gwei;

    uint fee = outputValue / 10;
    assertEq(q.fee, fee, "fee");
    assertEq(q.outputValue, outputValue - fee, "output value");
  }

  function test_GetSellQuote_SellAll() public {
    _buySomeNfts(11, 2048 gwei);

    SellQuote memory q = p.getSellQuote(11);
    assertEq(uint(q.error), uint(QuoteError.NONE), "error code");
    assertEq(q.newSpotPrice, 1 gwei, "new spot price");

    uint outputValue = 
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

    uint fee = outputValue / 10;
    assertEq(q.fee, fee, "fee");
    assertEq(q.outputValue, outputValue - fee, "output value");
  }

  function test_GetSellQuote_SellTooMuch() public {
    _buySomeNfts(1, 2 gwei);

    SellQuote memory q = p.getSellQuote(2);
    assertEq(uint(q.error), uint(QuoteError.INSUFFICIENT_FUNDS), "error code");
  }

  // sell

  function test_Sell_SellOne() public {
    _buySomeNfts(1, 2 gwei);

    SellQuote memory q = p.getSellQuote(1);

    uint[] memory ids = new uint[](1);
    ids[0] = 10;

    vm.prank(wallet1);
    p.sell(ids);

    // check caller funds
    assertEq(wallet1.balance, q.outputValue, "caller funds");
    // check caller nfts
    assertEq(nft.balanceOf(wallet1), 0, "caller nfts");
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 0), 0, "token of owner at index 0");

    // check pool NFTs
    assertEq(p.getTotalNftsForSale(), 11, "pool nfts for sale");
    assertEq(nft.balanceOf(p_addr), 1, "pool nft balance");
    assertEq(nft.tokenOfOwnerByIndex(p_addr, 0), 10, "token of pool owner at index 0");
    // check pool funds
    assertEq(p_addr.balance, 0, "pool funds");
    
    // check fee receiver funds
    assertEq(owner1.balance, q.fee, "received fee");
  }

  function test_Sell_SellAll() public {
    _buySomeNfts(11, 2048 gwei);

    SellQuote memory q = p.getSellQuote(11);

    uint[] memory ids = _getTokenIdArray(11, 10);
    vm.prank(wallet1);
    p.sell(ids);

    // check caller funds
    assertEq(wallet1.balance, q.outputValue, "caller funds");
    // check caller nfts
    assertEq(nft.balanceOf(wallet1), 0, "caller nfts");
    assertEq(nft.tokenOfOwnerByIndex(wallet1, 0), 0, "token of owner at index 0");

    // check pool NFTs
    assertEq(p.getTotalNftsForSale(), 11, "pool nfts for sale");
    assertEq(nft.balanceOf(p_addr), 11, "pool nft balance");
    assertEq(nft.tokenOfOwnerByIndex(p_addr, 0), 10, "token of pool owner at index 0");
    assertEq(nft.tokenOfOwnerByIndex(p_addr, 1), 11, "token of pool owner at index 1");
    assertEq(nft.tokenOfOwnerByIndex(p_addr, 10), 20, "token of pool owner at index 10");
    // check pool funds
    assertEq(p_addr.balance, 0, "pool funds");
    
    // check fee receiver funds
    assertEq(owner1.balance, q.fee, "received fee");
  }

  function test_Sell_InsufficientNfts() public {
    _buySomeNfts(2, 4 gwei);

    // get rid of all but 1
    vm.prank(wallet1);
    uint[] memory ids = _getTokenIdArray(1, 10);
    nft.batchTransferIds(wallet1, wallet2, ids);

    // try to sell 2
    ids = _getTokenIdArray(2, 10);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InsufficientSenderNfts.selector, wallet1, 2, 1));
    p.sell(ids);
  }

  function test_Sell_TooManyNfts() public {
    _buySomeNfts(2, 4 gwei);

    // try to sell 2
    uint[] memory ids = _getTokenIdArray(3, 10);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.BadQuote.selector, wallet1, QuoteError.INSUFFICIENT_FUNDS));
    p.sell(ids);
  }

  function test_Sell_OutOfRangeIds() public {
    // will buy with ids: 10, 11
    _buySomeNfts(2, 4 gwei);

    // try to sell with ids: 20, 21
    uint[] memory ids = _getTokenIdArray(2, 20);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.TokenIdOutOfRange.selector, wallet1, 21));
    p.sell(ids);
  }

  function test_Sell_SenderIsNotNftOwner() public {
    // will buy ids: 10, 11
    _buySomeNfts(2, 4 gwei);

    // send #10 to wallet2
    vm.prank(wallet1);
    nft.safeTransferFrom(wallet1, wallet2, 10);

    // at this point, wallet1 has #11, wallet2 has #10

    uint[] memory ids = _getTokenIdArray(1, 10);
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOwner.selector, wallet1, 10));
    p.sell(ids);
  }

  // helper methods

  function _buySomeNfts(uint numItems, uint expectedNewSpotPrice) private {
    BuyQuote memory q = p.getBuyQuote(numItems);

    wallet1.transfer(q.inputValue);

    vm.prank(wallet1);
    p.buy{value: wallet1.balance}(numItems);

    (, PoolStatus memory s) = p.getCurveStatus();
    assertEq(s.priceWei, expectedNewSpotPrice, "expected spot price");

    // nullify received fees (to make test assertions easier later on)
    vm.prank(owner1);
    payable(address(0)).transfer(owner1.balance);
  }

  function _getTokenIdArray(uint count, uint startId) private pure returns (uint[] memory) {
    uint[] memory ids = new uint[](count);
    for (uint i = 0; i < count; i++) {
      ids[i] = startId + i;
    }
    return ids;
  }
}

