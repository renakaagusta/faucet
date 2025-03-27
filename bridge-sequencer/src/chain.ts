// src/chains.ts
import { mainnet, arbitrum, polygon, optimism, base, type Chain } from 'viem/chains';

// Map of supported chains
const SUPPORTED_CHAINS: Record<string, Chain> = {
  ethereum: mainnet,
  mainnet: mainnet,
  arbitrum: arbitrum,
  polygon: polygon,
  optimism: optimism,
  base: base
};

// Function to get chain configuration by name
export function getChainByName(name: string): Chain {
  const normalizedName = name.toLowerCase();
  const chain = SUPPORTED_CHAINS[normalizedName];
  
  if (!chain) {
    throw new Error(`Unsupported chain: ${name}. Supported chains are: ${Object.keys(SUPPORTED_CHAINS).join(', ')}`);
  }
  
  return chain;
}

// Export all supported chains
export { mainnet, arbitrum, polygon, optimism, base };