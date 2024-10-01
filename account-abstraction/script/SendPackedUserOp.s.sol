// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IEntryPoint, PackedUserOperation} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract SendPackedUserOp is Script {
    function run() external {}

    function generatedSignedUserOp(bytes memory callData, address sender, HelperConfig helperConfig)
        public
        view
        returns (PackedUserOperation memory)
    {
        (address entryPoint, address account) = helperConfig.activeNetworkConfig();
        uint256 nonce = vm.getNonce(sender) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOp(callData, sender, nonce);

        bytes32 userOpHash = IEntryPoint(entryPoint).getUserOpHash(userOp);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        uint8 v; bytes32 r; bytes32 s;
        if (block.chainid == 31337) {
            uint256 anvilDefaultKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            (v, r, s) = vm.sign(anvilDefaultKey, digest);
            
        } else {
            (v, r, s) = vm.sign(account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v);
        return userOp;
    }

    ////////////////////////
    // internal functions //
    ////////////////////////
    function _generateUnsignedUserOp(bytes memory callData, address sender, uint256 nonce)
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verifyGasLimit = 16777216; // 1000000
        uint128 callGasLimit = verifyGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(verifyGasLimit) << 128 | callGasLimit),
            preVerificationGas: verifyGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
