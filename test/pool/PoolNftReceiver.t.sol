// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { MintSwapNftPool } from "src/MintSwapNftPool.sol";
import { LibErrors } from "src/LibErrors.sol";
import { PoolTestBase } from "./PoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract PoolNftReceiver is PoolTestBase {
  function test_MintedNfts_WithinCurveRange_AreAccepted() public {
    for (uint id = 10; id <= 20; id++) {
      nft.mint(p_addr, id, "", _computeMinterSig(
        abi.encodePacked(p_addr, id, ""), 
        block.timestamp + 10 seconds
      ));

      assertEq(nft.ownerOf(id), p_addr);
    }
  }

  function test_MintedNfts_OutOfCurveRange_AreRejected_Fuzz(uint id) public {
    vm.assume(id < 10 || id > 20);

    vm.expectRevert(abi.encodeWithSelector(LibErrors.TokenIdOutOfRange.selector, address(this), id));
    nft.mint(p_addr, id, "", _computeMinterSig(
      abi.encodePacked(p_addr, uint256(id), ""), 
      block.timestamp + 10 seconds
    ));
  }

  function test_TransferredNfts_WithinCurveRange_AreAccepted() public {
    for (uint id = 10; id <= 20; id++) {
      nft.mint(wallet1, id, "", _computeMinterSig(
        abi.encodePacked(wallet1, id, ""), 
        block.timestamp + 10 seconds
      ));

      vm.prank(wallet1);
      nft.safeTransferFrom(wallet1, p_addr, id);  

      assertEq(nft.ownerOf(id), p_addr);
    }
  }

  function test_TransferredNfts_OutOfCurveRange_AreRejected_Fuzz(uint id) public {
    vm.assume(id < 10 || id > 20);

    nft.mint(wallet1, id, "", _computeMinterSig(
      abi.encodePacked(wallet1, uint256(id), ""), 
      block.timestamp + 10 seconds
    ));

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.TokenIdOutOfRange.selector, wallet1, id));
    nft.safeTransferFrom(wallet1, p_addr, id);  
  }
}
