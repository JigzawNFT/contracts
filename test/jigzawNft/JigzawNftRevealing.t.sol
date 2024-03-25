// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { IERC721Errors } from "src/IERC721Errors.sol";
import { JigzawNftTestBase } from "./JigzawNftTestBase.sol";
import { Auth } from "src/Auth.sol";
import { LibErrors } from "src/LibErrors.sol";

contract JigzawNftRevealing is JigzawNftTestBase {
  function setUp() virtual override public {
    super.setUp();

    vm.prank(owner1);
    jigzawNft.setLotteryNFT(address(lotteryNft_addr));

    uint id = 1;
    string memory uri = "";

    vm.prank(wallet1);
    jigzawNft.mint(id, uri, _computeMinterSig(
      abi.encodePacked(wallet1, id, uri), 
      block.timestamp + 10 seconds
    ));
  }

  function test_RevealWithRevealerAuthorisation_Succeeds() public {
    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri1"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    jigzawNft.reveal(1, "uri1", sig);

    assertEq(jigzawNft.tokenURI(1), "uri1");
    assertEq(jigzawNft.revealed(1), true);
  }

  function test_RevealWithRevealerAuthorisation_EmitsEvent() public {
    vm.recordLogs();

    vm.prank(wallet1);
    jigzawNft.reveal(1, "uri1", _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri1"),
      block.timestamp + 10 seconds
    ));

    Vm.Log[] memory entries = vm.getRecordedLogs();
    assertEq(entries.length, 2, "Invalid entry count");
    assertEq(entries[0].topics.length, 1, "Invalid event count");
    assertEq(
        entries[0].topics[0],
        keccak256("MetadataUpdate(uint256)"),
        "Invalid event signature"
    );
    (uint256 tokenId) = abi.decode(entries[0].data, (uint256));
    assertEq(tokenId, 1, "Invalid token id");
  }

  function test_RevealWithRevealerAuthorisation_AwardsLotteryTickets() public {
    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri1"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    jigzawNft.reveal(1, "uri1", sig);

    assertEq(jigzawNft.tokenURI(1), "uri1");
    assertEq(jigzawNft.revealed(1), true);
  }

  function test_RevealWithNotRevealerAuthorisation_Fails() public {
    Auth.Signature memory sigOwner = _computeOwnerSig(
      abi.encodePacked(uint(1), "uri1"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, wallet1));
    jigzawNft.reveal(1, "uri1", sigOwner);

    Auth.Signature memory sigMinter = _computeMinterSig(
      abi.encodePacked(uint(1), "uri1"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureInvalid.selector, wallet1));
    jigzawNft.reveal(1, "uri1", sigMinter);
  }

  function test_RevealWithExpiredSignature_Fails() public {
    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri"),
      block.timestamp - 1 seconds
    );

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureExpired.selector, wallet1));
    jigzawNft.reveal(uint(1), "uri", sig);
  }

  function test_RevealWhenSignatureAlreadyUsed_Fails() public {
    Auth.Signature memory sig = _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri"),
      block.timestamp + 10 seconds
    );

    vm.prank(wallet1);
    jigzawNft.reveal(uint(1), "uri", sig);

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.SignatureAlreadyUsed.selector, wallet1));
    jigzawNft.reveal(uint(1), "uri", sig);
  }

  function test_RevealWhenAlreadyRevealed_Fails() public {
    vm.prank(wallet1);
    jigzawNft.reveal(uint(1), "uri", _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri"),
      block.timestamp + 10 seconds
    ));

    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(LibErrors.AlreadyRevealed.selector, 1));
    jigzawNft.reveal(uint(1), "uri", _computeRevealerSig(
      abi.encodePacked(wallet1, uint(1), "uri"),
      block.timestamp + 20 seconds
    ));
  }

  function test_RevealNonMintedToken_Fails() public {
    vm.prank(wallet1);
    vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721TokenNotMinted.selector, 2));
    jigzawNft.reveal(uint(2), "uri", _computeRevealerSig(
      abi.encodePacked(wallet1, uint(2), "uri"),
      block.timestamp + 10 seconds
    ));
  }
}
