// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IAccount, PackedUserOperation} from "account-abstraction/contracts/interfaces/IAccount.sol";
import {IEntryPoint} from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "account-abstraction/contracts/core/Helpers.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// entryPoint => this contract
contract MinimalAccount is Ownable, IAccount {
    error MinimalAccount__TransferFailed(address receiver, uint256 amount);
    error MinimalAccount__OnlyAcceptRequestFromEntryPoint(address sender);
    error MinimalAccount__OnlyAcceptRequestFromEntryPointOrOwner(address sender);
    error MinimalAccount__ExecuteFailed(bytes result);

    IEntryPoint private immutable i_entryPoint;

    //////////////
    // Modifier //
    //////////////
    modifier reqFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__OnlyAcceptRequestFromEntryPoint(msg.sender);
        }
        _;
    }

    modifier reqFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__OnlyAcceptRequestFromEntryPointOrOwner(msg.sender);
        }
        _;
    }

    constructor(address _entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(_entryPoint);
    }

    receive() external payable {}

    ///////////////////////
    // external function //
    ///////////////////////

    // @dev basic validate: a signature is valid, if it's THIS contract owner
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        reqFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        _payPrefund(missingAccountFunds);
    }

    function execute(address destination, uint256 value, bytes calldata data) external reqFromEntryPointOrOwner {
        (bool successed, bytes memory result) = payable(destination).call{value: value}(data);
        if (!successed) {
            revert MinimalAccount__ExecuteFailed(result);
        }
    }

    ///////////////////////
    // internal function //
    ///////////////////////
    function _validateSignature(PackedUserOperation calldata userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(digest, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }
        return SIG_VALIDATION_SUCCESS;
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds, gas: type(uint256).max}("");
            if (!success) {
                revert MinimalAccount__TransferFailed(msg.sender, missingAccountFunds);
            }
        }
    }

    /////////////////////////
    // Getters and Setters //
    /////////////////////////
    function getEntryPoint() public view returns (IEntryPoint) {
        return i_entryPoint;
    }
}
