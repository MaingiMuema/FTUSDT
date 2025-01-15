/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useState, useEffect } from 'react';
import { useWeb3Context } from '../context/Web3Context';
import { getFTUSDTContract } from '../utils/web3Config';
import { ArrowPathIcon, BoltIcon, ClockIcon, XMarkIcon, CheckIcon } from '@heroicons/react/24/outline';

interface FlashTx {
  id: string;
  sender: string;
  recipient: string;
  amount: string;
  deadline: number;
  minExecutionTime: number;
  fee: string;
  executed: boolean;
  cancelled: boolean;
  purpose: string;
  requiredApprovals: number;
  currentApprovals: number;
}

interface FlashTxContract {
  sender: string;
  recipient: string;
  amount: string;
  deadline: string;
  minExecutionTime: string;
  fee: string;
  executed: boolean;
  cancelled: boolean;
  purpose: string;
  requiredApprovals: string;
  currentApprovals: string;
}

const FlashTransactions: React.FC = () => {
  const { web3, account } = useWeb3Context();
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');
  const [recipient, setRecipient] = useState<string>('');
  const [amount, setAmount] = useState<string>('');
  const [timeWindow, setTimeWindow] = useState<string>('60'); // Default 1 hour in minutes
  const [minExecutionTime, setMinExecutionTime] = useState<string>('1'); // Default 1 minute
  const [requiredApprovals, setRequiredApprovals] = useState<string>('1');
  const [purpose, setPurpose] = useState<string>('');
  const [userTransactions, setUserTransactions] = useState<FlashTx[]>([]);

  useEffect(() => {
    if (web3 && account) {
      fetchUserTransactions();
    }
  }, [web3, account]);

  const fetchUserTransactions = async () => {
    try {
      const contract = await getFTUSDTContract(web3);
      // Cast the return value to string[] to ensure it's an array
      const txIds = (await contract.methods._userFlashTransactions(account).call()) as string[];
      
      if (!Array.isArray(txIds)) {
        console.error('Expected array of transaction IDs but got:', txIds);
        return;
      }

      const transactions = await Promise.all(
        txIds.map(async (txId: string) => {
          const tx = (await contract.methods._flashTransactions(txId).call()) as FlashTxContract;
          return {
            id: txId,
            sender: tx.sender,
            recipient: tx.recipient,
            amount: web3.utils.fromWei(tx.amount, 'ether'),
            deadline: parseInt(tx.deadline),
            minExecutionTime: parseInt(tx.minExecutionTime),
            fee: web3.utils.fromWei(tx.fee, 'ether'),
            executed: tx.executed,
            cancelled: tx.cancelled,
            purpose: web3.utils.hexToUtf8(tx.purpose),
            requiredApprovals: parseInt(tx.requiredApprovals),
            currentApprovals: parseInt(tx.currentApprovals)
          };
        })
      );

      setUserTransactions(transactions);
    } catch (err: any) {
      console.error('Error fetching transactions:', err);
    }
  };

  const handleCreateFlashTransaction = async () => {
    if (!web3 || !account) return;

    try {
      setLoading(true);
      setError('');

      const contract = await getFTUSDTContract(web3);
      const amountWei = web3.utils.toWei(amount, 'ether');
      const timeWindowSeconds = parseInt(timeWindow) * 60; // Convert minutes to seconds
      const minExecutionTimeSeconds = parseInt(minExecutionTime) * 60;
      const purposeHex = web3.utils.utf8ToHex(purpose);

      await contract.methods
        .createFlashTransaction(
          recipient,
          amountWei,
          timeWindowSeconds,
          minExecutionTimeSeconds,
          requiredApprovals,
          purposeHex
        )
        .send({ from: account });

      // Reset form
      setRecipient('');
      setAmount('');
      setTimeWindow('60');
      setMinExecutionTime('1');
      setRequiredApprovals('1');
      setPurpose('');

      // Refresh transactions
      await fetchUserTransactions();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleExecuteTransaction = async (txId: string) => {
    if (!web3 || !account) return;

    try {
      setLoading(true);
      const contract = await getFTUSDTContract(web3);
      await contract.methods.executeFlashTransaction(txId).send({ from: account });
      await fetchUserTransactions();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleCancelTransaction = async (txId: string) => {
    if (!web3 || !account) return;

    try {
      setLoading(true);
      const contract = await getFTUSDTContract(web3);
      await contract.methods.cancelFlashTransaction(txId).send({ from: account });
      await fetchUserTransactions();
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="bg-gradient-to-r from-yellow-50 to-orange-50 rounded-xl p-6">
        <div className="flex items-center space-x-4">
          <div className="bg-yellow-100 p-3 rounded-lg">
            <BoltIcon className="w-6 h-6 text-yellow-600" />
          </div>
          <div>
            <h3 className="text-lg font-medium text-gray-900">Flash Transactions</h3>
            <p className="text-sm text-gray-600 mt-1">
              Create and manage time-delayed transactions with multi-sig approval
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Create Flash Transaction</h3>
          <div className="space-y-4">
            <div>
              <label htmlFor="recipient" className="block text-sm font-medium text-gray-700 mb-1">
                Recipient Address
              </label>
              <input
                id="recipient"
                type="text"
                value={recipient}
                onChange={(e) => setRecipient(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
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
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
                placeholder="0.0"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label htmlFor="timeWindow" className="block text-sm font-medium text-gray-700 mb-1">
                  Time Window (minutes)
                </label>
                <input
                  id="timeWindow"
                  type="number"
                  value={timeWindow}
                  onChange={(e) => setTimeWindow(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
                  min="1"
                />
              </div>

              <div>
                <label htmlFor="minExecutionTime" className="block text-sm font-medium text-gray-700 mb-1">
                  Min Execution Delay (minutes)
                </label>
                <input
                  id="minExecutionTime"
                  type="number"
                  value={minExecutionTime}
                  onChange={(e) => setMinExecutionTime(e.target.value)}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
                  min="1"
                />
              </div>
            </div>

            <div>
              <label htmlFor="requiredApprovals" className="block text-sm font-medium text-gray-700 mb-1">
                Required Approvals
              </label>
              <input
                id="requiredApprovals"
                type="number"
                value={requiredApprovals}
                onChange={(e) => setRequiredApprovals(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
                min="1"
              />
            </div>

            <div>
              <label htmlFor="purpose" className="block text-sm font-medium text-gray-700 mb-1">
                Purpose
              </label>
              <input
                id="purpose"
                type="text"
                value={purpose}
                onChange={(e) => setPurpose(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-yellow-500 focus:border-yellow-500 transition-colors duration-200"
                placeholder="Transaction purpose..."
              />
            </div>

            <button
              onClick={handleCreateFlashTransaction}
              disabled={loading || !recipient || !amount || !timeWindow || !minExecutionTime || !requiredApprovals}
              className="w-full bg-yellow-600 text-white px-4 py-2 rounded-lg hover:bg-yellow-700 disabled:opacity-50 transition-colors duration-200 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <ArrowPathIcon className="w-5 h-5 animate-spin" />
                  Processing...
                </>
              ) : (
                <>
                  <BoltIcon className="w-5 h-5" />
                  Create Flash Transaction
                </>
              )}
            </button>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Your Flash Transactions</h3>
          <div className="space-y-4">
            {userTransactions.map((tx) => (
              <div
                key={tx.id}
                className="border border-gray-200 rounded-lg p-4 space-y-3"
              >
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-gray-900">
                    To: {tx.recipient.slice(0, 6)}...{tx.recipient.slice(-4)}
                  </span>
                  <div className="flex items-center space-x-2">
                    {tx.executed && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                        <CheckIcon className="w-4 h-4 mr-1" />
                        Executed
                      </span>
                    )}
                    {tx.cancelled && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                        <XMarkIcon className="w-4 h-4 mr-1" />
                        Cancelled
                      </span>
                    )}
                    {!tx.executed && !tx.cancelled && (
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                        <ClockIcon className="w-4 h-4 mr-1" />
                        Pending
                      </span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <p className="text-gray-500">Amount</p>
                    <p className="font-medium">{tx.amount} FTUSDT</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Fee</p>
                    <p className="font-medium">{tx.fee} FTUSDT</p>
                  </div>
                  <div>
                    <p className="text-gray-500">Approvals</p>
                    <p className="font-medium">
                      {tx.currentApprovals}/{tx.requiredApprovals}
                    </p>
                  </div>
                  <div>
                    <p className="text-gray-500">Deadline</p>
                    <p className="font-medium">
                      {new Date(tx.deadline * 1000).toLocaleString()}
                    </p>
                  </div>
                </div>

                {!tx.executed && !tx.cancelled && (
                  <div className="flex space-x-2 mt-2">
                    <button
                      onClick={() => handleExecuteTransaction(tx.id)}
                      disabled={loading || Date.now() < tx.minExecutionTime * 1000}
                      className="flex-1 bg-green-600 text-white px-3 py-1 rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors duration-200 text-sm font-medium"
                    >
                      Execute
                    </button>
                    <button
                      onClick={() => handleCancelTransaction(tx.id)}
                      disabled={loading}
                      className="flex-1 bg-red-600 text-white px-3 py-1 rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors duration-200 text-sm font-medium"
                    >
                      Cancel
                    </button>
                  </div>
                )}

                <div className="text-sm text-gray-500 mt-2">
                  <p>Purpose: {tx.purpose}</p>
                </div>
              </div>
            ))}

            {userTransactions.length === 0 && (
              <p className="text-center text-gray-500 py-4">
                No flash transactions found
              </p>
            )}
          </div>
        </div>
      </div>

      {error && (
        <div className="rounded-lg bg-red-50 p-4 border border-red-200">
          <p className="text-sm text-red-700">{error}</p>
        </div>
      )}
    </div>
  );
};

export default FlashTransactions;
