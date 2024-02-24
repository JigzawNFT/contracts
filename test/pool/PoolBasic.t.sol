// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { PoolTestBase } from "./PoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Structs.sol";

contract PoolBasic is PoolTestBase {
  function test_DefaultConfig() public {
    assertEq(address(p.nft()), address(nft));
    
    (PoolCurve memory c, PoolStatus memory s) = p.getCurveStatus();
    assertEq(c.mintStartId, 10);
    assertEq(c.mintEndId, 20);
    assertEq(c.startPriceWei, 100);
    assertEq(c.delta, 2 * 1e18);
    assertEq(s.lastMintId, 9);
    assertEq(s.priceWei, 100);
  }
}
