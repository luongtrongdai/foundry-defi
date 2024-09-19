// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    error OracleLib__StalePrice();

    uint256 private constant PRECISION = 1e18;
    uint256 private constant TIMEOUT = 3 hours;

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 answer,,,) = _stalePriceCheck(priceFeed);
        uint8 decimal = priceFeed.decimals();
        uint256 additionalFeedPrecision = 10 ** decimal;
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

    function getAmountFromUSD(uint256 usdAmountInWei, address priceFeedAddr) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddr);
        uint256 price = getPrice(priceFeed);
        return (usdAmountInWei * PRECISION / price);
    }

    function _stalePriceCheck(AggregatorV3Interface priceFeed) private view returns (uint80, int256, uint256, uint256, uint80) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            priceFeed.latestRoundData();

        if (updatedAt == 0 || answeredInRound < roundId) {
            revert OracleLib__StalePrice();
        }
        uint256 secondsSince = block.timestamp - updatedAt;
        if (secondsSince > TIMEOUT) revert OracleLib__StalePrice();

        return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function getTimeout() public pure returns (uint256) {
        return TIMEOUT;
    }
}
