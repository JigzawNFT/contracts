// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { TestBase01 } from "./TestBase01.sol";
import { JigzawNFT } from "../../src/JigzawNFT.sol";  
import { Config, Signature } from "../../src/Structs.sol";

abstract contract TestBaseTop is TestBase01 {  
  using Strings for uint256;

  uint owner1_key = 0x123;
  address public owner1 = vm.addr(owner1_key);

  uint minter1_key = 0x1234;
  address public minter1 = vm.addr(minter1_key);

  uint revealer1_key = 0x12345;
  address public revealer1 = vm.addr(revealer1_key);

  JigzawNFT public t;

  function setUp() virtual public {
    t = new JigzawNFT(_getDefaultParams());
  }

  // Helper methods

  function _computeMinterSig(bytes memory _data, uint _deadline) internal view returns (Signature memory) {
    return _computeSig(minter1_key, _data, _deadline);
  }

  function _computeRevealerSig(bytes memory _data, uint _deadline) internal view returns (Signature memory) {
    return _computeSig(revealer1_key, _data, _deadline);
  }

  function _computeOwnerSig(bytes memory _data, uint _deadline) internal view returns (Signature memory) {
    return _computeSig(owner1_key, _data, _deadline);
  }

  function _getDefaultParams() internal view returns (Config memory) {
    return Config({
      owner: owner1,
      minter: minter1,
      revealer: revealer1,
      royaltyFeeBips: 1000, /* 1000 bips = 10% */
      defaultImage: "img"
    });
  }  

  function _buildDefaultTokenUri(uint tokenId) internal view returns (string memory) {
    string memory img = t.defaultImage();

    string memory json = string(
      abi.encodePacked(
        '{',
            '"name": "Tile #', tokenId.toString(), '",',
            '"description": "Jigzaw unrevealed tile - see https://jigsaw.xyz for instructions.",',
            '"image": "', img, '"',
        '}'
      ) 
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  function testTestBaseTop_ExcludeFromCoverage() public {}  
}
