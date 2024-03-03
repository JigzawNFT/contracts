// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { PoolCurve, PoolStatus } from "src/Common.sol";


abstract contract PoolTestBase is TestBase01 {  
  uint owner1_key = 0x123;
  address public owner1 = vm.addr(owner1_key);

  uint minter1_key = 0x1234;
  address public minter1 = vm.addr(minter1_key);

  uint revealer1_key = 0x12345;
  address public revealer1 = vm.addr(revealer1_key);

  address payable wallet1 = payable(address(0x1234567890));
  address payable wallet2 = payable(address(0x1234567890123));

  JigzawNFT public nft;
  MintSwapPool public p;

  address nft_addr;
  address p_addr;

  function setUp() virtual public {
    nft = new JigzawNFT(_getDefaultNftConfig());
    nft_addr = address(nft);

    p = new MintSwapPool(_getDefaultPoolConfig());
    p_addr = address(p);
    
    vm.prank(owner1);
    nft.setPool(address(p));
  }

  // Helper methods

  function _computeMinterSig(bytes memory _data, uint _deadline) internal view returns (Auth.Signature memory) {
    return _computeSig(minter1_key, _data, _deadline);
  }

  function _getDefaultNftConfig() internal view returns (JigzawNFT.Config memory) {
    return JigzawNFT.Config({
      owner: owner1,
      minter: minter1,
      revealer: revealer1,
      pool: address(0),
      royaltyFeeBips: 1000, /* 1000 bips = 10% fee */
      defaultImage: "img"
    });
  }

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
