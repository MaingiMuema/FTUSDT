/* eslint-disable @typescript-eslint/no-unused-vars */
/* eslint-disable @typescript-eslint/no-explicit-any */
import Web3 from 'web3';
import { AbiItem } from 'web3-utils';
import BN from 'bn.js';
import CollateralManagerABI from '../contracts/CollateralManager.json';
import FTUSDT_ABI from '../contracts/FTUSDT.json';

export const COLLATERAL_MANAGER_ADDRESS = process.env.NEXT_PUBLIC_COLLATERAL_MANAGER_ADDRESS;
export const FTUSDT_ADDRESS = process.env.NEXT_PUBLIC_FTUSDT_ADDRESS;

declare global {
  interface Window {
    ethereum?: any;
  }
}

export const getWeb3 = async () => {
  if (typeof window !== 'undefined' && typeof window.ethereum !== 'undefined') {
    try {
      await window.ethereum.request({ method: 'eth_requestAccounts' });
      return new Web3(window.ethereum);
    } catch (error) {
      throw new Error('User denied account access');
    }
  }
  throw new Error('Please install Trust Wallet!');
};

export const getCollateralManagerContract = async (web3: Web3) => {
  if (!COLLATERAL_MANAGER_ADDRESS) {
    throw new Error('Collateral Manager contract address not found');
  }
  return new web3.eth.Contract(
    CollateralManagerABI as AbiItem[],
    COLLATERAL_MANAGER_ADDRESS
  );
};

export const getFTUSDTContract = async (web3: Web3) => {
  if (!FTUSDT_ADDRESS) {
    throw new Error('FTUSDT contract address not found');
  }
  return new web3.eth.Contract(
    FTUSDT_ABI as AbiItem[],
    FTUSDT_ADDRESS
  );
};

export const connectWallet = async () => {
  try {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
    return accounts[0];
  } catch (error) {
    throw new Error('Failed to connect wallet');
  }
};

export const checkAndSwitchNetwork = async (chainId: string) => {
  if (window.ethereum.networkVersion !== chainId) {
    try {
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: Web3.utils.toHex(chainId) }],
      });
    } catch (error: any) {
      throw new Error('Failed to switch network');
    }
  }
};

// Flash Transaction Helper Functions
export const MIN_FLASH_WINDOW = 60; // 1 minute in seconds
export const MAX_FLASH_WINDOW = 31536000; // 365 days in seconds
export const MIN_EXECUTION_DELAY = 60; // 1 minute in seconds
export const MAX_FLASH_AMOUNT = '1000000000000'; // 1M FTUSDT (6 decimals)

export const validateFlashTransaction = (
  amount: string,
  timeWindow: number,
  minExecutionTime: number
): string | null => {
  const amountWei = Web3.utils.toWei(amount, 'ether');
  const amountBN = new BN(amountWei);
  const maxAmountBN = new BN(MAX_FLASH_AMOUNT);
  
  if (amountBN.gt(maxAmountBN)) {
    return 'Amount exceeds maximum allowed';
  }
  
  if (timeWindow < MIN_FLASH_WINDOW || timeWindow > MAX_FLASH_WINDOW) {
    return 'Invalid time window';
  }
  
  if (minExecutionTime < MIN_EXECUTION_DELAY) {
    return 'Execution delay too short';
  }
  
  return null;
};
