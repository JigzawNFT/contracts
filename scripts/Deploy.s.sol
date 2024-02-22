// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { Config } from "../src/Structs.sol";
import { JigzawNFT } from "../src/JigzawNFT.sol";

contract Deploy is Script {
  bytes32 internal constant CREATE2_SALT = keccak256("JigzawNFT.deployment.salt");

  function run() public {
    address wallet = msg.sender;
    c.log("Wallet:", wallet);

    vm.startBroadcast(wallet);

    // deploy NFT contract using CREATE2
    Config memory config = Config({
      owner: wallet,
      minter: wallet,
      revealer: wallet,
      royaltyFeeBips: 500, /* 500 bips = 5% */
      defaultImage: "img"
    });
    JigzawNFT nft = new JigzawNFT{salt: CREATE2_SALT}(config);

    c.log("JigzawNFT:", address(nft));
    
    // Sanity check!
    string memory name = nft.name();
    c.log("Sanity check, NFT name:", name);
    if (!Strings.equal(name, "Jigzaw")) {
      revert("NFT name is incorrect");
    }

    vm.stopBroadcast();        
  }
}
