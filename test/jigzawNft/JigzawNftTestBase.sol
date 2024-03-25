// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Base64 } from "openzeppelin/utils/Base64.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";  
import { LotteryNFT } from "src/LotteryNFT.sol";
import { ERC721, IERC721TokenReceiver } from "src/ERC721.sol";
import { Auth } from "src/Auth.sol";
import { TestBase01 } from "test/utils/TestBase01.sol";

abstract contract JigzawNftTestBase is TestBase01 {  
  using Strings for uint256;

  uint pool1_key = 0x123456;
  address public pool1 = vm.addr(pool1_key);

  JigzawNFT public t;
  LotteryNFT public l;

  function setUp() virtual public {
    t = new JigzawNFT(_getDefaultJigzawNftConfig());
    l = new LotteryNFT(_getDefaultLotteryNftConfig(t));
  }

  // Helper methods

  function _buildDefaultTokenUri(uint /*tokenId*/) internal view returns (string memory) {
    string memory json = string(
      abi.encodePacked(
        '{',
            '"name": "Unrevealed tile",',
            '"description": "An unrevealed Jigzaw tile - see https://jigzaw.xyz for more info.",',
            '"image": "', t.defaultImage(), '"',
        '}'
      ) 
    );

    return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
  }

  function testJigzawNftTestBase_ExcludeFromCoverage() public {}  
}



contract MockERC721 is ERC721 {
  uint lastMintedId;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function mint(address to, uint256 id, bytes memory data) public {
    _safeMint(to, id, data);
  }

  function burn(uint256 id) public {
    _burn(id);
  }

  function batchMint(address to, uint256 count, bytes memory _data) public {
    _safeBatchMint(to, count, _data);
    lastMintedId += count;
  }

  function batchTransfer(address from, address to, uint256[] calldata ids, bytes memory data) public {
    _safeBatchTransfer(msg.sender, from, to, ids, data);
  }

  function batchTransfer(address from, address to, uint count, bytes memory data) public {
    _safeBatchTransfer(msg.sender, from, to, count, data);
  }

  function tokenURI(uint256 /*id*/) public pure override returns (string memory) {
    return "uri";
  }
}

contract GoodERC721Receiver is IERC721TokenReceiver {
  struct Received {
    address operator;
    address from;
    uint256 tokenId;
    bytes data;
  }

  Received[] internal received;

  function getReceived(uint i) public view returns (Received memory) {
    return received[i];
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    received.push(Received(operator, from, tokenId, data));
    return IERC721TokenReceiver.onERC721Received.selector;
  }
}

contract BadERC721Receiver is IERC721TokenReceiver {
  function onERC721Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*tokenId*/,
    bytes calldata /*data*/
  ) public override pure returns (bytes4) {
    return 0x0;
  }
}

