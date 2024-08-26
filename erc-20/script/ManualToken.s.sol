// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.26;

// 2. Imports
import {Script, console} from "forge-std/Script.sol";
import {ManualToken} from "src/ManualToken.sol";

// 3. Interfaces, Libraries, Contracts
contract ManualTokenScript is Script {
    uint256 public constant INITIAL_SUPPLY = 1000 ether;

    ManualToken public manualToken;

    function run() external {
        vm.startBroadcast();

        manualToken = new ManualToken("ManualToken", "MT", INITIAL_SUPPLY);
        vm.stopBroadcast();
    }
}
