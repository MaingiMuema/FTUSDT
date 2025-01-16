'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { FiMenu, FiX } from 'react-icons/fi';
import { FaWallet } from 'react-icons/fa';
import { motion, AnimatePresence } from 'framer-motion';

const Navbar = () => {
  const [isOpen, setIsOpen] = useState(false);
  const [walletAddress, setWalletAddress] = useState('');
  const [isConnected, setIsConnected] = useState(false);
  const pathname = usePathname();

  const navItems = [
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Loans', href: '/dashboard/loans' },
    { name: 'Flash Loans', href: '/dashboard/flash-loans' },
    { name: 'Collateral', href: '/dashboard/collateral' },
    { name: 'Insurance', href: '/dashboard/insurance' },
  ];

  const checkWalletConnection = async () => {
    try {
      if (typeof window === 'undefined' || !window.ethereum) {
        setIsConnected(false);
        setWalletAddress('');
        return;
      }

      // Check if Trust Wallet is available
      if (!window.ethereum.isTrust) {
        setIsConnected(false);
        setWalletAddress('');
        return;
      }

      // Get the current account
      const accounts = await window.ethereum.request({
        method: 'eth_accounts'
      });

      if (accounts && accounts.length > 0) {
        const address = accounts[0];
        setWalletAddress(`${address.slice(0, 6)}...${address.slice(-4)}`);
        setIsConnected(true);
      } else {
        setWalletAddress('');
        setIsConnected(false);
      }
    } catch (error) {
      console.error('Error checking wallet connection:', error);
      setWalletAddress('');
      setIsConnected(false);
    }
  };

  const connectWallet = async () => {
    try {
      if (typeof window === 'undefined') return;

      if (!window.ethereum) {
        window.open('https://trustwallet.com', '_blank');
        alert('Please install Trust Wallet');
        return;
      }

      if (!window.ethereum.isTrust) {
        window.open('https://trustwallet.com', '_blank');
        alert('Please use Trust Wallet');
        return;
      }

      // Request account access
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      if (accounts && accounts.length > 0) {
        const address = accounts[0];
        setWalletAddress(`${address.slice(0, 6)}...${address.slice(-4)}`);
        setIsConnected(true);
      }
    } catch (error) {
      console.error('Error connecting wallet:', error);
      setIsConnected(false);
    }
  };

  useEffect(() => {
    checkWalletConnection();
    
    // Set up event listeners for account changes
    const handleAccountsChanged = (accounts: string[]) => {
      if (accounts.length > 0) {
        const address = accounts[0];
        setWalletAddress(`${address.slice(0, 6)}...${address.slice(-4)}`);
        setIsConnected(true);
      } else {
        setWalletAddress('');
        setIsConnected(false);
      }
    };

    if (window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
    }

    // Poll for wallet connection changes (as backup)
    const intervalId = setInterval(checkWalletConnection, 3000);
    
    // Cleanup
    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      }
      clearInterval(intervalId);
    };
  }, []);

  const WalletButton = () => {
    if (isConnected && walletAddress) {
      return (
        <div className="flex items-center px-4 py-2 rounded-md bg-blue-800 text-white">
          <FaWallet className="mr-2" />
          <span>{walletAddress}</span>
        </div>
      );
    }
    
    return (
      <button
        onClick={connectWallet}
        className="flex items-center px-4 py-2 rounded-md bg-blue-600 hover:bg-blue-700 transition-colors duration-200"
      >
        <FaWallet className="mr-2" />
        Connect Wallet
      </button>
    );
  };

  return (
    <nav className="bg-gradient-to-r from-blue-900 to-purple-900 text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo and Brand */}
          <div className="flex-shrink-0">
            <Link href="/" className="flex items-center">
              <span className="text-xl font-bold">FTUSDT</span>
              <span className="ml-2 text-sm text-blue-300">DeFi</span>
            </Link>
          </div>

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center space-x-4">
            {navItems.map((item) => (
              <Link
                key={item.name}
                href={item.href}
                className={`px-3 py-2 rounded-md text-sm font-medium transition-colors duration-200 
                  ${pathname === item.href
                    ? 'bg-blue-700 text-white'
                    : 'text-gray-300 hover:bg-blue-800 hover:text-white'
                }`}
              >
                {item.name}
              </Link>
            ))}
          </div>

          {/* Wallet Connection */}
          <div className="hidden md:flex items-center">
            <WalletButton />
          </div>

          {/* Mobile Menu Button */}
          <div className="md:hidden">
            <button
              onClick={() => setIsOpen(!isOpen)}
              className="p-2 rounded-md hover:bg-blue-800 focus:outline-none"
            >
              {isOpen ? <FiX size={24} /> : <FiMenu size={24} />}
            </button>
          </div>
        </div>
      </div>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="md:hidden"
          >
            <div className="px-2 pt-2 pb-3 space-y-1">
              {navItems.map((item) => (
                <Link
                  key={item.name}
                  href={item.href}
                  className={`block px-3 py-2 rounded-md text-base font-medium ${
                    pathname === item.href
                      ? 'bg-blue-700 text-white'
                      : 'text-gray-300 hover:bg-blue-800 hover:text-white'
                  }`}
                  onClick={() => setIsOpen(false)}
                >
                  {item.name}
                </Link>
              ))}
              <div className="mt-4">
                <WalletButton />
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </nav>
  );
};

export default Navbar;
