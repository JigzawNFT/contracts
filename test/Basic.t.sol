// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { TestBaseTop } from "./utils/TestBaseTop.sol";

contract Basic is TestBaseTop {
  function test_DefaultConfig() public {
    assertEq(t.name(), "Jigzaw");
    assertEq(t.symbol(), "JIGZAW");
    // owner
    assertEq(t.owner(), owner1);
    // minter
    assertEq(t.minter(), minter1);
    // revealer
    assertEq(t.revealer(), revealer1);
    // enumerable
    assertEq(t.totalSupply(), 0);
    // royalty (10%)
    (address r1, uint r2) = t.royaltyInfo(0, 100);
    assertEq(r1, owner1);
    assertEq(r2, 10);
  }
}
