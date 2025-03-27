# Cross-Chain Token Bridge

A secure and efficient token bridge system that enables cross-chain token transfers between different EVM-compatible blockchains.

## Overview

This project consists of three main components:

1. **Smart Contracts** (`bridge-contract/`)
   - TokenBridge.sol: The main bridge contract for locking and releasing tokens
   - MockToken.sol: ERC20 token contract for testing

2. **Bridge Sequencer** (`bridge-sequencer/`)
   - Monitors bridge events and processes cross-chain transfers
   - Maintains a SQLite database of bridge events and token mappings

3. **Test Suite**
   - Comprehensive tests for both single-chain and cross-chain scenarios
   - Uses Foundry for testing and deployment

## Architecture

### Smart Contracts

- **TokenBridge**: Handles token locking and releasing
- **Events**: 
  - `BridgeInitiated`: Emitted when tokens are locked for bridging
  - `BridgeCompleted`: Emitted when tokens are released on target chain

### Sequencer

- Monitors source chain for `BridgeInitiated` events
- Validates and processes transfers on target chain
- Maintains database of processed messages to prevent duplicates

## Security

- Message uniqueness enforced through messageId
- Only authorized sequencer can complete transfers
- Token support must be explicitly enabled
- Emergency token rescue functionality for bridge owner

## License

MIT