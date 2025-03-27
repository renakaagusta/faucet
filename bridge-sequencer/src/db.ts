import { open } from 'sqlite';
import sqlite3 from 'sqlite3';
import { Database } from 'sqlite';

export async function setupDatabase() {
    const db = await open({
        filename: './bridge_events.db',
        driver: sqlite3.Database
    });

    // Create bridge events table if it doesn't exist
    await db.exec(`
    CREATE TABLE IF NOT EXISTS bridge_events (
      message_id TEXT PRIMARY KEY,
      token TEXT NOT NULL,
      source_chain_id INTEGER NOT NULL,
      target_chain_id INTEGER NOT NULL,
      from_address TEXT NOT NULL,
      to_address TEXT NOT NULL,
      amount TEXT NOT NULL,
      block_number INTEGER NOT NULL,
      transaction_hash TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      processed BOOLEAN NOT NULL DEFAULT 0
    )
    `);

    // Create token mappings table if it doesn't exist
    await db.exec(`
    CREATE TABLE IF NOT EXISTS token_mappings (
      symbol TEXT NOT NULL,
      source_chain_id INTEGER NOT NULL,
      target_chain_id INTEGER NOT NULL,
      token_address TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      PRIMARY KEY (symbol, source_chain_id, target_chain_id)
    )
    `);

    // Create chains table if it doesn't exist
    await db.exec(`
    CREATE TABLE IF NOT EXISTS chains (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      rpc_url TEXT NOT NULL
    )
    `);

    // Create bridges table if it doesn't exist
    await db.exec(`
    CREATE TABLE IF NOT EXISTS bridges (
      id INTEGER PRIMARY KEY,
      chain_id INTEGER NOT NULL,
      address TEXT NOT NULL,
      created_at INTEGER NOT NULL
    )
    `);

    // Insert initial token mappings from environment variables
    const timestamp = Math.floor(Date.now() / 1000);
    const chainIds = process.env.CHAIN_IDS?.split(',').map(Number) || [];
    const chainNames = process.env.CHAIN_NAMES?.split(',') || [];
    const rpcUrls = process.env.RPC_URLS?.split(',') || [];
    const tokenSymbols = process.env.TOKEN_SYMBOLS?.split(',') || [];

    for (const chainId of chainIds) {
        const chainIndex = chainIds.indexOf(chainId);
        const chainName = chainNames[chainIndex];
        const rpcUrl = rpcUrls[chainIndex];
        console.log(`Inserting chain: ${chainName} with id: ${chainId} and rpc url: ${rpcUrl}`);
        await db.run(
            'INSERT OR REPLACE INTO chains (id, name, rpc_url) VALUES (?, ?, ?)',
            [chainId, chainName, rpcUrl]
        );
        await db.run(
            'INSERT OR REPLACE INTO bridges (chain_id, address, created_at) VALUES (?, ?, ?)',
            [chainId, process.env[`BRIDGE_${chainId}_ADDRESS`], timestamp]
        );
    }

    for (const sourceChainId of chainIds) {
        for (const targetChainId of chainIds) {
            for (const tokenSymbol of tokenSymbols) {
                const tokenAddress = process.env[`${tokenSymbol}_${sourceChainId}_ADDRESS`];
                await db.run(
                    'INSERT OR REPLACE INTO token_mappings (symbol, source_chain_id, target_chain_id, token_address, created_at) VALUES (?, ?, ?, ?, ?)',
                    [tokenSymbol, sourceChainId, targetChainId, tokenAddress, timestamp]
                );
            }
        }
    }

    // Log the mappings
    console.log('\n=== Token Mappings ===');
    const mappings = await db.all('SELECT * FROM token_mappings ORDER BY symbol, source_chain_id, target_chain_id');
    for (const mapping of mappings) {
        console.log(`${mapping.symbol} on Chain ${mapping.chain_id}: ${mapping.token_address}`);
    }
    console.log('===================\n');

    return db;
}

export async function storeEvent(db: Database, {
    messageId,
    token,
    from,
    to,
    amount,
    blockNumber,
    transactionHash,
    timestamp
}: {
    messageId: string,
    token: string,
    from: string,
    to: string,
    amount: string,
    blockNumber: number,
    transactionHash: string,
    timestamp: number
}) {
    return await db.run(
        `INSERT OR IGNORE INTO bridge_events 
        (message_id, token, from_address, to_address, amount, block_number, transaction_hash, timestamp, processed) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [messageId, token, from, to, amount, blockNumber, transactionHash, timestamp, false]
    );
}

export async function markEventProcessed(db: Database, messageId: string) {
    return await db.run(
        'UPDATE bridge_events SET processed = ? WHERE message_id = ?',
        [true, messageId]
    );
}

interface BridgeEvent {
    messageId: string;
    token: string;
    sourceChainId: number;
    targetChainId: number;
    fromAddress: string;
    toAddress: string;
    amount: string;
    blockNumber: number;
    transactionHash: string;
    timestamp: number;
    processed: boolean;
}

interface TokenMapping {
    symbol: string;
    sourceChainId: number;
    targetChainId: number;
    tokenAddress: string;
}

interface Chain {
    id: number;
    name: string;
    rpcUrl: string;
}


export async function getPendingEvents(db: Database): Promise<BridgeEvent[]> {
    const events = await db.all<BridgeEvent[]>(`
        SELECT 
            message_id as messageId,
            token,
            source_chain_id as source_chain_id,
            target_chain_id as target_chain_id,
            from_address as from_address,
            to_address as to_address,
            amount,
            block_number as blockNumber,
            transaction_hash as transactionHash,
            timestamp,
            processed
        FROM bridge_events 
        WHERE processed = 0 
        ORDER BY timestamp ASC
    `);
    return events;
}

export async function getTokenAddress(db: Database, token: string, chainId: number) {
    const result = await db.get(
        'SELECT token_address FROM token_mappings WHERE symbol = ? AND source_chain_id = ?',
        [token, chainId]
    );
    return result?.token_address;
}

export async function getBridgeAddress(db: Database, chainId: number) {
    const result = await db.get(
        'SELECT address FROM bridges WHERE chain_id = ?',
        [chainId]
    );
    return result?.address;
}

export async function getChainId(db: Database, chainName: string) {
    const result = await db.get(
        'SELECT id FROM chains WHERE name = ?',
        [chainName]
    );
    return result?.id;
}

export async function getChains(db: Database) {
    const result = await db.all<Chain[]>(`
        SELECT 
            id,
            name,
            rpc_url as rpcUrl
        FROM chains
    `);
    return result;
}