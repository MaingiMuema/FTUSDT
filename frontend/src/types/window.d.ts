/* eslint-disable @typescript-eslint/no-explicit-any */
interface Window {
  tronWeb?: {
    defaultAddress: {
      base58: string;
      hex: string;
    };
    ready: boolean;
    fullNode: {
      host: string;
    };
    solidityNode: {
      host: string;
    };
    eventServer: {
      host: string;
    };
    trx: {
      getBalance(address: string): Promise<number>;
      sendTransaction(to: string, amount: number): Promise<any>;
    };
    contract(): {
      at(address: string): Promise<any>;
    };
    on(event: string, callback: (obj: any) => void): void;
    off(event: string, callback: (obj: any) => void): void;
    isConnected(): boolean;
  };
  tronLink?: {
    request(args: { method: string }): Promise<void>;
  };
  ethereum?: {
    isMetaMask?: boolean;
    isTrust?: boolean;
    networkVersion?: string;
    request(args: { method: string; params?: any[] }): Promise<any>;
    on(eventName: string, handler: (accounts: string[]) => void): void;
    removeListener(eventName: string, handler: (accounts: string[]) => void): void;
    selectedAddress: string | null;
    chainId: string;
    isConnected(): boolean;
  };
}
