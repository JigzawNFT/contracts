// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNFT } from "src/JigzawNFT.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";

contract JigzawNftBasic is JigzawNftTestBase {
  function test_DefaultConfig() public {
    assertEq(t.name(), "Jigzaw");
    assertEq(t.symbol(), "JIGZAW");
    assertEq(t.owner(), owner1);
    assertEq(t.minter(), minter1);
    assertEq(t.revealer(), revealer1);
    assertEq(t.pool(), pool1);
    assertEq(t.defaultImage(), "img");

    JigzawNFT.DevRoyalties memory devRoyalties = t.getDevRoyalties();
    assertEq(devRoyalties.feeBips, 1000);
    assertEq(devRoyalties.receiver, owner1);
    assertEq(devRoyalties.pot, 0);

    JigzawNFT.Lottery memory lottery = t.getLottery();
    assertEq(lottery.feeBips, 1000);
    assertEq(lottery.deadline, block.timestamp);
    assertEq(lottery.tileRevealThreshold, 10);
    assertEq(lottery.drawn, false);
    assertEq(lottery.pot, 0);
    assertEq(address(lottery.ticketNFT), address(l));

    assertEq(t.totalSupply(), 0);
    (address r1, uint r2) = t.royaltyInfo(0, 100);
    assertEq(r1, owner1);
    assertEq(r2, 10);

    (address rec, uint fee) = t.getRoyaltyInfo();
    assertEq(rec, owner1);
    assertEq(fee, 1000);
  }
}
