// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BoxV1} from "src/BoxV1.sol";

contract DeployBox is Script {
    function run() external returns (address) {
        return deployProxy();
    }

    function deployProxy() internal returns (address) {
        bytes4 selector = bytes4(keccak256("initialize()"));
        vm.startBroadcast(msg.sender);
        BoxV1 box = new BoxV1();
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(box),
            abi.encodeWithSelector(selector)
        );
        vm.stopBroadcast();
        return address(proxy);
    }
}
