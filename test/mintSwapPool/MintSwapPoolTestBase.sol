// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { LotteryNFT } from "src/LotteryNFT.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";


abstract contract MintSwapPoolTestBase is TestBase01 {  
  JigzawNFT public nft;
  MintSwapPool public p;
  LotteryNFT public l;

  address nft_addr;
  address p_addr;
  address l_addr;

  function setUp() virtual public {
    nft = new JigzawNFT(_getDefaultJigzawNftConfig());
    nft_addr = address(nft);

    p = new MintSwapPool(_getDefaultPoolConfig());
    p_addr = address(p);

    l = new LotteryNFT(_getDefaultLotteryNftConfig(nft));
    l_addr = address(l);
    
    vm.startPrank(owner1);
    nft.setPool(address(p));
    nft.setLotteryTicketNFT(address(l));
    vm.stopPrank();
  }

  // Helper methods

  function _getDefaultPoolConfig() internal view returns (MintSwapPool.Config memory) {
    return MintSwapPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 10,
        mintEndId: 20,
        startPriceWei: 1 gwei,
        delta: 2 * 1e18
      })
    });
  }  

  function testPoolTestBase_ExcludeFromCoverage() public {}  
}
