// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { console2 as c } from "forge-std/Test.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { PoolCurve, PoolStatus, QuoteError, BuyQuote, SellQuote } from "src/Common.sol";

contract PoolBuy is PoolTestBase {
  function test_GetBuyInfo_Initial_BuyOne() public {
    (BuyQuote memory q, ) = p.getBuyQuote(1);
    assertEq(uint(q.error), uint(QuoteError.NONE));
    assertEq(q.newSpotPrice, 2 gwei);

    uint intermediateInputValue = 2 gwei;

    uint fee = intermediateInputValue / 10;
    assertEq(q.fee, fee);
    assertEq(q.inputValue, q.newSpotPrice + fee);
  }

  function test_GetBuyInfo_Initial_BuyAll() public {
    (BuyQuote memory q, ) = p.getBuyQuote(11);
    assertEq(uint(q.error), uint(QuoteError.NONE));
    assertEq(q.newSpotPrice, 2048 gwei /* 2^11 */);

    uint intermediateInputValue = 2 gwei;

    uint fee = intermediateInputValue / 10;
    assertEq(q.fee, fee);
    assertEq(q.inputValue, q.newSpotPrice + fee);
  }
}

