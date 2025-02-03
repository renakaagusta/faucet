import { ponder } from "ponder:registry";
import { addToken, requestToken } from '../ponder.schema';

ponder.on("Faucet:AddToken", async ({ event, context }) => {
  console.log("Faucet:AddToken", event);
  await context.db.insert(addToken).values({
    id: event.args.token,
    address: event.args.token,
    addedAt: Number(event.block.timestamp),
    lastRequestTime: 0,
    timestamp: Number(event.block.timestamp),
    blockNumber: Number(event.block.number),
    transactionHash: event.transaction.hash,
  });
});

ponder.on("Faucet:RequestToken", async ({ event, context }) => {
  // Create request record
  await context.db.insert(requestToken).values({
    id: `${event.block.number}-${event.transaction.hash}`,
    requester: event.args.requester,
    receiver: event.args.receiver,
    token: event.args.token,
    timestamp: Number(event.block.timestamp),
    blockNumber: Number(event.block.number),
    transactionHash: event.transaction.hash,
  });
});