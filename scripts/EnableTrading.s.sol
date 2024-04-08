// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { console2 as c } from "forge-std/Script.sol";
import { JigzawNFT } from "src/JigzawNFT.sol";
import { LotteryNFT } from "src/LotteryNFT.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { ScriptBase } from "./ScriptBase.sol";

contract EnableTrading is ScriptBase {
  function run() public {
    Config memory cfg = _getScriptConfig();

    address wallet = cfg.owner;
    c.log("Wallet:", wallet);

    vm.startBroadcast(wallet);

    c.log("Enabling trading...");

    JigzawNFT.Config memory jigzawNftConfig = _getJigzawNftConfig(cfg);
    address payable jigzawNftAddress = _getDeployedAddress(type(JigzawNFT).creationCode, abi.encode(jigzawNftConfig));

    MintSwapPool.Config memory poolConfig = _getMintSwapPoolConfig(cfg, jigzawNftAddress);
    address poolAddress = _getDeployedAddress(type(MintSwapPool).creationCode, abi.encode(poolConfig));

    MintSwapPool pool = MintSwapPool(poolAddress);
    pool.setEnabled(true);

    c.log("All done");

    vm.stopBroadcast();    
  }
}
