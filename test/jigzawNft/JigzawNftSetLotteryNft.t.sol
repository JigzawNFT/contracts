// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import {console2 as c} from "forge-std/Test.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Ownable } from "openzeppelin/access/Ownable.sol";
import { LibErrors } from "src/LibErrors.sol";


contract JigzawNftSetLotteryNft is JigzawNftTestBase {
  function test_SetLotteryNft_WhenOwner_Succeeds() public {
    vm.prank(owner1);
    jigzawNft.setLotteryNFT(lotteryNft_addr);
    assertEq(address(jigzawNft.getLottery().nft), address(lotteryNft_addr));
  }

  function test_SetLotteryNft_WhenNotOwner_Fails() public {
    vm.prank(revealer1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, revealer1));
    jigzawNft.setLotteryNFT(address(0x789));

    vm.prank(minter1);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, minter1));
    jigzawNft.setLotteryNFT(address(0x789));

    address random = address(0x8876);
    vm.prank(random);
    vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, random));
    jigzawNft.setLotteryNFT(address(0x789));
  }

  function test_SetLotteryNft_WhenAlreadySet_Fails() public {
    vm.prank(owner1);
    jigzawNft.setLotteryNFT(lotteryNft_addr);

    vm.prank(owner1);
    vm.expectRevert(LibErrors.LotteryNFTAlreadySet.selector);
    jigzawNft.setLotteryNFT(lotteryNft_addr);
  }

  function test_SetLotteryNft_WhenInvalidInterface_Fails() public {
    vm.prank(owner1);
    vm.expectRevert();
    jigzawNft.setLotteryNFT(vm.addr(0x123));

    vm.prank(owner1);
    vm.expectRevert(LibErrors.LotteryNFTInvalid.selector);
    jigzawNft.setLotteryNFT(jigzawNft_addr);
  }
}
