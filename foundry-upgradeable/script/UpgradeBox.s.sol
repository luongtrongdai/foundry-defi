// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BoxV1} from "src/BoxV1.sol";
import {BoxV2} from "src/BoxV2.sol";

contract UpgradeBox is Script {
    function run() external returns (address) {
        address proxy = DevOpsTools.get_most_recent_deployment(
            "ERC1967Proxy",
            block.chainid
        );
        return upgradeBox(proxy);
    }

    function upgradeBox(address proxy) public returns (address) {
        vm.startBroadcast(msg.sender);
        BoxV2 box = new BoxV2();
        BoxV1(proxy).upgradeToAndCall(address(box), "");
        vm.stopBroadcast();
        return address(proxy);
    }
}
