import { createConfig } from "ponder";
import { http } from "viem";
import dotenv from "dotenv";
import { FaucetABI } from "./abis/FaucetABI";

dotenv.config();

export default createConfig({
  networks: {
    mainnet: {
      chainId: 1,
      transport: http(process.env.PONDER_RPC_URL_1),
    },
    anvil: {
      chainId: 31337,
      transport: http(process.env.PONDER_RPC_URL_2),
    },
    arbitrumSepolia: {
      chainId: 421614,
      transport: http(process.env.PONDER_RPC_URL_3),
    },
    conduit: {
      chainId: 911867,
      transport: http(process.env.PONDER_RPC_URL_4),
    },
  },
  contracts: {
    Faucet: {
      network: "conduit",
      abi: FaucetABI,
      address: process.env.FAUCET_ADDRESS as `0x${string}`,
      startBlock: process.env.FAUCET_BLOCK as unknown as number,
    },
  },
});
