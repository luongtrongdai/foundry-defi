// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    uint256 private constant PRECISION = 1e18;
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer,,,) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        uint256 additionalFeedPrecision = 10**decimal;
        return uint256(answer) * (PRECISION / additionalFeedPrecision);
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(uint256 amount, address priceFeedAddr) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        uint256 price = getPrice(priceFeed);
        return (price * amount) / PRECISION;
    }
}