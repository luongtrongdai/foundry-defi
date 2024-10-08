// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MerkelAirdropScript} from "script/MerkleAirdop.s.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {GiftToken} from "src/GiftToken.sol";

contract MerkleAirdropTest is Test {
    MerkelAirdropScript private deployScript;
    MerkleAirdrop private merkleAirdrop;
    GiftToken private giftToken;
    address private user;
    uint256 private userPrivKey;
    address private gasPlayer;

    function setUp() external {
        deployScript = new MerkelAirdropScript();
        // deployScript.run();
        giftToken = new GiftToken();
        merkleAirdrop = new MerkleAirdrop(deployScript.ROOT(), giftToken);
        giftToken.mint(address(merkleAirdrop), deployScript.AMOUNT_TO_TRANSFER());

        (user, userPrivKey) = makeAddrAndKey("user");
        console.log("User address: ", user);
        gasPlayer = makeAddr("gasPlayer");
    }

    function test_deploySuccess() external view {
        uint256 airdropBalance = giftToken.balanceOf(address(merkleAirdrop));
        assertEq(airdropBalance, deployScript.AMOUNT_TO_TRANSFER());
        assertEq(merkleAirdrop.getMerkleRoot(), deployScript.ROOT());
    }

    function test_UserCanClaim() external {
        uint256 startBalance = giftToken.balanceOf(user);
        uint256 claimBalance = 25 ether;
        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
        merkleProof[1] = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;

        bytes32 message = merkleAirdrop.getMessage(user, claimBalance);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivKey, message);
        vm.prank(gasPlayer);
        merkleAirdrop.claim(user, claimBalance, merkleProof, v, r, s);

        assertEq(startBalance + claimBalance, giftToken.balanceOf(user));
    }
}
