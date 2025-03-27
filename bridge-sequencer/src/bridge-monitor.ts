// bridge-monitor.ts
import { config } from 'dotenv';
import { Chain, createPublicClient, createWalletClient, decodeEventLog, formatEther, formatUnits, http, parseAbiItem, PublicClient, WalletClient, type Address, type Log, type GetBlockReturnType } from 'viem';
import { privateKeyToAccount } from 'viem/accounts';
import { TokenBridgeABI } from '../abis/TokenBridgeABI';
import { getBridgeAddress, getChains, getPendingEvents, getTokenAddress, markEventProcessed, setupDatabase, storeEvent } from './db';

// Load environment variables from .env file
config();

// Configuration
const SEQUENCER_PRIVATE_KEY = process.env.SEQUENCER_PRIVATE_KEY || '';
const POLLING_INTERVAL = parseInt(process.env.POLLING_INTERVAL || '15000');

// ABI for the events and functions we need
const bridgeInitiatedAbi = {
    type: 'event',
    name: 'BridgeInitiated',
    inputs: [
        { type: 'bytes32', name: 'messageId', indexed: true },
        { type: 'address', name: 'token', indexed: true },
        { type: 'address', name: 'from', indexed: false },
        { type: 'address', name: 'to', indexed: false },
        { type: 'uint256', name: 'amount', indexed: false },
        { type: 'uint256', name: 'targetChainId', indexed: false }
    ]
} as const;
const tokenAbi = parseAbiItem('function symbol() view returns (string)');

// Add the missing error to the ABI
const extendedABI = [
    ...TokenBridgeABI,
    {
        type: 'error',
        name: 'InvalidSourceChain',
        inputs: [{ type: 'uint256', name: 'sourceChainId' }]
    }
] as const;

