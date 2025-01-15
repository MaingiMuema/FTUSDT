/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useState, useEffect } from 'react';
import { useWeb3Context } from '../context/Web3Context';
import { getFTUSDTContract } from '../utils/web3Config';
import { ArrowPathIcon, PaperAirplaneIcon, CurrencyDollarIcon } from '@heroicons/react/24/outline';

const FTUSDTOperations: React.FC = () => {
  const { web3, account } = useWeb3Context();
  const [balance, setBalance] = useState<string>('0');
  const [transferAmount, setTransferAmount] = useState<string>('');
  const [transferTo, setTransferTo] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  useEffect(() => {
    if (web3 && account) {
      fetchBalance();
    }
  }, [web3, account]);

  const fetchBalance = async () => {
    try {
      const contract = await getFTUSDTContract(web3);
      const balance = await contract.methods.balanceOf(account).call();
      setBalance(web3.utils.fromWei(balance, 'ether'));
    } catch (err: any) {
      setError(err.message);
    }
  };

  const handleTransfer = async () => {
    if (!web3 || !account || !transferAmount || !transferTo) return;

    try {
      setLoading(true);
      setError('');
      const contract = await getFTUSDTContract(web3);
      const amount = web3.utils.toWei(transferAmount, 'ether');

      await contract.methods.transfer(transferTo, amount)
        .send({ from: account });

      setTransferAmount('');
      setTransferTo('');
      await fetchBalance();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleMint = async () => {
    if (!web3 || !account) return;

    try {
      setLoading(true);
      setError('');
      const contract = await getFTUSDTContract(web3);

      await contract.methods.mint()
        .send({ from: account });

      await fetchBalance();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="bg-gradient-to-r from-indigo-50 to-blue-50 rounded-xl p-6">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-medium text-gray-900">Your FTUSDT Balance</h3>
            <p className="text-3xl font-bold text-indigo-600 mt-2">{balance} FTUSDT</p>
          </div>
          <button
            onClick={fetchBalance}
            className="p-2 text-gray-400 hover:text-gray-500 transition-colors duration-200"
          >
            <ArrowPathIcon className="w-5 h-5" />
          </button>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Transfer FTUSDT</h3>
          <div className="space-y-4">
            <div>
              <label htmlFor="recipient" className="block text-sm font-medium text-gray-700 mb-1">
                Recipient Address
              </label>
              <input
                id="recipient"
                type="text"
                value={transferTo}
                onChange={(e) => setTransferTo(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors duration-200"
                placeholder="0x..."
              />
            </div>
            <div>
              <label htmlFor="amount" className="block text-sm font-medium text-gray-700 mb-1">
                Amount
              </label>
              <input
                id="amount"
                type="number"
                value={transferAmount}
                onChange={(e) => setTransferAmount(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 transition-colors duration-200"
                placeholder="0.0"
              />
            </div>
            <button
              onClick={handleTransfer}
              disabled={loading || !transferAmount || !transferTo}
              className="w-full bg-indigo-600 text-white px-4 py-2 rounded-lg hover:bg-indigo-700 disabled:opacity-50 transition-colors duration-200 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <ArrowPathIcon className="w-5 h-5 animate-spin" />
                  Processing...
                </>
              ) : (
                <>
                  <PaperAirplaneIcon className="w-5 h-5" />
                  Transfer
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Mint FTUSDT</h3>
        <button
          onClick={handleMint}
          disabled={loading}
          className="w-full bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors duration-200 flex items-center justify-center gap-2"
        >
          {loading ? (
            <>
              <ArrowPathIcon className="w-5 h-5 animate-spin" />
              Processing...
            </>
          ) : (
            <>
              <CurrencyDollarIcon className="w-5 h-5" />
              Mint FTUSDT
            </>
          )}
        </button>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 p-4 border border-red-200">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}
    </div>
  );
};

export default FTUSDTOperations;
