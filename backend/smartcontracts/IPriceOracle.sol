// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPriceOracle {
    /**
     * @dev Returns the current price of FTUSDT in USD (18 decimals)
     */
    function getPrice() external view returns (uint256);
    
    /**
     * @dev Returns the current price of the collateral asset in USD (18 decimals)
     */
    function getCollateralPrice() external view returns (uint256);
}
