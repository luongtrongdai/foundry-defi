// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {Script, console} from "forge-std/Script.sol";
import {BasicNft} from "src/BasicNft.sol";

contract BasicNftScript is Script {
    BasicNft public basicNft;

    function run() external {
        vm.startBroadcast();
        basicNft = new BasicNft("GameFi", "KEN");
        vm.stopBroadcast();
    }
}
