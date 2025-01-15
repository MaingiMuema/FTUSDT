// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPriceOracle.sol";
import "./Ownable.sol";

/**
 * @title Price Oracle for FTUSDT
 * @dev Implements price feed functionality for FTUSDT and collateral
 */
contract PriceOracle is IPriceOracle, Ownable {
    uint256 private ftusdtPrice;
    uint256 private collateralPrice;
    
    event PriceUpdated(string asset, uint256 price);
    
    constructor() {
        ftusdtPrice = 1 * 10**18; // Initialize at 1 USD
        collateralPrice = 1 * 10**18; // Initialize collateral price at 1 USD
    }
    
    function getPrice() external view override returns (uint256) {
        return ftusdtPrice;
    }
    
    function getCollateralPrice() external view override returns (uint256) {
        return collateralPrice;
    }
    
    function updatePrice(string memory asset, uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Price must be positive");
        
        if (keccak256(bytes(asset)) == keccak256(bytes("FTUSDT"))) {
            ftusdtPrice = newPrice;
        } else if (keccak256(bytes(asset)) == keccak256(bytes("COLLATERAL"))) {
            collateralPrice = newPrice;
        } else {
            revert("Invalid asset");
        }
        
        emit PriceUpdated(asset, newPrice);
    }
}
