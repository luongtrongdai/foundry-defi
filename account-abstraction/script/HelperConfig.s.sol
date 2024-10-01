// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {EntryPoint} from "account-abstraction/contracts/core/EntryPoint.sol";

contract HelperConfig is Script {
    error HelperConfig__NotSupportChainId();

    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    address public constant BURNER_WALLET = 0x0aFF5c3ac89F0A91F713A9a789e343A78B838C3c;
    address public constant DEFAULT_ANVIL_WALLET = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    function run() external {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = _getEthSepoliaConfig();
        } else if (block.chainid == ZKSYNC_SEPOLIA_CHAIN_ID) {
            activeNetworkConfig = _getZkSyncSepoliaConfig();
        } else if (block.chainid == LOCAL_CHAIN_ID) {
            activeNetworkConfig = _getOrCreateAnvilConfig();
        } else {
            revert HelperConfig__NotSupportChainId();
        }
    }

    function _getEthSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
    }

    function _getZkSyncSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({entryPoint: address(0), account: BURNER_WALLET});
    }

    function _getOrCreateAnvilConfig() internal returns (NetworkConfig memory) {
        if (activeNetworkConfig.entryPoint != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast(DEFAULT_ANVIL_WALLET);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();
        // deploy mock EntryPoint
        return NetworkConfig({entryPoint: address(entryPoint), account: DEFAULT_ANVIL_WALLET});
    }
}
