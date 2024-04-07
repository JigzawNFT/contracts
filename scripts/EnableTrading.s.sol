// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.24;

import { Script, console2 as c } from "forge-std/Script.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { MintSwapPool } from "src/MintSwapPool.sol";
import { PoolCurve } from "src/Common.sol";

contract EnableTrading is Script {
  address internal constant POOL_ADDRESS = 0x28c659ec5bF449062fcbAe73474f8a67E8502235;

  function run() public {
    address wallet = msg.sender;
    c.log("Wallet:", wallet);

    vm.startBroadcast(wallet);

    c.log("Enabling trading...");

    MintSwapPool pool = MintSwapPool(POOL_ADDRESS);
    pool.setEnabled(true);

    c.log("All done");

    vm.stopBroadcast();        
  }
}
