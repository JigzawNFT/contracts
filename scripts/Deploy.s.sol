// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { MintSwapNftPool } from "src/MintSwapNftPool.sol";
import { PoolCurve } from "src/Common.sol";

contract Deploy is Script {
  bytes32 internal constant CREATE2_SALT = keccak256("JigzawNFT.deployment.salt");


  function _assertDeployedAddressIsEmpty(bytes memory creationCode, bytes memory constructorArgs) internal view returns (address) {
    address expectedAddr = vm.computeCreate2Address(
      CREATE2_SALT, 
      hashInitCode(creationCode, constructorArgs)
    );

    if (expectedAddr.code.length > 0) {
      c.log("!!!! Already deployed at:", expectedAddr);
      revert("Already deployd");
    }

    return expectedAddr;
  }


  function run() public {
    address wallet = msg.sender;
    c.log("Wallet:", wallet);

    vm.startBroadcast(wallet);

    c.log("Deploying JigzawNFT...");

    JigzawNFT.Config memory nftConfig = JigzawNFT.Config({
      owner: wallet,
      minter: wallet,
      revealer: wallet,
      pool: wallet,
      royaltyFeeBips: 500, /* 500 bips = 5% */
      defaultImage: "img"
    });

    _assertDeployedAddressIsEmpty(type(JigzawNFT).creationCode, abi.encode(nftConfig));

    JigzawNFT nft = new JigzawNFT{salt: CREATE2_SALT}(nftConfig);
    c.log("JigzawNFT:", address(nft));
    
    c.log("Deploying MintSwapNftPool...");

    MintSwapNftPool.Config memory poolConfig = MintSwapNftPool.Config({
      nft: address(nft),
      curve: PoolCurve({
        mintStartId: 1,
        mintEndId: 7056,
        startPriceWei: 0.01 ether,
        /*
        Delta is equiv. to 1.0005 => increase by 0.05% 
        At last item (no. 7056) the price will be 0.34 ether
        */
        delta: 1000500000000000000 
      })
    });

    _assertDeployedAddressIsEmpty(type(MintSwapNftPool).creationCode, abi.encode(poolConfig));

    MintSwapNftPool pool = new MintSwapNftPool{salt: CREATE2_SALT}(poolConfig);
    c.log("MintSwapNftPool:", address(pool));

    vm.stopBroadcast();        
  }
}
