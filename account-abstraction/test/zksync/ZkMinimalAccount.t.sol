// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {
    IAccount,
    Transaction,
    MemoryTransactionHelper,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    BOOTLOADER_FORMAL_ADDRESS
} from "foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ZkMinimalAccount} from "src/zksync/ZkMinimalAccount.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract ZkMinimalAccountTest is Test {
    ZkMinimalAccount private minimalAccount;
    ERC20Mock private token;
    address private defaultAccount = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() external {
        minimalAccount = new ZkMinimalAccount();
        token = new ERC20Mock();

        vm.deal(address(minimalAccount), 1 ether);
        minimalAccount.transferOwnership(defaultAccount);
        console.log("Owner: ", minimalAccount.owner());  
    }

    function test_zkOwnerCanExecute() external {
        address dest = address(token);
        uint256 value = 0;

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), 1 ether);

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);

        vm.prank(minimalAccount.owner());
        minimalAccount.executeTransaction("", "", transaction);

        assertEq(token.balanceOf(address(minimalAccount)), 1 ether);
    }

    function test_ZkMinimalAccountValidateTransaction() external {
        address dest = address(token);
        uint256 value = 0;

        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), 1 ether);

        Transaction memory transaction = _createUnsignedTransaction(minimalAccount.owner(), 113, dest, value, functionData);
        transaction = signTxn(transaction, defaultAccount); // Test for anvil first

        vm.prank(BOOTLOADER_FORMAL_ADDRESS);
        bytes4 magic = minimalAccount.validateTransaction("", "", transaction);
        assertEq(magic, ZkMinimalAccount.validateTransaction.selector);
    }

    ///////////////////////
    // internal function //
    ///////////////////////
    function _createUnsignedTransaction(
        address _from,
        uint8 _txnType,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal view returns (Transaction memory) {
        uint128 verifyGasLimit = 16777216; // 1000000
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;
        uint256 nonce = vm.getNonce(address(minimalAccount));
        bytes32[] memory factoryDeps = new bytes32[](0);

        Transaction memory txn = Transaction({
            txType: _txnType, // type 113 (0x71)
            from: uint256(uint160(_from)),
            to: uint256(uint160(_to)),
            gasLimit: verifyGasLimit,
            gasPerPubdataByteLimit: verifyGasLimit,
            maxFeePerGas: maxFeePerGas,
            maxPriorityFeePerGas: maxPriorityFeePerGas,
            paymaster: 0,
            nonce: nonce,
            value: _value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: _data,
            signature: hex"",
            factoryDeps: factoryDeps,
            paymasterInput: hex"", 
            reservedDynamic: hex""
        });

        return txn;
    }

    function signTxn(Transaction memory _transaction, address _account) internal view returns (Transaction memory) {
        bytes32 unsignTxnHash = MemoryTransactionHelper.encodeHash(_transaction);
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(unsignTxnHash);
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == 31337) {
            uint256 anvilDefaultKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
            (v, r, s) = vm.sign(anvilDefaultKey, digest);
        } else {
            (v, r, s) = vm.sign(_account, digest);
        }

        _transaction.signature = abi.encodePacked(r, s, v);
        return _transaction;
    }
}