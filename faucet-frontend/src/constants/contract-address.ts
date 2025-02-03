import dotenv from "dotenv";

dotenv.config();

export const IDRT_ADDRESS = process.env.NEXT_PUBLIC_IDRT_ADDRESS;
export const USDT_ADDRESS = process.env.NEXT_PUBLIC_USDT_ADDRESS;
export const WETH_ADDRESS = process.env.NEXT_PUBLIC_WETH_ADDRESS;

export const FAUCET_ADDRESS = process.env.NEXT_PUBLIC_FAUCET_ADDRESS;