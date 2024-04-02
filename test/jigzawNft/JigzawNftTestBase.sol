// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";  
import { LotteryNFT } from "src/LotteryNFT.sol";
import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";

abstract contract JigzawNftTestBase is TestBase01 {  
  using Strings for uint256;

  uint pool1_key = 0x123456;
  address public pool1 = vm.addr(pool1_key);

  // Helper methods

  function _buildDefaultTokenUri(uint /*tokenId*/) internal view returns (string memory) {
    string memory json = string(
      abi.encodePacked(
        '{',
            '"name": "Unrevealed tile",',
            '"description": "An unrevealed Jigzaw tile - see https://jigzaw.xyz for more info.",',
            '"image": "', jigzawNft.defaultImage(), '"',
        '}'
      ) 
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  function testJigzawNftTestBase_ExcludeFromCoverage() public {}  
}

