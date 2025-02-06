import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { http } from 'viem';
import {
  Chain
} from 'wagmi/chains';

const localChain: Chain = {
  id: 31337,
  name: "Anvil",
  nativeCurrency: {
    decimals: 18,
    name: "Anvil Ether",
    symbol: "ETH",
  },
  rpcUrls: {
    default: {
      http: ["http://127.0.0.1:8545"],
    },
    public: {
      http: ["http://127.0.0.1:8545"],
    },
  },
  blockExplorers: {
    default: {
      name: "Ganache Explorer",
      url: "https://ganache.renakaagusta.dev",
    },
  },
  testnet: true,
};



export const wagmiConfig = getDefaultConfig({
  appName: 'RainbowKit',
  projectId: 'c8d08053460bfe0752116d730dc6393b',
  chains: [
    localChain
  ],
});