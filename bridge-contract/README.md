# Deployment

## 1. Deploy Tokens

forge script script/DeployTokens.s.sol --rpc-url $SOURCE_RPC_URL --private-key $PRIVATE_KEY --broadcast

## 2. Deploy Bridges

forge script script/DeployBridges.s.sol --rpc-url $SOURCE_RPC_URL --private-key $PRIVATE_KEY --broadcast

## 3. Bridge Token

forge script script/BridgeTokens.s.sol --rpc-url $SOURCE_RPC_URL --private-key $PRIVATE_KEY --broadcast