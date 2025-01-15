const PriceOracle = artifacts.require("PriceOracle");
const CollateralManager = artifacts.require("CollateralManager");
const FTUSDT = artifacts.require("FTUSDT");

module.exports = async function(deployer) {
  try {
    // Deploy PriceOracle
    await deployer.deploy(PriceOracle);
    const priceOracle = await PriceOracle.deployed();
    console.log('PriceOracle deployed at:', priceOracle.address);

    // Deploy CollateralManager
    await deployer.deploy(CollateralManager);
    const collateralManager = await CollateralManager.deployed();
    console.log('CollateralManager deployed at:', collateralManager.address);

    // Deploy FTUSDT with initial supply and dependencies
    const initialSupply = 1000000; // 1 million FTUSDT
    await deployer.deploy(
      FTUSDT,
      initialSupply,
      priceOracle.address,
      collateralManager.address
    );
    const ftusdt = await FTUSDT.deployed();
    console.log('FTUSDT deployed at:', ftusdt.address);

    // Save addresses to file
    const fs = require('fs');
    const envContent = `
PRICE_ORACLE_ADDRESS=${priceOracle.address}
COLLATERAL_MANAGER_ADDRESS=${collateralManager.address}
CONTRACT_ADDRESS=${ftusdt.address}
    `.trim();
    
    fs.writeFileSync('../frontend/.env', envContent);
    console.log('Contract addresses saved to .env file');

  } catch (error) {
    console.error('Deployment failed:', error);
    throw error;
  }
};
