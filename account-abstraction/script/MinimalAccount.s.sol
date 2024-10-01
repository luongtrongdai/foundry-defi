// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract MinimalAccountScript is Script {
    MinimalAccount public minimalAccount;
    HelperConfig public helperConfig;

    function run() external {
        helperConfig = new HelperConfig();
        helperConfig.run();
        (address entryPoint, address account) = helperConfig.activeNetworkConfig();

        vm.startBroadcast(account);
        minimalAccount = new MinimalAccount(entryPoint);
        minimalAccount.transferOwnership(account);
        vm.stopBroadcast();
    }
}
