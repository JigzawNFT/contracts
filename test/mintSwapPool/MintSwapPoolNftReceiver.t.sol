// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { MintSwapPool } from "src/MintSwapPool.sol";
import { LibErrors } from "src/LibErrors.sol";
import { MintSwapPoolTestBase } from "./MintSwapPoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract MintSwapPoolNftReceiver is MintSwapPoolTestBase {
  function test_MintedNfts_AreAccepted_Fuzz(uint id) public {
    vm.prank(pool_addr);
    jigzawNft.mint(pool_addr, id, "", _computeMinterSig(
      abi.encodePacked(pool_addr, id, ""), 
      block.timestamp + 10 seconds
    ));

    assertEq(jigzawNft.ownerOf(id), pool_addr);
  }

  function test_TransferredNfts_AreAccepted_Fuzz(uint id) public {
    vm.startPrank(wallet1);

    jigzawNft.mint(wallet1, id, "", _computeMinterSig(
      abi.encodePacked(wallet1, uint256(id), ""), 
      block.timestamp + 10 seconds
    ));

    jigzawNft.safeTransferFrom(wallet1, pool_addr, id);  
    
    vm.stopPrank();

    assertEq(jigzawNft.ownerOf(id), pool_addr);
  }
}
