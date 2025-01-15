/* eslint-disable @typescript-eslint/no-explicit-any */
import React, { createContext, useContext, ReactNode } from 'react';
import { useWeb3 } from '../hooks/useWeb3';

interface Web3ContextType {
  web3: any;
  account: string;
  loading: boolean;
  error: string;
  connect: () => Promise<string>;
}

const Web3Context = createContext<Web3ContextType | undefined>(undefined);

export function Web3Provider({ children }: { children: ReactNode }) {
  const web3State = useWeb3();

  return (
    <Web3Context.Provider value={web3State}>
      {children}
    </Web3Context.Provider>
  );
}

export function useWeb3Context() {
  const context = useContext(Web3Context);
  if (context === undefined) {
    throw new Error('useWeb3Context must be used within a Web3Provider');
  }
  return context;
}
