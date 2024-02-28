// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { JigzawPool } from "src/JigzawPool.sol";
import { LibErrors } from "src/LibErrors.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract PoolBasic is PoolTestBase {
  function test_DefaultConfig() public {
    assertEq(address(p.nft()), address(nft));
    
    (PoolCurve memory c, PoolStatus memory s) = p.getCurveStatus();
    assertEq(c.mintStartId, 10);
    assertEq(c.mintEndId, 20);
    assertEq(c.startPriceWei, 1 gwei);
    assertEq(c.delta, 2 * 1e18);

    assertEq(s.lastMintId, 9);
    assertEq(s.priceWei, 1 gwei);
  }

  function test_MintPrice_Fuzz(uint128 price) public {
    vm.assume(price >= 1 gwei);

    p = new JigzawPool(JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 1,
        mintEndId: 1,
        startPriceWei: price,
        delta: 2 * 1e18
      })
    }));
  }

  function test_MintPrice_Bad() public {
    uint128 price = 1 gwei - 1;

    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidMintPrice.selector, price));
    p = new JigzawPool(JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 1,
        mintEndId: 1,
        startPriceWei: price,
        delta: 2 * 1e18
      })
    }));
  }

  function test_MintRange_Fuzz(uint start, uint end) public {
    vm.assume(start > 1);
    vm.assume(end >= start);

    p = new JigzawPool(JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: start,
        mintEndId: end,
        startPriceWei: 1 gwei,
        delta: 2 * 1e18
      })
    }));
  }

  function test_MintRange_Bad() public {
    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidMintStartId.selector, 0));
    p = new JigzawPool(JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 0,
        mintEndId: 1,
        startPriceWei: 1 gwei,
        delta: 2 * 1e18
      })
    }));

    vm.expectRevert(abi.encodeWithSelector(LibErrors.InvalidMintEndId.selector, 1));
    p = new JigzawPool(JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 2,
        mintEndId: 1,
        startPriceWei: 1 gwei,
        delta: 2 * 1e18
      })
    }));
  }
}
