// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { LotteryNFT } from "src/LotteryNFT.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";


abstract contract MintSwapPoolTestBase is TestBase01 {  
  JigzawNFT public jigzawNft;
  MintSwapPool public pool;
  LotteryNFT public lotteryNft;

  address payable jigzawNft_addr;
  address payable pool_addr;
  address payable lotteryNft_addr;

  function setUp() virtual public {
    jigzawNft = new JigzawNFT(_getDefaultJigzawNftConfig());
    jigzawNft_addr = payable(address(jigzawNft));

    pool = new MintSwapPool(_getDefaultPoolConfig());
    pool_addr = payable(address(pool));

    lotteryNft = new LotteryNFT(_getDefaultLotteryNftConfig(jigzawNft));
    lotteryNft_addr = payable(address(lotteryNft));
    
    vm.startPrank(owner1);
    jigzawNft.setPool(pool_addr);
    jigzawNft.setLotteryNFT(lotteryNft_addr);
    vm.stopPrank();
  }

  // Helper methods

  function _getDefaultPoolConfig() internal view returns (MintSwapPool.Config memory) {
    return MintSwapPool.Config({
      nft: jigzawNft_addr,
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
