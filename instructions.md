# Creating FTUSDT (FLASHTRON USDT) TRC-20 Token

This guide outlines the process of creating the FTUSDT (FLASHTRON USDT) TRC-20 token on the TRON blockchain, making it compatible with wallets like Trust Wallet.

## Step 1: Development Environment Setup

1. **Install Node.js**
   - Download and install from [nodejs.org](https://nodejs.org/)
   - Verify installation:
     ```bash
     node --version
     npm --version
     ```

2. **Install TronWeb**
   ```bash
   npm install tronweb
   ```

3. **TRON Wallet Setup**
   - Install Trust Wallet or TronLink
   - Create a new wallet
   - Fund it with TRX for deployment costs

## Step 2: FTUSDT Smart Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FTUSDT {
    // Token Details
    string public name = "FLASHTRON USDT";
    string public symbol = "FTUSDT";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    // Balances and allowances
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 _totalSupply) {
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}
```

## Step 3: Contract Compilation

1. **Using Remix IDE**
   - Visit [Remix](https://remix.ethereum.org/)
   - Create new file `FTUSDT.sol`
   - Paste the contract code
   - Compile using Solidity Compiler 0.8.x
   - Save the ABI and bytecode

2. **Alternative: TronIDE**
   - Visit [TronIDE](https://www.tronide.io/)
   - Follow similar steps as Remix

## Step 4: Contract Deployment

Create a deployment script (`deploy.js`):

```javascript
const TronWeb = require('tronweb');
const fs = require('fs');

const tronWeb = new TronWeb({
    fullHost: 'https://api.trongrid.io',
    privateKey: 'YOUR_PRIVATE_KEY' // Replace with your private key
});

const contractData = JSON.parse(fs.readFileSync('FTUSDT.json', 'utf8'));

async function deploy() {
    try {
        const contract = await tronWeb.contract().new({
            abi: contractData.abi,
            bytecode: contractData.bytecode,
            feeLimit: 100000000,
            callValue: 0,
            parameters: [1000000] // Initial supply: 1 million FTUSDT
        });

        console.log('Contract deployed at:', contract.address);
    } catch (error) {
        console.error('Deployment failed:', error);
    }
}

deploy();
```

## Step 5: Trust Wallet Integration

1. **After Deployment**
   - Save the contract address
   - Note token details:
     - Name: FLASHTRON USDT
     - Symbol: FTUSDT
     - Decimals: 6
     - Network: TRON

2. **Add to Trust Wallet**
   - Open Trust Wallet
   - Go to "Tokens" → "+" → "Add Custom Token"
   - Select TRON network
   - Enter contract address and token details
   - Click "Save"

## Step 6: Testing

Test token functionality using this script (`test.js`):

```javascript
async function transferTokens(contractAddress, toAddress, amount) {
    const contract = await tronWeb.contract().at(contractAddress);
    try {
        const result = await contract.transfer(toAddress, amount).send();
        console.log('Transfer successful:', result);
    } catch (error) {
        console.error('Transfer failed:', error);
    }
}

// Example: Transfer 1 FTUSDT (remember to multiply by 10^6 for decimals)
// transferTokens('CONTRACT_ADDRESS', 'RECIPIENT_ADDRESS', 1000000);
```

## Security Considerations

1. **Private Key Security**
   - Never share or commit your private key
   - Use environment variables for sensitive data
   - Consider using a hardware wallet for deployment

2. **Smart Contract Safety**
   - Test thoroughly on testnet first
   - Consider a professional audit
   - Implement pause functionality for emergencies

3. **Regulatory Compliance**
   - Research local token regulations
   - Document token purpose and functionality
   - Maintain transparency with users

## Resources

- [TRON Documentation](https://developers.tron.network/)
- [TronWeb GitHub](https://github.com/tronprotocol/tronweb)
- [Trust Wallet Developer Docs](https://developer.trustwallet.com/)

## Support

For technical support or questions about FTUSDT:
- Create an issue in the project repository
- Join the TRON Developer Discord
- Consult the TRON community forums

Last Updated: 2025-01-15
