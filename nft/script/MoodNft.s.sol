// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

// 2. Imports
import {Script, console} from "forge-std/Script.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {MoodNft} from "src/MoodNft.sol";

contract MoodNftScript is Script {
    MoodNft public moodNft;

    function run() external {
        string memory happy = vm.readFile("img/happy.svg");
        string memory sad = vm.readFile("img/sad.svg");
        vm.startBroadcast();
        moodNft = new MoodNft("Mood NFT", "MOOD", svgToImageUri(happy), svgToImageUri(sad));
        vm.stopBroadcast();
    }

    function svgToImageUri(string memory image) internal pure returns (string memory) {
        return string(abi.encodePacked("data:image/svg+xml;base64,",
            Base64.encode(bytes(string(abi.encodePacked(image))))));
    }
}
