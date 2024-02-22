// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { TestBaseTop } from "./utils/TestBaseTop.sol";

contract Basic is TestBaseTop {
  function test_DefaultConfig() public {
    assertEq(t.name(), "Jigzaw");
    assertEq(t.symbol(), "JIGZAW");
    assertEq(t.owner(), owner1);
    assertEq(t.minter(), minter1);
    assertEq(t.revealer(), revealer1);
    assertEq(t.pool(), pool1);
    assertEq(t.totalSupply(), 0);
    (address r1, uint r2) = t.royaltyInfo(0, 100);
    assertEq(r1, owner1);
    assertEq(r2, 10);
  }
}
