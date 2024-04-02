// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { LotteryNFT } from "src/LotteryNFT.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { PoolCurve } from "src/Common.sol";

contract Deploy is Script {
  bytes32 internal constant CREATE2_SALT = keccak256("JigzawNFT.deployment.salt");

  string internal constant DEFAULT_TILE_IMG = "data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIGZpbGw9Im5vbmUiIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBmaWxsPSIjRDhEOEQ4IiBmaWxsLW9wYWNpdHk9Ii41IiBkPSJNMCAwaDUxMnY1MTJIMHoiLz48ZyBjbGlwLXBhdGg9InVybCgjYSkiPjxwYXRoIGZpbGw9IiMzMTMwMzAiIGQ9Ik0xOTcuNiAzNTJoMTE1LjhjNC44IDAgOC43LTMuOSA4LjctOC43VjI0NWMwLTQuOC00LTguNy04LjctOC43aC04Ljd2LTI2YTQ5LjMgNDkuMyAwIDAgMC05OC40IDB2MjZoLTguN2E4LjcgOC43IDAgMCAwLTguNyA4Ljd2OTguNGMwIDQuOCA0IDguNyA4LjcgOC43Wm02Ni42LTU1djExLjZhOC43IDguNyAwIDEgMS0xNy40IDBWMjk3YTE0LjUgMTQuNSAwIDEgMSAxNy40IDBabS00MC41LTg2LjhhMzEuOSAzMS45IDAgMCAxIDYzLjYgMHYyNmgtNjMuNnYtMjZaIi8+PC9nPjxkZWZzPjxjbGlwUGF0aCBpZD0iYSI+PHBhdGggZmlsbD0iI2ZmZiIgZD0iTTE2MCAxNjFoMTkxdjE5MUgxNjB6Ii8+PC9jbGlwUGF0aD48L2RlZnM+PC9zdmc+";

  string internal constant DEFAULT_LOTTERY_IMG = "";

  address internal constant DEV_ROYALTY_RECEIVER = 0x314E889E5B20d7D48B17c2890B44A42723e2F8a6;

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

    JigzawNFT.Config memory jigzawNftConfig = JigzawNFT.Config({
      owner: wallet,
      minter: wallet,
      devRoyaltyReceiver: DEV_ROYALTY_RECEIVER,
      devRoyaltyFeeBips: 500, /* 500 bips = 5% */
      defaultImage: DEFAULT_TILE_IMG,
      lotteryPotFeeBips: 500, /* 500 bips = 5% */
      lotteryDeadline: 1735689600, /* 2025-01-01 00:00:00 - keep it fixed so that CREATE2 returns same address each time */
      lotteryRevealThreshold: 9261 /* level 1 + level 2 + level 3 tiles */
    });

    _assertDeployedAddressIsEmpty(type(JigzawNFT).creationCode, abi.encode(jigzawNftConfig));

    JigzawNFT jigzawNft = new JigzawNFT{salt: CREATE2_SALT}(jigzawNftConfig);
    c.log("JigzawNFT:", address(jigzawNft));
    
    c.log("Deploying LotteryNFT...");

    LotteryNFT.Config memory lotteryNftConfig = LotteryNFT.Config({
      minter: address(jigzawNft),
      defaultImage: DEFAULT_LOTTERY_IMG,
      royaltyReceiver: DEV_ROYALTY_RECEIVER,
      royaltyFeeBips: 500 /* 500 bips = 5% */
    });

    _assertDeployedAddressIsEmpty(type(LotteryNFT).creationCode, abi.encode(lotteryNftConfig));

    LotteryNFT lotteryNft = new LotteryNFT{salt: CREATE2_SALT}(lotteryNftConfig);
    c.log("LotteryNFT:", address(lotteryNft));

    c.log("Deploying MintSwapPool...");

    MintSwapPool.Config memory poolConfig = MintSwapPool.Config({
      nft: address(jigzawNft),
      curve: PoolCurve({
        mintStartId: 1,
        mintEndId: 7056,
        startPriceWei: 0.01 ether,
        /*
        Delta is equiv. to 1.0006 => increase by 0.06% 
        */
        delta: 1000600000000000000 
      })
    });

    _assertDeployedAddressIsEmpty(type(MintSwapPool).creationCode, abi.encode(poolConfig));

    MintSwapPool pool = new MintSwapPool{salt: CREATE2_SALT}(poolConfig);
    c.log("MintSwapPool:", address(pool));

    c.log("Enable pool on Jigzaw contract...");
    jigzawNft.setPool(address(pool));

    c.log("Enable lottery on Jigzaw contract...");
    jigzawNft.setLotteryNFT(address(lotteryNft));

    c.log("All done");

    vm.stopBroadcast();        
  }
}
