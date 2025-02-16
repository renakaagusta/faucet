import dotenv from  "dotenv";

dotenv.config();

export const WETH_SUBGRAPH_URL = "https://api.studio.thegraph.com/query/93430/weth/v0.0.1";

export const FAUCET_INDEXER_URL = process.env.NEXT_PUBLIC_FAUCET_INDEXER_URL;