async function main() {
    try {
        console.log('Starting bridge monitor...');

        // Setup database
        const db = await setupDatabase();
        console.log('Database initialized');

        const walletClients: WalletClient[] = [];

        const chains = await getChains(db);

        for (const chain of chains) {
            walletClients.push(createWalletClient({
                account: privateKeyToAccount(SEQUENCER_PRIVATE_KEY as `0x${string}`),
                chain: {
                    id: chain.id,
                    name: chain.name,
                    nativeCurrency: {
                        name: 'Ether',
                        symbol: 'ETH',
                        decimals: 18
                    },
                    rpcUrls: {
                        default: { http: [chain.rpcUrl] },
                        public: { http: [chain.rpcUrl] }
                    }
                },
                transport: http(chain.rpcUrl || 'http://127.0.0.1:8545')
            }));
        }

        // Setup viem clients
        const transport = http(chains[0].rpcUrl || 'http://127.0.0.1:8545');

        // Function to process an event
        async function processEvent(log: Log, sourceChain: Chain, targetChain: Chain, targetWalletClient: WalletClient, publicClient: PublicClient, targetBridgeAddress: Address) {
            // Decode the log data
            const event = decodeEventLog({
                abi: [bridgeInitiatedAbi],
                data: log.data,
                topics: log.topics
            });

            const messageId = event.args.messageId as string;
            const token = event.args.token as Address;
            const from = event.args.from as Address;
            const to = event.args.to as Address;
            const amount = event.args.amount as bigint;

            const timestamp = Math.floor(Date.now() / 1000);

            // Store event in database
            await storeEvent(db, {
                messageId,
                token,
                from,
                to,
                amount: amount.toString(),
                blockNumber: Number(log.blockNumber),
                transactionHash: log.transactionHash as string,
                timestamp: Math.floor(Date.now() / 1000)
            });

            console.log('\n======= Bridge Initiated Event Detected =======');
            console.log(`Timestamp: ${new Date(timestamp * 1000).toISOString()}`);
            console.log(`Transaction Hash: ${log.transactionHash}`);
            console.log(`Block Number: ${log.blockNumber}`);
            console.log(`Message ID: ${messageId}`);
            console.log(`Token: ${token}`);
            console.log(`From: ${from}`);
            console.log(`To: ${to}`);
            console.log(`Amount: ${formatUnits(amount, 18)}`); // Assumes 18 decimals, adjust if needed
            console.log('=============================================\n');

            // Call completeTransfer if wallet client is available
            if (targetWalletClient) {
                console.log("Wallet Client: ");
                console.log(await targetWalletClient.getChainId());
                console.log("Target Chain: ", targetChain.rpcUrls.default.http[0], targetWalletClient.chain?.rpcUrls.default.http[0], targetWalletClient.chain?.rpcUrls.public.http[0]);
                console.log("Target Chain ID: ", targetChain.id, targetWalletClient.chain?.id);
                console.log("Target Bridge Address: ", targetBridgeAddress);

                const tokenSymbol = await publicClient.readContract({
                    address: token,
                    abi: [tokenAbi],
                    functionName: 'symbol'
                });

                // Get target chain token address from database
                const targetToken = await getTokenAddress(db, tokenSymbol, targetChain.id);
                if (!targetToken) {
                    throw new Error(`No target chain mapping found for token ${token}`);
                }

                try {
                    console.log(`Attempting to complete transfer for messageId: ${messageId}`);

                    console.log('Debug values:', {
                        targetBridgeAddress,
                        publicClientChainId: publicClient.chain?.id,
                        publicClientChainName: publicClient.chain?.name,
                        publicClientChainRpcUrl: publicClient.chain?.rpcUrls.default.http[0]
                    });

                    const code = await publicClient.getCode({
                        address: targetBridgeAddress
                    });

                    console.log('Code:', code);

                    // Before attempting completeTransfer, verify sequencer
                    const currentSequencer = await publicClient.readContract({
                        address: targetBridgeAddress,
                        abi: TokenBridgeABI,
                        functionName: 'sequencer'
                    });

                    console.log('Current sequencer:', currentSequencer);
                    console.log('Wallet address:', targetWalletClient.account?.address);

                    // Set sequencer if needed
                    if (currentSequencer !== targetWalletClient.account?.address) {
                        console.log('Setting sequencer...');
                        await targetWalletClient.writeContract({
                            address: targetBridgeAddress,
                            abi: TokenBridgeABI,
                            functionName: 'setSequencer',
                            args: [targetWalletClient.account?.address as Address],
                            chain: targetWalletClient.chain,
                            account: targetWalletClient.account?.address as Address
                        });
                    }

                    // Before the transfer, check if token is supported
                    const isTokenSupported = await publicClient.readContract({
                        address: targetBridgeAddress,
                        abi: TokenBridgeABI,
                        functionName: 'supportedTokens',
                        args: [targetToken]
                    });

                    console.log('Is token supported:', isTokenSupported);
                    if (!isTokenSupported) {
                        console.log('Adding token to supported list...');
                        await targetWalletClient.writeContract({
                            address: targetBridgeAddress,
                            abi: TokenBridgeABI,
                            functionName: 'addSupportedToken',
                            args: [targetToken],
                            chain: targetWalletClient.chain,
                            account: targetWalletClient.account?.address as Address
                        });
                    }

                    // Before the transfer, check if message has been processed
                    const isMessageProcessed = await publicClient.readContract({
                        address: targetBridgeAddress,
                        abi: TokenBridgeABI,
                        functionName: 'processedMessages',
                        args: [messageId as `0x${string}`]
                    });

                    console.log('Message ID:', messageId);
                    console.log('Is message processed:', isMessageProcessed);

                    // Check if bridge has enough balance before transfer
                    const tokenContract = {
                        address: targetToken,
                        abi: [{
                            type: 'function',
                            name: 'balanceOf',
                            inputs: [{ type: 'address', name: 'account' }],
                            outputs: [{ type: 'uint256' }],
                            stateMutability: 'view'
                        }]
                    } as const;

                    const bridgeBalance = await publicClient.readContract({
                        ...tokenContract,
                        functionName: 'balanceOf',
                        args: [targetBridgeAddress]
                    });

                    console.log('Bridge balance:', bridgeBalance.toString());
                    console.log('Required amount:', amount.toString());

                    if (bridgeBalance < BigInt(amount)) {
                        throw new Error(`Insufficient bridge balance. Has: ${bridgeBalance}, Needs: ${amount}`);
                    }

                    if (!isMessageProcessed) {
                        // Debug the exact transaction data
                        console.log('Transaction data:', {
                            address: targetBridgeAddress,
                            function: 'completeTransfer',
                            args: [
                                messageId,
                                targetToken,
                                to,
                                amount.toString(),
                                sourceChain.id
                            ]
                        });

                        // Now try the transfer with explicit error logging
                        try {
                            const hash = await targetWalletClient.writeContract({
                                address: targetBridgeAddress,
                                abi: TokenBridgeABI,
                                functionName: 'completeTransfer',
                                args: [messageId as `0x${string}`, targetToken, to, BigInt(amount), BigInt(sourceChain.id)],
                                chain: targetWalletClient.chain,
                                account: targetWalletClient.account?.address as Address
                            });
                            console.log(`Transfer completed. Transaction hash: ${hash}`);
                        } catch (error) {
                            console.error('Complete error:', error);  // Log the full error object
                        }
                    } else {
                        console.log('Message has already been processed');
                        await markEventProcessed(db, messageId);
                    }
                } catch (error) {
                    if (error.message.includes('OnlySequencer')) {
                        console.error(`Error: Only sequencer can call this function. Current sender is not the sequencer`);
                    } else if (error.message.includes('UnsupportedToken')) {
                        console.error(`Error: Token ${targetToken} is not supported`);
                    } else if (error.message.includes('MessageAlreadyProcessed')) {
                        console.error(`Error: Message ${messageId} was already processed`);
                    } else if (error.message.includes('ZeroAmount')) {
                        console.error(`Error: Amount cannot be zero`);
                    } else {
                        console.error(`Failed to complete transfer: ${error}`);
                    }
                }
            }
        }

        // Function to get past events
        async function getPastEvents(publicClient: PublicClient, sourceChain: Chain, walletClient: WalletClient, targetChain: Chain, sourceBridgeAddress: Address, targetBridgeAddress: Address) {
            const startBlock = process.env[`START_${sourceChain.id}_BLOCK`] ? BigInt(process.env[`START_${sourceChain.id}_BLOCK`] as string) : BigInt(0);

            console.log(`Fetching past events from block ${startBlock.toString()}...`);

            const logs = await publicClient.getLogs({
                address: sourceBridgeAddress,
                event: bridgeInitiatedAbi,
                fromBlock: startBlock
            });

            // console.log(`Found ${logs.length} past events`);

            for (const log of logs) {
                await processEvent(log, sourceChain, targetChain, walletClient, publicClient, targetBridgeAddress);
            }
        }


        // Process pending transactions that haven't been completed
        async function processPendingTransactions() {
            const pendingEvents = await getPendingEvents(db);

            // console.log(`Found ${pendingEvents.length} pending transactions to process`);

            for (const event of pendingEvents) {
                const { sourceChainId, targetChainId } = event;

                const targetBridgeAddress = await getBridgeAddress(db, targetChainId);
                if (!targetBridgeAddress) {
                    console.error(`No bridge address found for target chain ${targetChainId}`);
                    continue;
                }

                const targetWalletClient = walletClients.find(client => client.chain?.id === targetChainId);
                if (!targetWalletClient) {
                    console.error(`No wallet client found for target chain ${targetChainId}`);
                    continue;
                }

                try {
                    console.log(`Attempting to complete pending transfer for messageId: ${event.messageId}`);

                    console.log("Source Chain ID: ", sourceChainId);
                    console.log("Target Chain ID: ", targetChainId);
                    console.log("client chain id: ", targetWalletClient.chain?.id);

                    const hash = await targetWalletClient.writeContract({
                        address: targetBridgeAddress as Address,
                        abi: extendedABI,
                        functionName: 'completeTransfer',
                        args: [
                            event.messageId as `0x${string}`,
                            event.token as Address,
                            event.toAddress as Address,
                            BigInt(event.amount),
                            BigInt(sourceChainId)],
                        chain: targetWalletClient.chain,
                        account: targetWalletClient.account?.address as Address
                    });

                    console.log(`Pending transfer completed. Transaction hash: ${hash}`);

                    // Update the database
                    await markEventProcessed(db, event.messageId);
                } catch (error) {
                    console.error(`Failed to complete pending transfer: ${error}`);
                }
            }
        }

        // Process pending transactions periodically
        setInterval(processPendingTransactions, POLLING_INTERVAL * 2);

        chains.forEach(async (sourceChain) => {
            chains.forEach(async (targetChain) => {
                if (sourceChain.id === targetChain.id) {
                    return;
                }

                const SOURCE_BRIDGE_ADDRESS = process.env[`BRIDGE_${sourceChain.id}_ADDRESS`];
                const TARGET_BRIDGE_ADDRESS = process.env[`BRIDGE_${targetChain.id}_ADDRESS`];

                console.log(`Connecting to RPC: ${sourceChain.rpcUrl}`);
                console.log(`Monitoring bridge at: ${SOURCE_BRIDGE_ADDRESS}`);

                const targetPublicClient = createPublicClient({
                    chain: {
                        id: targetChain.id,
                        name: targetChain.name,
                        nativeCurrency: {
                            name: 'Ether',
                            symbol: 'ETH',
                            decimals: 18
                        },
                        rpcUrls: {
                            default: { http: [targetChain.rpcUrl] },
                            public: { http: [targetChain.rpcUrl] }
                        }
                    },
                    transport: http(targetChain.rpcUrl || 'http://127.0.0.1:8545')
                });

                // Setup wallet client if private key is provided
                let targetWalletClient;
                if (SEQUENCER_PRIVATE_KEY) {
                    const account = privateKeyToAccount(SEQUENCER_PRIVATE_KEY as `0x${string}`);
                    targetWalletClient = createWalletClient({
                        account,
                        chain: {
                            id: targetChain.id,
                            name: targetChain.name,
                            nativeCurrency: {
                                name: 'Ether',
                                symbol: 'ETH',
                                decimals: 18
                            },
                            rpcUrls: {
                                default: { http: [targetChain.rpcUrl] },
                                public: { http: [targetChain.rpcUrl] }
                            }
                        },
                        transport: http(
                            targetChain.rpcUrl || 'http://127.0.0.1:8545'
                        )
                    });
                    console.log(`Connected with wallet: ${account.address}`);
                    console.log({
                        account,
                        chain: {
                            id: targetChain.id,
                            name: targetChain.name,
                            nativeCurrency: {
                                name: 'Ether',
                                symbol: 'ETH',
                                decimals: 18
                            },
                            rpcUrls: {
                                default: { http: [targetChain.rpcUrl] },
                                public: { http: [targetChain.rpcUrl] }
                            }
                        },
                        rpcUrl: targetChain.rpcUrl || 'http://127.0.0.1:8545'

                    });
                    console.log("Target Chain ID: ", targetWalletClient.chain?.id);

                    // Verify the chain ID before proceeding
                    const targetChainId = await targetWalletClient.getChainId();
                    if (targetChainId !== targetChain.id) {
                        throw new Error(`Chain ID mismatch. Expected ${targetChain.id}, got ${targetChainId}`);
                    }
                } else {
                    console.warn('No private key provided. Will not be able to complete transfers.');
                }

                // Process past events first
                await getPastEvents(targetPublicClient, {
                    id: sourceChain.id,
                    name: sourceChain.name,
                    nativeCurrency: {
                        name: 'Ether',
                        symbol: 'ETH',
                        decimals: 18
                    },
                    rpcUrls: {
                        default: { http: [sourceChain.rpcUrl] },
                        public: { http: [sourceChain.rpcUrl] }
                    }
                }, targetWalletClient, {
                    id: targetChain.id,
                    name: targetChain.name,
                    nativeCurrency: {
                        name: 'Ether',
                        symbol: 'ETH',
                        decimals: 18
                    },
                    rpcUrls: {
                        default: { http: [targetChain.rpcUrl] },
                        public: { http: [targetChain.rpcUrl] }
                    }
                }, SOURCE_BRIDGE_ADDRESS as Address, TARGET_BRIDGE_ADDRESS as Address);

                // Create a polling mechanism for new events
                console.log(`Starting polling for new events every ${POLLING_INTERVAL}ms...`);
                let lastBlock = await targetPublicClient.getBlockNumber();

                setInterval(async () => {
                    try {
                        const currentBlock = await targetPublicClient.getBlockNumber();

                        if (currentBlock > lastBlock) {
                            // First, check all transactions
                            console.log(`Checking transactions from block ${lastBlock} to ${currentBlock}`);

                            for (let blockNumber = lastBlock; blockNumber <= currentBlock; blockNumber++) {
                                console.log(`Processing block ${blockNumber}`);
                                const block = await targetPublicClient.getBlock({
                                    blockNumber: BigInt(blockNumber),
                                    includeTransactions: true
                                }) as GetBlockReturnType<typeof targetPublicClient.chain, true>;
                                // console.log(`Found ${block.transactions.length} transactions in block ${blockNumber}`);

                                for (const tx of block.transactions) {
                                    // Filter transactions to your bridge contract
                                    console.log("Source Bridge Address: ", SOURCE_BRIDGE_ADDRESS);
                                    console.log(`Transaction to: ${tx.to}`);
                                    if (tx.to?.toLowerCase() === SOURCE_BRIDGE_ADDRESS?.toLowerCase()) {
                                        console.log('\n=== Transaction Details ===');
                                        console.log(`Block Number: ${blockNumber}`);
                                        console.log(`Transaction Hash: ${tx?.hash}`);
                                        console.log(`From Address: ${tx?.from}`);
                                        console.log(`To Address: ${tx?.to}`);
                                        console.log(`Value: ${formatEther(tx?.value)} ETH`);
                                        console.log(`Data: ${tx?.input}`);
                                        console.log('========================\n');
                                    }
                                }
                            }

                            // Then check for events as before
                            console.log(`Checking for new events from block ${lastBlock} to ${currentBlock}`);

                            const logs = await targetPublicClient.getLogs({
                                address: SOURCE_BRIDGE_ADDRESS as Address,
                                event: bridgeInitiatedAbi,
                                fromBlock: BigInt(lastBlock),
                                toBlock: currentBlock
                            });

                            // console.log(`Found ${logs.length} new events`);

                            for (const log of logs) {
                                const decodedLog = decodeEventLog({
                                    abi: [bridgeInitiatedAbi],
                                    data: log.data,
                                    topics: log.topics
                                });

                                console.log('\n=== Transaction Details ===');
                                console.log(`Block Number: ${log.blockNumber}`);
                                console.log(`Transaction Hash: ${log.transactionHash}`);
                                console.log(`Message ID: ${decodedLog.args.messageId}`);
                                console.log(`Token Address: ${decodedLog.args.token}`);
                                console.log(`From Address: ${decodedLog.args.from}`);
                                console.log(`To Address: ${decodedLog.args.to}`);
                                console.log(`Amount: ${formatUnits(decodedLog.args.amount, 18)} tokens`);
                                console.log('========================\n');

                                await processEvent(log, {
                                    id: sourceChain.id,
                                    name: sourceChain.name,
                                    nativeCurrency: {
                                        name: 'Ether',
                                        symbol: 'ETH',
                                        decimals: 18
                                    },
                                    rpcUrls: {
                                        default: { http: [sourceChain.rpcUrl] },
                                        public: { http: [sourceChain.rpcUrl] }
                                    }
                                }, {
                                    id: targetChain.id,
                                    name: targetChain.name,
                                    nativeCurrency: {
                                        name: 'Ether',
                                        symbol: 'ETH',
                                        decimals: 18
                                    },
                                    rpcUrls: {
                                        default: { http: [targetChain.rpcUrl] },
                                        public: { http: [targetChain.rpcUrl] }
                                    }
                                }, targetWalletClient, targetPublicClient, TARGET_BRIDGE_ADDRESS as Address);
                            }

                            lastBlock = currentBlock;
                        }
                    } catch (error) {
                        console.error('Error polling for events:', error);
                    }
                }, POLLING_INTERVAL);

                console.log('Monitor is running for source chain: ', sourceChain.id, ' and target chain: ', targetChain.id, '. Press Ctrl+C to exit.');
            });
        });
    } catch (error) {
        console.error('Error in bridge monitor:', error);
        process.exit(1);
    }
}

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('Shutting down...');
    process.exit(0);
});

main();