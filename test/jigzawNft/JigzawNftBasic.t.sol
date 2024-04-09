// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Ownable } from "openzeppelin/access/Ownable.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";

contract JigzawNftBasic is JigzawNftTestBase {
  function test_DefaultConfig() public {
    assertEq(jigzawNft.name(), "Jigzaw", "name");
    assertEq(jigzawNft.symbol(), "JIGZAW", "symbol");
    assertEq(jigzawNft.owner(), owner1, "owner");
    assertEq(jigzawNft.minter(), minter1, "minter");
    assertEq(jigzawNft.pool(), address(0), "pool");
    assertEq(jigzawNft.defaultImage(), "img", "defaultImg");

    JigzawNFT.DevRoyalties memory devRoyalties = jigzawNft.getDevRoyalties();
    assertEq(devRoyalties.feeBips, 1000, "devRoyalties.feeBips");
    assertEq(devRoyalties.receiver, owner1, "devRoyalties.receiver");

    JigzawNFT.Lottery memory lottery = jigzawNft.getLottery();
    assertEq(lottery.feeBips, 1000, "lottery.feeBips");
    assertEq(lottery.deadline, block.timestamp + 10, "lottery.deadline");
    assertEq(lottery.tileRevealThreshold, 10, "lottery.tileRevealThreshold");
    assertEq(lottery.drawn, false, "lottery.drawn");
    assertEq(lottery.drawnPot, 0, "lottery.drawnPot");
    assertEq(lottery.numWinningTickets, 0, "lottery.numWinningTickets");
    assertEq(address(lottery.nft), address(0), "lottery.ticketNFT");

    assertEq(jigzawNft.getLotteryPot(), 0, "getLotteryPotSoFar");

    assertEq(jigzawNft.totalSupply(), 0, "totalSupply");
    (address r1, uint r2) = jigzawNft.royaltyInfo(0, 100);
    assertEq(r1, jigzawNft_addr, "royaltyInfo.receiver");
    assertEq(r2, 20, "royaltyInfo.fee");

    (address rec, uint fee) = jigzawNft.getRoyaltyInfo();
    assertEq(rec, jigzawNft_addr, "getRoyaltyInfo.receiver");
    assertEq(fee, 2000, "getRoyaltyInfo.fee");
  }

  function test_ClaimGasRefunds_WhenOwner() public {
    vm.prank(owner1);
    jigzawNft.claimGasRefund();
  }

  function test_ClaimGasRefunds_WhenNotOwner() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, wallet1));
    jigzawNft.claimGasRefund();
  }
}
