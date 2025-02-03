import { onchainTable } from "ponder";

export const addToken = onchainTable("add_token", (t) => ({
  id: t.text().primaryKey(),
  address: t.text(),
  timestamp: t.integer(),
  blockNumber: t.integer(),
  transactionHash: t.text(),
  lastRequestTime: t.integer(),
}));

export const requestToken = onchainTable("request_token", (t) => ({
  id: t.text().primaryKey(),
  requester: t.text(),
  receiver: t.text(),
  token: t.text(),
  timestamp: t.integer(),
  blockNumber: t.integer(),
  transactionHash: t.text(),
}));

export const faucetConfig = onchainTable("faucet_config", (t) => ({
  id: t.text().primaryKey(),
  amount: t.numeric(),
  cooldown: t.numeric(),
  owner: t.text(),
}));