/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { useState } from 'react';
import { useWeb3Context } from '../context/Web3Context';
import { getCollateralManagerContract } from '../utils/web3Config';
import { ArrowPathIcon, LockClosedIcon } from '@heroicons/react/24/outline';

const CollateralManager: React.FC = () => {
  const { web3, account } = useWeb3Context();
  const [amount, setAmount] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>('');

  const handleTransferCollateral = async () => {
    if (!web3 || !account || !amount) return;
    
    try {
      setLoading(true);
      setError('');
      
      const contract = await getCollateralManagerContract(web3);
      const amountWei = web3.utils.toWei(amount, 'ether');
      
      await contract.methods.transferCollateralFrom(
        account,
        process.env.NEXT_PUBLIC_TREASURY_ADDRESS,
        amountWei
      ).send({ from: account });
      
      setAmount('');
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-6">
        <div className="flex items-center space-x-4">
          <div className="bg-purple-100 p-3 rounded-lg">
            <LockClosedIcon className="w-6 h-6 text-purple-600" />
          </div>
          <div>
            <h3 className="text-lg font-medium text-gray-900">Collateral Management</h3>
            <p className="text-sm text-gray-600 mt-1">
              Lock your collateral to mint FTUSDT tokens
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white rounded-xl border border-gray-200 overflow-hidden">
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-900 mb-4">Transfer Collateral</h3>
          <div className="space-y-4">
            <div>
              <label htmlFor="collateral-amount" className="block text-sm font-medium text-gray-700 mb-1">
                Amount to Lock
              </label>
              <input
                id="collateral-amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-purple-500 focus:border-purple-500 transition-colors duration-200"
                placeholder="0.0"
              />
              <p className="mt-1 text-sm text-gray-500">
                Enter the amount of collateral you want to lock
              </p>
            </div>
            
            <button
              onClick={handleTransferCollateral}
              disabled={loading || !amount}
              className="w-full bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700 disabled:opacity-50 transition-colors duration-200 flex items-center justify-center gap-2"
            >
              {loading ? (
                <>
                  <ArrowPathIcon className="w-5 h-5 animate-spin" />
                  Processing...
                </>
              ) : (
                <>
                  <LockClosedIcon className="w-5 h-5" />
                  Lock Collateral
                </>
              )}
            </button>
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

export default CollateralManager;
