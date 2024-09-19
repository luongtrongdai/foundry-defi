// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidMerkelProof();
    error MerkleAirdrop__AlreadyClaimed();

    event MerkleClaim(address indexed account, uint256 amount);

    address[] private claimers;
    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool hasClaimed) private s_claimed;

    constructor(bytes32 _merkleRoot, IERC20 _token) {
        i_merkleRoot = _merkleRoot;
        i_airdropToken = _token;
    }

    // leaf node = keccak256(account + amount)
    function claim(address claimer, uint256 amount, bytes32[] calldata merkleProof) external {
        if (s_claimed[claimer]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(claimer, amount))));
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidMerkelProof();
        }
        s_claimed[claimer] = true;
        emit MerkleClaim(claimer, amount);
        i_airdropToken.safeTransfer(claimer, amount);
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
