// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {
    IAccount,
    Transaction,
    MemoryTransactionHelper,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {SystemContractsCaller} from
    "foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {Utils} from "foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";
import {INonceHolder} from "foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {
    DEPLOYER_SYSTEM_CONTRACT,
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS
} from "foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract ZkMinimalAccount is Ownable, IAccount {
    using MemoryTransactionHelper for Transaction;

    error ZkMinimalAccount__NotEnoughBalance(uint256 requireBalance);
    error ZkMinimalAccount__NotFromBootloader();
    error ZkMinimalAccount__NotFromBootloaderOrOwner();
    error ZkMinimalAccount__ExecuteFailed(bytes result);
    error ZkMinimalAccount__FailedToPay();

    //////////////
    // modifier //
    //////////////
    modifier requestFromBootloader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkMinimalAccount__NotFromBootloader();
        }
        _;
    }

    modifier requestFromBootloaderOrOwner() {
        if ((msg.sender != BOOTLOADER_FORMAL_ADDRESS) && (msg.sender != owner())) {
            revert ZkMinimalAccount__NotFromBootloaderOrOwner();
        }
        _;
    }

    ////////////////
    // contructor //
    ////////////////
    constructor() Ownable(msg.sender) {}

    ///////////////////////
    // external function //
    ///////////////////////
    receive() external payable {}

    function validateTransaction(
        bytes32, /*_txHash*/
        bytes32, /*_suggestedSignedHash*/
        Transaction calldata _transaction
    ) external payable requestFromBootloader returns (bytes4 magic) {
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32, /*_txHash*/
        bytes32, /*_suggestedSignedHash*/
        Transaction calldata _transaction
    ) external payable requestFromBootloaderOrOwner {
        _executeTransaction(_transaction);
    }

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        _validateTransaction(_transaction);
        _executeTransaction(_transaction);
    }

    function payForTransaction(bytes32, /*_txHash*/ bytes32, /*_suggestedSignedHash*/ Transaction calldata _transaction)
        external
        payable
    {
        bool successed = _transaction.payToTheBootloader();
        if (!successed) {
            revert ZkMinimalAccount__FailedToPay();
        }
    }

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable
    {}

    ///////////////////////
    // internal function //
    ///////////////////////
    function _validateTransaction(Transaction calldata _transaction) internal returns (bytes4 magic) {
        // call increment nonce
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );

        // Check for fee to pay
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkMinimalAccount__NotEnoughBalance(totalRequiredBalance);
        }

        // Check the signature
        bytes32 txHash = _transaction.encodeHash();
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(txHash);
        address signer = ECDSA.recover(digest, _transaction.signature);
        bool isValidSign = signer == owner();

        // return the "magic" number
        if (isValidSign) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
    }

    function _executeTransaction(Transaction calldata _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            // Deploy contract from account
            // We need call system contract
            SystemContractsCaller.systemCallWithPropagatedRevert(uint32(gasleft()), to, value, data);
        } else {
            bool successed;
            bytes memory result = new bytes(32);
            // (bool successed, bytes memory result) = payable(to).call{value: value}(_transaction.data);
            assembly {
                successed := call(gas(), to, value, add(data, 0x20), mload(data), result, mload(result))
            }
            if (!successed) {
                revert ZkMinimalAccount__ExecuteFailed(result);
            }
        }
    }
}
