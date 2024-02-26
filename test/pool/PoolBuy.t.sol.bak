// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { console2 as c } from "forge-std/Test.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract PoolBuy is PoolTestBase {
  function test_GetBuyInfo_InitialMint_AtCurrentPrice() public {
    (uint n, uint fa) = p.getBuyInfo(100);
    assertEq(n, 0);
    assertEq(fa, 0);
  }

  function test_GetBuyInfo_InitialMint_AtCurrentPricePlusDelta() public {
    (uint n, uint fa) = p.getBuyInfo(100*2);
    assertEq(n, 1);
    assertEq(fa, 100*2);
  }

  function test_GetBuyInfo_InitialMint_AtCurrentPricePlusDeltaTimesTwo() public {
    uint amt = 100*(2+4);
    (uint n, uint fa) = p.getBuyInfo(amt);
    assertEq(n, 2);
    assertEq(fa, amt);
  }

  function test_GetBuyInfo_InitialMint_BuyWhole() public {
    uint amt = 100*(2+4+8+16+32+64+128+256+512+1024+2048); // ids 10 to 20 inclusive equals 11 items
    (uint n, uint fa) = p.getBuyInfo(amt);
    assertEq(n, 11);
    assertEq(fa, amt);
  }

  function test_GetBuyInfo_InitialMint_IfExcessAmount() public {
    uint amt = 100*2+50; // 50 extra
    (uint n, uint fa) = p.getBuyInfo(amt);
    assertEq(n, 1);
    assertEq(fa, 100*2);
  }
}

