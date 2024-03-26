// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { LibErrors } from "src/LibErrors.sol";


contract JigzawNftLottery is JigzawNftTestBase {
  function setUp() public override {
    super.setUp();

    vm.startPrank(owner1);
    jigzawNft.setPool(pool1);    
    jigzawNft.setLotteryNFT(lotteryNft_addr);
    vm.stopPrank();
  }

  function test_DrawLottery_WhenNotOwner_Fails() public {
    uint[] memory winners = new uint[](0);

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, wallet1));
    jigzawNft.drawLottery(winners);

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    jigzawNft.drawLottery(winners);

    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    jigzawNft.drawLottery(winners);

    vm.prank(pool1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, pool1));
    jigzawNft.drawLottery(winners);
  }

  function test_DrawLottery_WhenNotYetReady_Fails() public {
    assertEq(jigzawNft.canDrawLottery(), false, "canDrawLottery");
    
    vm.prank(owner1);
    vm.expectRevert(LibErrors.LotteryCannotBeDrawnYet.selector);
    uint[] memory winners = new uint[](0);
    jigzawNft.drawLottery(winners);
  }

  function test_DrawLottery_WhenTileRevealThresholdReached_Succeeds() public {
    _mintAndRevealTiles();

    assertEq(jigzawNft.canDrawLottery(), true, "canDrawLottery");

    vm.prank(owner1);
    uint[] memory winners = new uint[](0);
    jigzawNft.drawLottery(winners);
  }

  function test_DrawLottery_WhenDeadlinePassed_Succeeds() public {
    vm.warp(block.timestamp + 11);

    assertEq(jigzawNft.canDrawLottery(), true, "canDrawLottery");

    vm.prank(owner1);
    uint[] memory winners = new uint[](0);
    jigzawNft.drawLottery(winners);
  }

  function test_DrawLottery_Again_Fails() public {
    _mintAndRevealTiles();

    uint[] memory winners = new uint[](0);

    vm.prank(owner1);
    jigzawNft.drawLottery(winners);

    assertEq(jigzawNft.canDrawLottery(), false, "canDrawLottery");

    vm.prank(owner1);
    vm.expectRevert(LibErrors.LotteryAlreadyDrawn.selector);
    jigzawNft.drawLottery(winners);
  }

  function test_DrawLottery_SetsUpLotteryPot() public {
    _mintAndRevealTiles();

    uint[] memory winners = new uint[](0);

    payable(jigzawNft_addr).transfer(0.0005 ether);
    // c.log("jigzawNft_addr balance", address(jigzawNft_addr).balance);

    vm.prank(owner1);
    jigzawNft.drawLottery(winners);

    JigzawNFT.Lottery memory lottery = jigzawNft.getLottery();
    assertEq(lottery.pot, 0.00025 ether, "lottery.pot");
  }

  function test_DrawLottery_UpdatesRoyaltyInfo() public {
    _mintAndRevealTiles();

    uint[] memory winners = new uint[](0);

    JigzawNFT.DevRoyalties memory devRoyalties = jigzawNft.getDevRoyalties();

    vm.prank(owner1);
    jigzawNft.drawLottery(winners);

    (address rr, uint rf) = jigzawNft.getRoyaltyInfo();
    assertEq(rr, devRoyalties.receiver, "royaltyReceiver");
    assertEq(rf, devRoyalties.feeBips, "royaltyFeeBips");
  }

  function test_DrawLottery_SavesWinners() public {
    _mintAndRevealTiles();

    uint[] memory winners = new uint[](3);
    winners[0] = 4;
    winners[1] = 5;
    winners[2] = 6;

    vm.prank(owner1);
    jigzawNft.drawLottery(winners);

    JigzawNFT.Lottery memory lottery = jigzawNft.getLottery();
    assertEq(lottery.winners.length, 3, "winners.length");
    assertEq(lottery.winners[0], 4, "winners[0]");
    assertEq(lottery.winners[1], 5, "winners[1]");
    assertEq(lottery.winners[2], 6, "winners[2]");
  }

  function test_DrawLottery_WithdrawsDevRoyalties() public {
    _drawLotteryWinners();
    assertEq(owner1.balance, 0.0009 ether);
  }

  function test_IsWinner_WhenNotYetDrawn() public {
    assertEq(jigzawNft.isLotteryWinner(1), false);
  }

  function test_IsWinner() public {
    _drawLotteryWinners();

    assertEq(jigzawNft.isLotteryWinner(1), false);
    assertEq(jigzawNft.isLotteryWinner(2), false);
    assertEq(jigzawNft.isLotteryWinner(3), false);
    assertEq(jigzawNft.isLotteryWinner(4), true);
    assertEq(jigzawNft.isLotteryWinner(5), true);
    assertEq(jigzawNft.isLotteryWinner(6), true);
    assertEq(jigzawNft.isLotteryWinner(7), false);
    assertEq(jigzawNft.isLotteryWinner(8), false);
    assertEq(jigzawNft.isLotteryWinner(9), false);
    assertEq(jigzawNft.isLotteryWinner(10), false);
  }

  function test_canClaimWinnings_WhenNotYetDrawn() public {
    assertEq(jigzawNft.canClaimLotteryWinnings(1), false);
  }

  function test_canClaimWinnings_WhenDrawnButNotWinningTicket() public {
    _drawLotteryWinners();

    assertEq(jigzawNft.canClaimLotteryWinnings(1), false);
  }

  function test_canClaimWinnings_WhenDrawn_AndWinningTicket() public {
    _drawLotteryWinners();

    assertEq(jigzawNft.canClaimLotteryWinnings(4), true);
  }

  function test_claimWinnings_WhenNotDrawn_Fails() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.LotteryCannotClaimWinnings.selector, uint(1)));
    jigzawNft.claimLotteryWinnings(1);
  }

  function test_claimWinnings_WhenDrawn_ButNotWinningTicket_Fails() public {
    _drawLotteryWinners();

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.LotteryCannotClaimWinnings.selector, uint(1)));
    jigzawNft.claimLotteryWinnings(1);
  }

  function test_claimWinnings_WhenDrawn_AndWinningTicket_Succeeds() public {
    _drawLotteryWinners();
    
    assertEq(jigzawNft_addr.balance, 0.0018 ether - 0.0009 ether /* dev royalties */);

    vm.prank(wallet1);
    jigzawNft.claimLotteryWinnings(4);

    // check status
    assertEq(jigzawNft.canClaimLotteryWinnings(4), false);
    assertEq(jigzawNft.lotteryWinningsClaimed(4), true);

    // check balances have been updated
    assertEq(wallet1.balance, 0.0003 ether);
    assertEq(jigzawNft_addr.balance, 0.0018 ether - 0.0009 ether - 0.0003 ether);
  }

  function test_claimWinnings_WhenDrawn_AndAnyoneCanClaimForWinningTicket() public {
    _drawLotteryWinners();
    
    assertEq(jigzawNft_addr.balance, 0.0018 ether - 0.0009 ether /* dev royalties */);

    vm.prank(wallet2); // not the ticket owner but still works
    jigzawNft.claimLotteryWinnings(4);

    // check status
    assertEq(jigzawNft.canClaimLotteryWinnings(4), false);
    assertEq(jigzawNft.lotteryWinningsClaimed(4), true);

    // check balances have been updated
    assertEq(wallet1.balance, 0.0003 ether);
    assertEq(jigzawNft_addr.balance, 0.0018 ether - 0.0009 ether - 0.0003 ether);
  }

  function test_claimWinnings_WhenDrawn_AndCannotClaimTwice() public {
    _drawLotteryWinners();
    
    vm.prank(wallet1);
    jigzawNft.claimLotteryWinnings(4);

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.LotteryCannotClaimWinnings.selector, 4));
    jigzawNft.claimLotteryWinnings(4);
  }

  // Helper methods

  function _mintAndRevealTiles() internal {
    vm.prank(pool1);
    jigzawNft.batchMint(wallet1, 1, 10);

    vm.startPrank(wallet1);

    for (uint i = 1; i <= 10; i++) {
      jigzawNft.reveal(i, "uri1", _computeRevealerSig(
        abi.encodePacked(wallet1, i, "uri1"),
        block.timestamp + 10 seconds
      ));
    }

    vm.stopPrank();
  }

  function _drawLotteryWinners() internal {
    _mintAndRevealTiles();

    /*
    See JigzawNftTestBase for this config...

    dev royalty (10% of trade value) = 0.00009 ether
    lottery pot (10% of trade value) = 0.00009 ether
    total fee = 20%

    total pot= 0.00018 ether
    dev pot = 0.00009 ether
    lottery pot = 0.00009 ether
    */
    payable(jigzawNft_addr).transfer(0.0018 ether);

    uint[] memory winners = new uint[](3);
    winners[0] = 4;
    winners[1] = 5;
    winners[2] = 6;

    vm.prank(owner1);
    jigzawNft.drawLottery(winners);
  }
}
