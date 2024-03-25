// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { LotteryNftTestBase } from "./LotteryNftTestBase.sol";

contract LotteryNftBasic is LotteryNftTestBase {
  function test_DefaultConfig() public {
    assertEq(lotteryNft.name(), "Jigzaw Lottery", "name");
    assertEq(lotteryNft.symbol(), "JIGZAW_LOTTERY", "symbol");
    assertEq(lotteryNft.minter(), minter1, "minter");
    assertEq(lotteryNft.defaultImage(), "img", "defaultImg");

    assertEq(lotteryNft.totalSupply(), 0, "totalSupply");
    (address r1, uint r2) = lotteryNft.royaltyInfo(0, 100);
    assertEq(r1, owner1, "royaltyInfo.receiver");
    assertEq(r2, 10, "royaltyInfo.fee");
  }
}
