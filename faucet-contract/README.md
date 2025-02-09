# Deployment

## 1. Deployment Faucet

forge script script/DeploymentFaucet.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

## 2. Deployment Token

forge script script/DeploymentToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

## 3. Add Token to Faucet

forge script script/AddToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

## 4. Deposit Token to Faucet

forge script script/DepositToken.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

## 5. Setup Faucet

forge script script/SetupFaucet.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast

Or if you want to do it in a concise way, you can use this command:

forge script script/SetupAll.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
