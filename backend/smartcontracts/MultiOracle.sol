// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPriceOracle.sol";
import "./Ownable.sol";

contract MultiOracle is IPriceOracle, Ownable {
    struct OracleData {
        uint256 price;
        uint256 timestamp;
        uint256 heartbeat;
        bool valid;
        uint256 weight;
    }

    mapping(address => OracleData) public oracles;
    address[] public oracleList;
    
    uint256 public constant MAX_ORACLE_COUNT = 10;
    uint256 public constant MIN_ORACLE_COUNT = 3;
    uint256 public constant MAX_PRICE_DEVIATION = 10; // 10% maximum deviation
    uint256 public constant MAX_HEARTBEAT = 1 hours;
    
    event OracleAdded(address indexed oracle, uint256 weight);
    event OracleRemoved(address indexed oracle);
    event PriceUpdated(address indexed oracle, uint256 price);
    event HeartbeatMissed(address indexed oracle);

    modifier onlyValidOracle(address oracle) {
        require(oracles[oracle].valid, "Invalid oracle");
        _;
    }

    function getPrice() external view override returns (uint256) {
        uint256 weightedSum = 0;
        uint256 totalWeight = 0;
        uint256 validOracleCount = 0;
        
        for (uint i = 0; i < oracleList.length; i++) {
            address oracle = oracleList[i];
            OracleData memory data = oracles[oracle];
            
            if (data.valid && 
                block.timestamp - data.timestamp <= data.heartbeat && 
                data.price > 0) {
                weightedSum += data.price * data.weight;
                totalWeight += data.weight;
                validOracleCount++;
            }
        }
        
        require(validOracleCount >= MIN_ORACLE_COUNT, "Insufficient valid oracles");
        require(totalWeight > 0, "No valid prices");
        
        return weightedSum / totalWeight;
    }

    function getCollateralPrice() external view override returns (uint256) {
        // For this implementation, we'll use the same price for collateral
        // In a production environment, you might want different price feeds for different collateral types
        return this.getPrice();
    }

    function addOracle(address oracle, uint256 weight) external onlyOwner {
        require(oracleList.length < MAX_ORACLE_COUNT, "Too many oracles");
        require(!oracles[oracle].valid, "Oracle already exists");
        require(weight > 0, "Weight must be positive");

        oracles[oracle] = OracleData({
            price: 0,
            timestamp: block.timestamp,
            heartbeat: MAX_HEARTBEAT,
            valid: true,
            weight: weight
        });
        
        oracleList.push(oracle);
        emit OracleAdded(oracle, weight);
    }

    function removeOracle(address oracle) external onlyOwner onlyValidOracle(oracle) {
        require(oracleList.length > MIN_ORACLE_COUNT, "Cannot remove oracle");
        oracles[oracle].valid = false;
        
        // Remove from list
        for (uint i = 0; i < oracleList.length; i++) {
            if (oracleList[i] == oracle) {
                oracleList[i] = oracleList[oracleList.length - 1];
                oracleList.pop();
                break;
            }
        }
        
        emit OracleRemoved(oracle);
    }

    function updatePrice(uint256 newPrice) external onlyValidOracle(msg.sender) {
        require(block.timestamp - oracles[msg.sender].timestamp <= oracles[msg.sender].heartbeat, "Heartbeat exceeded");
        
        // Check for extreme price deviations
        if (oracles[msg.sender].price > 0) {
            uint256 deviation = calculateDeviation(newPrice, oracles[msg.sender].price);
            require(deviation <= MAX_PRICE_DEVIATION, "Price deviation too high");
        }
        
        oracles[msg.sender].price = newPrice;
        oracles[msg.sender].timestamp = block.timestamp;
        
        emit PriceUpdated(msg.sender, newPrice);
    }

    function calculateDeviation(uint256 price1, uint256 price2) internal pure returns (uint256) {
        if (price1 > price2) {
            return ((price1 - price2) * 100) / price2;
        }
        return ((price2 - price1) * 100) / price1;
    }
}
