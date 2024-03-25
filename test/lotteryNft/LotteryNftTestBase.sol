// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";  
import { LotteryNFT } from "src/LotteryNFT.sol";
import { ERC721, IERC721TokenReceiver } from "src/ERC721.sol";
import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";

abstract contract LotteryNftTestBase is TestBase01 {  
  using Strings for uint256;

  LotteryNFT public lotteryNft;
  address lotteryNft_addr;

  address payable jigzawNft_addr = payable(vm.addr(0x123456));

  function setUp() virtual public {
    lotteryNft = new LotteryNFT(_getDefaultLotteryNftConfig(JigzawNFT(jigzawNft_addr)));
    lotteryNft_addr = address(lotteryNft);
  }

  // Helper methods

  function _buildDefaultTokenUri(uint /*tokenId*/) internal view returns (string memory) {
    string memory json = string(
      abi.encodePacked(
        '{',
            '"name": "Lottery ticket",',
            '"description": "A lottery ticket for the Jigzaw NFT collection - see https://jigzaw.xyz for more info.",',
            '"image": "', lotteryNft.defaultImage(), '"',
        '}'
      ) 
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  function testJigzawNftTestBase_ExcludeFromCoverage() public {}  
}


