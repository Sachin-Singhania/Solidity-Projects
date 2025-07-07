// SPDX-License-Identifier: UNLICENSED
import {AggregatorV3Interface} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.13;
library OracleLib {
    error OracleLib___STALEPRICE();
    uint256 constant private TIMEOUT = 3 hours;
    function stalePriceCheck(
        AggregatorV3Interface priceFeed
    ) public view returns (uint80, int256, uint256, uint256, uint80) {
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        uint256 timeElapsed = block.timestamp - updatedAt;
        if (timeElapsed > TIMEOUT) {
            revert OracleLib___STALEPRICE();
    }
     return (roundId, answer, startedAt, updatedAt, answeredInRound);

}}
