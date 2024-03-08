// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { PoolCurve } from "src/Common.sol";

contract Deploy is Script {
  bytes32 internal constant CREATE2_SALT = keccak256("JigzawNFT.deployment.salt");

  string internal constant DEFAULT_TILE_IMG = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGZpbGw9Im5vbmUiIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBmaWxsPSIjRDhEOEQ4IiBmaWxsLW9wYWNpdHk9Ii41IiBkPSJNMCAwaDUxMnY1MTJIMHoiLz48ZyBjbGlwLXBhdGg9InVybCgjYSkiPjxwYXRoIGZpbGw9IiMzMTMwMzAiIGQ9Ik0xOTcuNiAzNTJoMTE1LjhjNC44IDAgOC43LTMuOSA4LjctOC43VjI0NWMwLTQuOC00LTguNy04LjctOC43aC04Ljd2LTI2YTQ5LjMgNDkuMyAwIDAgMC05OC40IDB2MjZoLTguN2E4LjcgOC43IDAgMCAwLTguNyA4Ljd2OTguNGMwIDQuOCA0IDguNyA4LjcgOC43Wm02Ni42LTU1djExLjZhOC43IDguNyAwIDEgMS0xNy40IDBWMjk3YTE0LjUgMTQuNSAwIDEgMSAxNy40IDBabS00MC41LTg2LjhhMzEuOSAzMS45IDAgMCAxIDYzLjYgMHYyNmgtNjMuNnYtMjZaIi8+PC9nPjxkZWZzPjxjbGlwUGF0aCBpZD0iYSI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTE2MCAxNjFoMTkxdjE5MUgxNjB6Ii8+PC9jbGlwUGF0aD48L2RlZnM+PC9zdmc+";

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
      defaultImage: DEFAULT_TILE_IMG
    });

    _assertDeployedAddressIsEmpty(type(JigzawNFT).creationCode, abi.encode(nftConfig));

    JigzawNFT nft = new JigzawNFT{salt: CREATE2_SALT}(nftConfig);
    c.log("JigzawNFT:", address(nft));
    
    c.log("Deploying MintSwapPool...");

    MintSwapPool.Config memory poolConfig = MintSwapPool.Config({
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

    _assertDeployedAddressIsEmpty(type(MintSwapPool).creationCode, abi.encode(poolConfig));

    MintSwapPool pool = new MintSwapPool{salt: CREATE2_SALT}(poolConfig);
    c.log("MintSwapPool:", address(pool));

    c.log("Enable pool on NFT contract...");
    nft.setPool(address(pool));

    c.log("All done");

    vm.stopBroadcast();        
  }
}
