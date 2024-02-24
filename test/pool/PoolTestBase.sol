// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { IERC165 } from "openzeppelin/interfaces/IERC165.sol";
import { ERC721 } from "openzeppelin/token/ERC721/ERC721.sol";
import { ERC721Enumerable } from "openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";
import { IMintable } from "src/IMintable.sol";
import { JigzawPool } from "src/JigzawPool.sol";
import { PoolCurve } from "src/Structs.sol";


contract TestNFT is ERC721, ERC721Enumerable, IMintable {
  constructor() ERC721("Test","TEST") {}

  // Functions - necessary overrides

  function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
    return ERC721Enumerable._update(to, tokenId, auth);
  }

  function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
    ERC721Enumerable._increaseBalance(account, amount);
  }

  function supportsInterface(bytes4 /*interfaceId*/) public pure override(ERC721, ERC721Enumerable, IERC165) returns (bool) {
    return true;
  }

  // IMintable

  function mint(address _to, uint _startId, uint _count) external {
    for (uint i = _startId; i < _startId + _count; i++) {
      _safeMint(_to, i);
    }
  }
}

abstract contract PoolTestBase is TestBase01 {  
  TestNFT nft = new TestNFT();

  JigzawPool public p;

  function setUp() virtual public {
    p = new JigzawPool(_getDefaultConfig());
  }

  // Helper methods

  function _getDefaultConfig() internal view returns (JigzawPool.Config memory) {
    return JigzawPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 10,
        mintEndId: 20,
        startPriceWei: 100,
        delta: 2 * 1e18
      })
    });
  }  

  function testPoolTestBase_ExcludeFromCoverage() public {}  
}
