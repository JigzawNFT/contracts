// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { MintSwapPool } from "src/MintSwapPool.sol";
import { LibErrors } from "src/LibErrors.sol";
import { MintSwapPoolTestBase } from "./MintSwapPoolTestBase.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";

contract MintSwapPoolNftReceiver is MintSwapPoolTestBase {
  function test_MintedNfts_AreAccepted_Fuzz(uint id) public {
    vm.prank(p_addr);
    nft.mint(id, "", _computeMinterSig(
      abi.encodePacked(p_addr, id, ""), 
      block.timestamp + 10 seconds
    ));

    assertEq(nft.ownerOf(id), p_addr);
  }

  function test_TransferredNfts_AreAccepted_Fuzz(uint id) public {
    vm.startPrank(wallet1);

    nft.mint(id, "", _computeMinterSig(
      abi.encodePacked(wallet1, uint256(id), ""), 
      block.timestamp + 10 seconds
    ));

    nft.safeTransferFrom(wallet1, p_addr, id);  
    
    vm.stopPrank();

    assertEq(nft.ownerOf(id), p_addr);
  }
}
