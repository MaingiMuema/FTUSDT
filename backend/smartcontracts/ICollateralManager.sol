// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICollateralManager {
    /**
     * @dev Transfers collateral from a user to the contract
     * @param from Address to transfer collateral from
     * @param to Address to transfer collateral to
     * @param amount Amount of collateral to transfer
     */
    function transferCollateralFrom(address from, address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Transfers collateral to a user
     * @param to Address to transfer collateral to
     * @param amount Amount of collateral to transfer
     */
    function transferCollateral(address to, uint256 amount) external returns (bool);
}
