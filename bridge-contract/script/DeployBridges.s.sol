// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {TokenBridge} from "../src/TokenBridge.sol";
import {MockToken} from "../src/MockToken.sol";
import {console} from "forge-std/console.sol";

contract DeployBridge is Script {
      // Chain IDs and RPC URLs arrays
    uint256[] chainIds;
    string[] rpcUrls;

    // Token symbols
    string[] tokenSymbols;

    // Actors
    address deployer;
    address sequencer;

    // Constants
    uint256 constant INITIAL_SUPPLY = 10000 ether;

    function setUp() public {
        string[] memory chainIdStrs = vm.envString("CHAIN_IDS", ",");
        rpcUrls = vm.envString("RPC_URLS", ",");

        require(
            chainIdStrs.length == rpcUrls.length,
            "Chain IDs and RPC URLs length mismatch"
        );
        require(chainIdStrs.length >= 2, "Need at least 2 chains for testing");

        // Convert chain ID strings to uint256
        chainIds = new uint256[](chainIdStrs.length);
        for (uint i = 0; i < chainIdStrs.length; i++) {
            chainIds[i] = vm.parseUint(chainIdStrs[i]);
            console.log("Chain ID:", chainIds[i]);
            console.log("RPC URL:", rpcUrls[i]);
        }

        tokenSymbols = vm.envString("TOKEN_SYMBOLS", ",");

        deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        sequencer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
    }

    function run() public {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(vm.createFork(rpcUrls[i]));

            vm.startBroadcast(deployer);

            TokenBridge bridge = new TokenBridge(deployer);
            bridge.setSequencer(sequencer);

            console.log("Deploying bridge on chain %s", chainIds[i]);
            console.log("RPC URL: %s", rpcUrls[i]);
            console.log("BRIDGE_%s_ADDRESS=%s", chainIds[i], address(bridge));

            for (uint256 j = 0; j < chainIds.length; j++) {
                if (i == j) {
                    continue;
                }

                for (uint256 k = 0; k < tokenSymbols.length; k++) {
                    string memory tokenKey = string.concat(
                        tokenSymbols[k], 
                        "_", 
                        vm.toString(chainIds[i]),
                        "_ADDRESS"
                    );
                    address tokenAddress = vm.envAddress(tokenKey);

                    // First add token to supported list
                    bridge.addSupportedToken(chainIds[j], tokenAddress);
                    
                    // Then mint tokens to the bridge using the MockToken contract
                    MockToken token = MockToken(tokenAddress);
                    token.mint(address(bridge), INITIAL_SUPPLY);
                }
            }

            vm.stopBroadcast();
        }
    }
} 