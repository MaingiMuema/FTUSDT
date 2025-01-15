const TronWeb = require('tronweb');
const fs = require('fs');
require('dotenv').config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const NETWORK = process.env.NETWORK || 'nile'; // Default to Nile testnet

// Network configurations
const networks = {
    nile: {
        fullHost: 'https://api.nileex.io',
        network_id: '201910292',
    },
    mainnet: {
        fullHost: 'https://api.trongrid.io',
        network_id: '1',
    }
};

// Initialize TronWeb
const tronWeb = new TronWeb({
    fullHost: networks[NETWORK].fullHost,
    privateKey: PRIVATE_KEY
});

async function deployContract(contractName, ...args) {
    try {
        console.log(`Deploying ${contractName}...`);
        
        // Read contract artifact
        const contractPath = `./build/${contractName}.json`;
        const contractJson = JSON.parse(fs.readFileSync(contractPath, 'utf8'));
        
        // Deploy contract
        const contract = await tronWeb.contract().new({
            abi: contractJson.abi,
            bytecode: contractJson.bytecode,
            feeLimit: 1000000000,
            callValue: 0,
            parameters: args
        });

        console.log(`${contractName} deployed at:`, contract.address);
        return contract.address;
    } catch (error) {
        console.error(`Error deploying ${contractName}:`, error);
        throw error;
    }
}

async function main() {
    try {
        // 1. Deploy PriceOracle
        const priceOracleAddress = await deployContract('PriceOracle');
        
        // 2. Deploy CollateralManager
        const collateralManagerAddress = await deployContract('CollateralManager');
        
        // 3. Deploy FTUSDT with initial supply and dependencies
        const initialSupply = 1000000; // 1 million FTUSDT
        const ftusdtAddress = await deployContract(
            'FTUSDT',
            initialSupply,
            priceOracleAddress,
            collateralManagerAddress
        );
        
        // Save addresses to .env file
        const envContent = `
PRICE_ORACLE_ADDRESS=${priceOracleAddress}
COLLATERAL_MANAGER_ADDRESS=${collateralManagerAddress}
CONTRACT_ADDRESS=${ftusdtAddress}
        `.trim();
        
        fs.writeFileSync('../frontend/.env', envContent);
        console.log('Contract addresses saved to .env file');
        
    } catch (error) {
        console.error('Deployment failed:', error);
        process.exit(1);
    }
}

main();
