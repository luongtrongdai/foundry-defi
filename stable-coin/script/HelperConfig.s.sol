// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Script} from "forge-std/Script.sol";
import {MockAggregatorV3} from "test/mocks/MockAggregatorV3.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    struct NetworkConfig {
        address[] tokenAddrs;
        address[] priceFeeds;
        address dscToken;
    }

    constructor() {
        if (block.chainid == 11155111) {
            getSepoliaEthConfig();
        } else {
            getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public {
        address[] memory tokenAddrs = new address[](2);
        tokenAddrs[0] = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
        tokenAddrs[1] = 0xE544cAd11e108775399358Bd0790bb72c9e3AD9E;
        address[] memory priceFeeds = new address[](2);
        priceFeeds[0] = 0x694AA1769357215DE4FAC081bf1f309aDC325306;
        priceFeeds[1] = 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43;

        activeNetworkConfig = NetworkConfig({tokenAddrs: tokenAddrs, priceFeeds: priceFeeds, dscToken: address(0)});
    }

    function getAnvilEthConfig() public {
        if (activeNetworkConfig.tokenAddrs.length == 0) {
            vm.startBroadcast();
            MockAggregatorV3 mockAggregatorV3 = new MockAggregatorV3(8, 2000e8);
            ERC20Mock weth = new ERC20Mock();
            vm.stopBroadcast();

            address[] memory tokenAddrs = new address[](1);
            tokenAddrs[0] = address(weth);
            address[] memory priceFeeds = new address[](1);
            priceFeeds[0] = address(mockAggregatorV3);

            activeNetworkConfig = NetworkConfig({tokenAddrs: tokenAddrs, priceFeeds: priceFeeds, dscToken: address(0)});
        }
    }

    function updateDscToken(address tokenAddr) external {
        activeNetworkConfig.dscToken = tokenAddr;
    }

    function getActiveNetworkConfig() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }
}
