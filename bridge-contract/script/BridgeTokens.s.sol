// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Script} from "forge-std/Script.sol";
import {TokenBridge} from "../src/TokenBridge.sol";
import {MockToken} from "../src/MockToken.sol";
import {console} from "forge-std/console.sol";

contract BridgeTokens is Script {
    // Chain IDs and RPC URLs arrays
    uint256[] chainIds;
    string[] rpcUrls;

    // Token symbols
    string[] tokenSymbols;

    // Actors
    address deployer;
    address user;
    address recipient;

    // Constants
    uint256 constant BRIDGE_AMOUNT = 1 ether;

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
    }

    function run() public {
        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.selectFork(vm.createFork(rpcUrls[i]));

            vm.startBroadcast(deployer);

            string memory bridgeKey = string.concat(
                "BRIDGE_",
                vm.toString(chainIds[i]),
                "_ADDRESS"
            );
            address bridgeAddress = vm.envAddress(bridgeKey);

            TokenBridge bridge = TokenBridge(bridgeAddress);

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

                    IERC20(tokenAddress).approve(address(bridge), BRIDGE_AMOUNT);

                    bridge.bridgeToken(
                        tokenAddress,
                        recipient,
                        BRIDGE_AMOUNT,
                        chainIds[j]
                    );
                }
            }

            vm.stopBroadcast();
        }
    }
}
