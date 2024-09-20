// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {GiftToken} from "src/GiftToken.sol";

contract MerkelAirdropScript is Script {
    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    // 4 users, 25 Bagel tokens each
    uint256 public AMOUNT_TO_TRANSFER = 4 * (25 * 1e18);

    MerkleAirdrop public airdrop;
    GiftToken public giftToken;

    function run() external {
        vm.startBroadcast();
        giftToken = new GiftToken();
        airdrop = new MerkleAirdrop(ROOT, giftToken);
        giftToken.mint(address(airdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
    }
}