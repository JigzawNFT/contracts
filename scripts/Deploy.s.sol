// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { console as c } from "forge-std/Script.sol";
import { ScriptBase } from "./ScriptBase.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { LotteryNFT } from "src/LotteryNFT.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";

contract Deploy is ScriptBase {
  function run() public {
    Config memory cfg = _getScriptConfig();

    address wallet = cfg.owner;
    c.log("Owner:", wallet);

    vm.startBroadcast(wallet);

    c.log("Deploying JigzawNFT...");

    JigzawNFT.Config memory jigzawNftConfig = _getJigzawNftConfig(cfg);
    c.log("JigzawNFT constructor args:");
    c.logBytes(abi.encode(jigzawNftConfig));

    JigzawNFT jigzawNft;
    address payable jigzawNftAddress = _getDeployedAddress(type(JigzawNFT).creationCode, abi.encode(jigzawNftConfig));
    if (jigzawNftAddress.code.length > 0) {
      c.log("JigzawNFT already deployed at:", jigzawNftAddress);
      jigzawNft = JigzawNFT(jigzawNftAddress);
    } else {
      jigzawNft = new JigzawNFT{salt: CREATE2_SALT}(jigzawNftConfig);
      c.log("JigzawNFT:", address(jigzawNft));
    }
    
    c.log("Deploying LotteryNFT...");

    LotteryNFT.Config memory lotteryNftConfig = _getLotteryNftConfig(cfg, jigzawNftAddress);
    c.log("LotteryNFT constructor args:");
    c.logBytes(abi.encode(lotteryNftConfig));

    LotteryNFT lotteryNft;
    address lotteryNftAddress = _getDeployedAddress(type(LotteryNFT).creationCode, abi.encode(lotteryNftConfig));
    if (lotteryNftAddress.code.length > 0) {
      c.log("LotteryNFT already deployed at:", lotteryNftAddress);
      lotteryNft = LotteryNFT(lotteryNftAddress);
    } else {
      lotteryNft = new LotteryNFT{salt: CREATE2_SALT}(lotteryNftConfig);
      c.log("LotteryNFT:", address(lotteryNft));
    }

    c.log("Deploying MintSwapPool...");

    MintSwapPool.Config memory poolConfig = _getMintSwapPoolConfig(cfg, jigzawNftAddress);
    c.log("MintSwapPool constructor args:");
    c.logBytes(abi.encode(poolConfig));

    MintSwapPool pool;
    address poolAddress = _getDeployedAddress(type(MintSwapPool).creationCode, abi.encode(poolConfig));
    if (poolAddress.code.length > 0) {
      c.log("MintSwapPool already deployed at:", poolAddress);
      pool = MintSwapPool(poolAddress);
    } else {
      pool = new MintSwapPool{salt: CREATE2_SALT}(poolConfig);
      c.log("MintSwapPool:", poolAddress);
    }

    address currentPool = jigzawNft.pool();
    if (currentPool != poolAddress) {
      c.log("Enable pool on Jigzaw contract...");
      jigzawNft.setPool(poolAddress);
    } else {
      c.log("Pool already enabled on Jigzaw contract...");    
    }

    address currentLottery = address(jigzawNft.getLottery().nft);
    if (currentLottery != lotteryNftAddress) {
      c.log("Enable lottery on Jigzaw contract...");
      jigzawNft.setLotteryNFT(lotteryNftAddress);
    } else {
      c.log("Lottery already enabled on Jigzaw contract...");    
    }

    c.log("Enable trading on MintSwapPool...");
    pool.setEnabled(true);

    c.log("All done");

    vm.stopBroadcast();        
  }
}
