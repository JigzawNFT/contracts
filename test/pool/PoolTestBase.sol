// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { TestBase01 } from "test/utils/TestBase01.sol";
import { JigzawPool } from "src/JigzawPool.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";


abstract contract PoolTestBase is TestBase01 {  
  uint owner1_key = 0x123;
  address public owner1 = vm.addr(owner1_key);

  uint minter1_key = 0x1234;
  address public minter1 = vm.addr(minter1_key);

  uint revealer1_key = 0x12345;
  address public revealer1 = vm.addr(revealer1_key);


  JigzawNFT public nft;
  JigzawPool public p;

  function setUp() virtual public {
    nft = new JigzawNFT(_getDefaultNftConfig());
    p = new JigzawPool(_getDefaultPoolConfig());
    
    vm.prank(owner1);
    nft.setPool(address(p));
  }

  // Helper methods

  function _getDefaultNftConfig() internal view returns (JigzawNFT.Config memory) {
    return JigzawNFT.Config({
      owner: owner1,
      minter: minter1,
      revealer: revealer1,
      pool: address(0),
      royaltyFeeBips: 1000, /* 1000 bips = 10% */
      defaultImage: "img"
    });
  }

  function _getDefaultPoolConfig() internal view returns (JigzawPool.Config memory) {
    return JigzawPool.Config({
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
