// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidMerkelProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();

    event MerkleClaim(address indexed account, uint256 amount);

    bytes32 private constant MESSAGE_TYPE_HASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    address[] private claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool hasClaimed) private s_claimed;

    constructor(bytes32 _merkleRoot, IERC20 _token) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _token;
    }

    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPE_HASH, AirdropClaim({account: account, amount: amount}))));
    }

    // leaf node = keccak256(account + amount)
    function claim(address claimer, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (s_claimed[claimer]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // check signature
        if (!_validateSignature(claimer, getMessage(claimer, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkelProof();
        }
        s_claimed[claimer] = true;
        emit MerkleClaim(claimer, amount);
        i_airdropToken.safeTransfer(claimer, amount);
    }

    ///////////////////////
    // Internal function //
    ///////////////////////
    function _validateSignature(address account, bytes32 message, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address signer,,) = ECDSA.tryRecover(message, v, r, s);
        return signer == account;
    }

    /////////////////////////
    // Getters and Setters //
    /////////////////////////
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
