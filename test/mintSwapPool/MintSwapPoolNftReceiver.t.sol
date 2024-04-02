// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { MintSwapPool } from "src/MintSwapPool.sol";
import { LibErrors } from "src/LibErrors.sol";
import { MintSwapPoolTestBase } from "./MintSwapPoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract MintSwapPoolNftReceiver is MintSwapPoolTestBase {
  function test_MintedNfts_AreAccepted_Fuzz(uint id) public {
    vm.prank(pool_addr);
    _jigzawNft_mint(pool_addr, id, "", 0);

    assertEq(jigzawNft.ownerOf(id), pool_addr);
  }

  function test_TransferredNfts_AreAccepted_Fuzz(uint id) public {
    vm.startPrank(wallet1);

    _jigzawNft_mint(wallet1, id, "", 0);
    jigzawNft.safeTransferFrom(wallet1, pool_addr, id);  
    
    vm.stopPrank();

    assertEq(jigzawNft.ownerOf(id), pool_addr);
  }
}
