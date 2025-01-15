import React, { useState } from 'react';
import { useWeb3Context } from '../context/Web3Context';
import CollateralManager from './CollateralManager';
import FTUSDTOperations from './FTUSDTOperations';
import FlashTransactions from './FlashTransactions';
import { WalletIcon, ArrowPathIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

const Dashboard: React.FC = () => {
  const { account, connect, loading } = useWeb3Context();
  const [activeTab, setActiveTab] = useState<'collateral' | 'ftusdt' | 'flash'>('collateral');

  if (!account) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-50 to-blue-50">
        <div className="p-8 bg-white rounded-2xl shadow-xl max-w-md w-full mx-4">
          <div className="text-center mb-8">
            <div className="bg-indigo-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
              <WalletIcon className="w-8 h-8 text-indigo-600" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Welcome to FTUSDT Platform</h1>
            <p className="text-gray-600">Connect your wallet to access the dashboard</p>
          </div>
          <button
            onClick={connect}
            disabled={loading}
            className="w-full py-3 px-4 bg-indigo-600 text-white rounded-xl font-medium shadow-lg hover:bg-indigo-700 transition-colors duration-200 disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {loading ? (
              <>
                <ArrowPathIcon className="w-5 h-5 animate-spin" />
                Connecting...
              </>
            ) : (
              <>
                <WalletIcon className="w-5 h-5" />
                Connect Trust Wallet
              </>
            )}
          </button>
          <div className="mt-6 text-center">
            <Link href="/" className="text-indigo-600 hover:text-indigo-700 text-sm font-medium">
              ← Back to Home
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-50 to-blue-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="mb-8">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Dashboard</h1>
              <p className="text-gray-600 mt-1">Manage your FTUSDT tokens and collateral</p>
            </div>
            <div className="bg-white rounded-lg shadow px-4 py-3">
              <p className="text-sm text-gray-600">Connected Account</p>
              <p className="font-mono text-sm text-gray-900 mt-1 break-all">{account}</p>
            </div>
          </div>
        </div>

        <div className="bg-white rounded-2xl shadow-xl overflow-hidden">
          <div className="border-b border-gray-200">
            <div className="px-6">
              <nav className="-mb-px flex space-x-8">
                <button
                  onClick={() => setActiveTab('collateral')}
                  className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors duration-200 ${
                    activeTab === 'collateral'
                      ? 'border-indigo-600 text-indigo-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  Collateral Management
                </button>
                <button
                  onClick={() => setActiveTab('ftusdt')}
                  className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors duration-200 ${
                    activeTab === 'ftusdt'
                      ? 'border-indigo-600 text-indigo-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  FTUSDT Operations
                </button>
                <button
                  onClick={() => setActiveTab('flash')}
                  className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors duration-200 ${
                    activeTab === 'flash'
                      ? 'border-indigo-600 text-indigo-600'
                      : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }`}
                >
                  Flash Transactions
                </button>
              </nav>
            </div>
          </div>

          <div className="p-6">
            {activeTab === 'collateral' && <CollateralManager />}
            {activeTab === 'ftusdt' && <FTUSDTOperations />}
            {activeTab === 'flash' && <FlashTransactions />}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
