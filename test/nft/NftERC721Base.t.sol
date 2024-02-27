// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { IERC165 } from "openzeppelin/interfaces/IERC165.sol";
import { IERC721 } from "openzeppelin/interfaces/IERC721.sol";
import { IERC721Metadata } from "openzeppelin/interfaces/IERC721Metadata.sol";
import { IERC721Enumerable } from "openzeppelin/interfaces/IERC721Enumerable.sol";
import { ERC721, ERC721TokenReceiver } from "src/ERC721.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";
import { NftTestBase } from "./NftTestBase.sol";
import { Bytes32AddressLib } from "solmate/utils/Bytes32AddressLib.sol";


contract NftERC721Base is NftTestBase, IERC721Errors {
  MockERC721 b;
  address public wallet1 = vm.addr(0x56565656);
  address public wallet2 = vm.addr(0x12121212);

  function setUp() public override {
    super.setUp();
    b = new MockERC721("Test", "TEST");
  }

  // Basic

  function test_BasicDetails() public {
    assertEq(b.name(), "Test");
    assertEq(b.symbol(), "TEST");
    assertEq(b.totalSupply(), 0);
  }

  function test_SupportsInterface() public {
    assertTrue(b.supportsInterface(type(IERC165).interfaceId));
    assertTrue(b.supportsInterface(type(IERC721).interfaceId));
    assertTrue(b.supportsInterface(type(IERC721Metadata).interfaceId));
    assertTrue(b.supportsInterface(type(IERC721Enumerable).interfaceId));
  }

  function test_TokenURI() public {
    assertEq(b.tokenURI(1), "uri");
    assertEq(b.tokenURI(2), "uri");
  }

  // Mint

  function test_SingleMint_UpdatesEnumeration() public {
    b.mint(wallet1, 1, "");
    b.mint(wallet1, 2, "");

    assertEq(b.totalSupply(), 2);
    assertEq(b.tokenByIndex(0), 1);
    assertEq(b.tokenByIndex(1), 2);
    assertEq(b.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(b.tokenOfOwnerByIndex(wallet1, 1), 2);
    assertEq(b.balanceOf(wallet1), 2);
    assertEq(b.ownerOf(1), wallet1);
    assertEq(b.ownerOf(2), wallet1);

    b.mint(wallet2, 3, "");
    assertEq(b.totalSupply(), 3);
    assertEq(b.tokenByIndex(2), 3);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 0), 3);
    assertEq(b.balanceOf(wallet2), 1);
    assertEq(b.ownerOf(3), wallet2);
  }

  function test_SingleMint_FiresTransferEvent() public {
    vm.recordLogs();

    b.mint(wallet1, 1, "");

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(entries[0].topics.length, 4, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("Transfer(address,address,uint256)"),
        "Invalid event signature"
    );
    assertEq(entries[0].topics[1], bytes32(0), "Invalid from");
    assertEq(entries[0].topics[2], _toBytes32(wallet1), "Invalid to");
    assertEq(entries[0].topics[3], bytes32(uint(1)), "Invalid tokenId");
  }

  function test_SingleMint_InvokesReceiver_Good() public {
    address good = address(new GoodERC721Receiver());

    vm.prank(wallet1);
    b.mint(good, 1, "test");

    assertEq(b.ownerOf(1), good);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived();
    assertEq(r.operator, wallet1);
    assertEq(r.from, address(0));
    assertEq(r.tokenId, 1);
    assertEq(r.data, "test");
  }

  function test_SingleMint_InvokesReceiver_Bad() public {
    address bad = address(new BadERC721Receiver());

    vm.expectRevert(abi.encodeWithSelector(ERC721UnsafeTokenReceiver.selector, bad, uint(1)));
    b.mint(bad, 1, "test");
  }

  function test_SingleMintAlreadyMintedToken_Fails() public {
    b.mint(wallet1, 1, "");
    
    vm.expectRevert(abi.encodeWithSelector(ERC721TokenAlreadyMinted.selector, uint(1)));
    b.mint(wallet1, 1, "");
  }

  function test_SingleMintToZeroAddress_Fails() public {
    vm.expectRevert(abi.encodeWithSelector(ERC721ZeroAddress.selector));
    b.mint(address(0), 1, "");
  }

  // Transfer

  function test_TransferFrom_UpdatesEnumeration() public {
    b.mint(wallet1, 1, "");
    b.mint(wallet1, 2, "");
    b.mint(wallet2, 3, "");

    vm.startPrank(wallet1);
    b.transferFrom(wallet1, wallet2, 1);
    b.transferFrom(wallet1, wallet2, 2);
    vm.stopPrank();

    assertEq(b.totalSupply(), 3);
    
    assertEq(b.tokenByIndex(0), 1);
    assertEq(b.tokenByIndex(1), 2);
    assertEq(b.tokenByIndex(2), 3);

    assertEq(b.tokenOfOwnerByIndex(wallet1, 0), 0);

    assertEq(b.tokenOfOwnerByIndex(wallet2, 0), 3);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 1), 1);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 2), 2);

    assertEq(b.balanceOf(wallet1), 0);
    assertEq(b.balanceOf(wallet2), 3);
  }

  function test_TransferFrom_CancelsApprovals() public {
    b.mint(wallet1, 1, "");

    vm.prank(wallet1);
    b.approve(wallet2, 1);

    vm.prank(wallet1);
    b.transferFrom(wallet1, wallet2, 1);

    assertEq(b.getApproved(1), address(0));
  }

  function test_TransferFrom_FiresTransferEvent() public {
    b.mint(wallet1, 1, "");

    vm.recordLogs();

    vm.prank(wallet1);
    b.transferFrom(wallet1, wallet2, 1);

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(entries[0].topics.length, 4, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("Transfer(address,address,uint256)"),
        "Invalid event signature"
    );
    assertEq(entries[0].topics[1], _toBytes32(wallet1), "Invalid from");
    assertEq(entries[0].topics[2], _toBytes32(wallet2), "Invalid to");
    assertEq(entries[0].topics[3], bytes32(uint(1)), "Invalid tokenId");
  }

  function test_TransferFrom_InvalidFrom_Fails() public {
    b.mint(wallet2, 1, "");

    vm.expectRevert(abi.encodeWithSelector(ERC721InvalidOwner.selector, wallet1, uint(1)));
    b.transferFrom(wallet1, wallet2, 1);
  }

  function test_TransferFrom_ToZeroAddress_Fails() public {
    b.mint(wallet2, 1, "");

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(ERC721ZeroAddress.selector));
    b.transferFrom(wallet2, address(0), 1);
  }  

  // Safe Transfer

  function test_SafeTransferFrom_UpdatesEnumeration() public {
    b.mint(wallet1, 1, "");
    b.mint(wallet1, 2, "");
    b.mint(wallet2, 3, "");

    vm.startPrank(wallet1);
    b.safeTransferFrom(wallet1, wallet2, 1, "");
    b.safeTransferFrom(wallet1, wallet2, 2, "");
    vm.stopPrank();

    assertEq(b.totalSupply(), 3);
    
    assertEq(b.tokenByIndex(0), 1);
    assertEq(b.tokenByIndex(1), 2);
    assertEq(b.tokenByIndex(2), 3);

    assertEq(b.tokenOfOwnerByIndex(wallet1, 0), 0);

    assertEq(b.tokenOfOwnerByIndex(wallet2, 0), 3);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 1), 1);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 2), 2);

    assertEq(b.balanceOf(wallet1), 0);
    assertEq(b.balanceOf(wallet2), 3);
  }

  function test_SafeTransferFrom_CancelsApprovals() public {
    b.mint(wallet1, 1, "");

    vm.prank(wallet1);
    b.approve(wallet2, 1);

    vm.prank(wallet1);
    b.safeTransferFrom(wallet1, wallet2, 1, "");

    assertEq(b.getApproved(1), address(0));
  }

  function test_SafeTransferFrom_FiresTransferEvent() public {
    b.mint(wallet1, 1, "");

    vm.recordLogs();

    vm.prank(wallet1);
    b.safeTransferFrom(wallet1, wallet2, 1);

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(entries[0].topics.length, 4, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("Transfer(address,address,uint256)"),
        "Invalid event signature"
    );
    assertEq(entries[0].topics[1], _toBytes32(wallet1), "Invalid from");
    assertEq(entries[0].topics[2], _toBytes32(wallet2), "Invalid to");
    assertEq(entries[0].topics[3], bytes32(uint(1)), "Invalid tokenId");
  }

  function test_SafeTransferFrom_InvokesReceiver_Good() public {
    address good = address(new GoodERC721Receiver());

    vm.startPrank(wallet1);
    b.mint(wallet1, 1, "");
    b.safeTransferFrom(wallet1, good, 1, "test");
    vm.stopPrank();

    assertEq(b.ownerOf(1), good);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived();
    assertEq(r.operator, wallet1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 1);
    assertEq(r.data, "test");
  }

  function test_SafeTransferFrom_InvalidFrom_Fails() public {
    b.mint(wallet2, 1, "");

    vm.expectRevert(abi.encodeWithSelector(ERC721InvalidOwner.selector, wallet1, uint(1)));
    b.safeTransferFrom(wallet1, wallet2, 1);
  }

  function test_SafeTransferFrom_ToZeroAddress_Fails() public {
    b.mint(wallet2, 1, "");

    vm.prank(wallet2);
    vm.expectRevert(abi.encodeWithSelector(ERC721ZeroAddress.selector));
    b.safeTransferFrom(wallet2, address(0), 1);
  }

  function test_SafeTransferFromWithoutData_InvokesReceiver_Good() public {
    address good = address(new GoodERC721Receiver());

    vm.startPrank(wallet1);
    b.mint(wallet1, 1, "");
    b.safeTransferFrom(wallet1, good, 1);
    vm.stopPrank();

    assertEq(b.ownerOf(1), good);

    GoodERC721Receiver.Received memory r = GoodERC721Receiver(good).getReceived();
    assertEq(r.operator, wallet1);
    assertEq(r.from, wallet1);
    assertEq(r.tokenId, 1);
    assertEq(r.data, "");
  }

  function test_SafeTransferFrom_InvokesReceiver_Bad() public {
    address bad = address(new BadERC721Receiver());

    vm.startPrank(wallet1);
    b.mint(wallet1, 1, "");
    vm.expectRevert(abi.encodeWithSelector(ERC721UnsafeTokenReceiver.selector, bad, uint(1)));
    b.safeTransferFrom(wallet1, bad, 1, "test");
    vm.stopPrank();
  }

  // Burn

  function test_Burn_UpdatesEnumeration() public {
    b.mint(wallet1, 1, "");
    b.mint(wallet1, 2, "");
    b.mint(wallet2, 3, "");
    b.mint(wallet2, 4, "");
    b.mint(wallet2, 5, "");

    b.burn(5); // last item in tokenByIndex and tokenOfOwnerByIndex(wallet2)
    b.burn(2); // last item in tokenOfOwnerByIndex(wallet1)
    b.burn(3); // first item in tokenOfOwnerByIndex(wallet2)

    assertEq(b.totalSupply(), 2);
    assertEq(b.tokenByIndex(0), 1);
    assertEq(b.tokenByIndex(1), 4);
    assertEq(b.tokenByIndex(2), 0);
    assertEq(b.tokenOfOwnerByIndex(wallet1, 0), 1);
    assertEq(b.tokenOfOwnerByIndex(wallet1, 1), 0);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 0), 4);
    assertEq(b.tokenOfOwnerByIndex(wallet2, 1), 0);
    assertEq(b.balanceOf(wallet1), 1);
    assertEq(b.balanceOf(wallet2), 1);
    assertEq(b.ownerOf(1), wallet1);
    assertEq(b.ownerOf(4), wallet2);

    vm.expectRevert(abi.encodeWithSelector(ERC721TokenNotMinted.selector, uint(2)));
    assertEq(b.ownerOf(2), address(0));
    vm.expectRevert(abi.encodeWithSelector(ERC721TokenNotMinted.selector, uint(3)));
    assertEq(b.ownerOf(3), address(0));
    vm.expectRevert(abi.encodeWithSelector(ERC721TokenNotMinted.selector, uint(5)));
    assertEq(b.ownerOf(5), address(0));
  }

  function test_Burn_CancelsApprovals() public {
    b.mint(wallet1, 1, "");
    
    vm.prank(wallet1);
    b.approve(wallet2, 1);
    b.burn(1);

    assertEq(b.getApproved(1), address(0));
  }

  function test_Burn_FiresTransferEvent() public {
    b.mint(wallet1, 1, "");
    vm.recordLogs();

    b.burn(1);

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 1, "Invalid entry count");
    assertEq(entries[0].topics.length, 4, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("Transfer(address,address,uint256)"),
        "Invalid event signature"
    );
    assertEq(entries[0].topics[1], _toBytes32(wallet1), "Invalid from");
    assertEq(entries[0].topics[2], bytes32(0), "Invalid to");
    assertEq(entries[0].topics[3], bytes32(uint(1)), "Invalid tokenId");
  }

  function test_BurnUnmintedToken_Fails() public {
    vm.expectRevert(abi.encodeWithSelector(ERC721TokenNotMinted.selector, uint(1)));
    b.burn(1);
  }
}



contract MockERC721 is ERC721 {
  uint lastMintedId;

  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {}

  function mint(address to, uint256 id, bytes memory data) public {
    _safeMint(to, id, data);
  }

  function batchMint(address to, uint256 count) public {
    _safeBatchMintRange(to, lastMintedId + 1, count);
    lastMintedId += count;
  }

  function burn(uint256 id) public {
    _burn(id);
  }

  function tokenURI(uint256 /*id*/) public pure override returns (string memory) {
    return "uri";
  }
}

contract GoodERC721Receiver is ERC721TokenReceiver {
  struct Received {
    address operator;
    address from;
    uint256 tokenId;
    bytes data;
  }

  Received internal received;

  function getReceived() public view returns (Received memory) {
    return received;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) public override returns (bytes4) {
    received = Received(operator, from, tokenId, data);
    return this.onERC721Received.selector;
  }
}

contract BadERC721Receiver is ERC721TokenReceiver {
  function onERC721Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*tokenId*/,
    bytes calldata /*data*/
  ) public override returns (bytes4) {
    return 0x0;
  }
}

