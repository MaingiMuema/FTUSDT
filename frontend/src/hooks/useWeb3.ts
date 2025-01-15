/* eslint-disable @typescript-eslint/no-explicit-any */
import { useState, useEffect } from 'react';
import Web3 from 'web3';
import { getWeb3, connectWallet, checkAndSwitchNetwork } from '../utils/web3Config';

export const useWeb3 = () => {
  const [web3, setWeb3] = useState<Web3 | null>(null);
  const [account, setAccount] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    initializeWeb3();
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
      window.ethereum.on('chainChanged', () => window.location.reload());
    }
    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      }
    };
  }, []);

  const initializeWeb3 = async () => {
    try {
      const web3Instance = await getWeb3();
      setWeb3(web3Instance);
      const accounts = await web3Instance.eth.getAccounts();
      if (accounts[0]) {
        setAccount(accounts[0]);
      }
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleAccountsChanged = (accounts: string[]) => {
    if (accounts.length > 0) {
      setAccount(accounts[0]);
    } else {
      setAccount('');
    }
  };

  const connect = async () => {
    try {
      setLoading(true);
      setError('');
      await checkAndSwitchNetwork('97'); // BSC Testnet
      const userAccount = await connectWallet();
      setAccount(userAccount);
      return userAccount;
    } catch (err: any) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return {
    web3,
    account,
    loading,
    error,
    connect,
  };
};
