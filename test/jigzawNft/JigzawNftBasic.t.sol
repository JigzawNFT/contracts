// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { JigzawNFT } from "src/JigzawNFT.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";

contract JigzawNftBasic is JigzawNftTestBase {
  function test_DefaultConfig() public {
    assertEq(t.name(), "Jigzaw", "name");
    assertEq(t.symbol(), "JIGZAW", "symbol");
    assertEq(t.owner(), owner1, "owner");
    assertEq(t.minter(), minter1, "minter");
    assertEq(t.revealer(), revealer1, "revealer");
    assertEq(t.pool(), address(0), "pool");
    assertEq(t.defaultImage(), "img", "defaultImg");

    JigzawNFT.DevRoyalties memory devRoyalties = t.getDevRoyalties();
    assertEq(devRoyalties.feeBips, 1000, "devRoyalties.feeBips");
    assertEq(devRoyalties.receiver, owner1, "devRoyalties.receiver");
    assertEq(devRoyalties.pot, 0, "devRoyalties.pot");

    JigzawNFT.Lottery memory lottery = t.getLottery();
    assertEq(lottery.feeBips, 1000, "lottery.feeBips");
    assertEq(lottery.deadline, block.timestamp, "lottery.deadline");
    assertEq(lottery.tileRevealThreshold, 10, "lottery.tileRevealThreshold");
    assertEq(lottery.drawn, false, "lottery.drawn");
    assertEq(lottery.pot, 0, "lottery.pot");
    assertEq(address(lottery.ticketNFT), address(0), "lottery.ticketNFT");

    assertEq(t.totalSupply(), 0, "totalSupply");
    (address r1, uint r2) = t.royaltyInfo(0, 100);
    assertEq(r1, address(t), "royaltyInfo.receiver");
    assertEq(r2, 20, "royaltyInfo.fee");

    (address rec, uint fee) = t.getRoyaltyInfo();
    assertEq(rec, address(t), "getRoyaltyInfo.receiver");
    assertEq(fee, 2000, "getRoyaltyInfo.fee");
  }
}
