// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockToken} from "../src/MockToken.sol";
import {console} from "forge-std/console.sol";

contract DeployTokens is Script {
    // Chain IDs and RPC URLs arrays
    uint256[] chainIds;
    string[] rpcUrls;

    // Token symbols
    string[] tokenSymbols;

    // Actors
    address deployer;

    // Constants
    uint256 constant INITIAL_SUPPLY = 1000 ether;

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

            for (uint256 j = 0; j < tokenSymbols.length; j++) {
                MockToken token = new MockToken(
                    tokenSymbols[j],
                    tokenSymbols[j]
                );
                token.mint(deployer, INITIAL_SUPPLY);
                console.log(
                    "%s_%s_ADDRESS=%s",
                    tokenSymbols[j],
                    chainIds[i],
                    address(token)
                );
            }

            vm.stopBroadcast();
        }
    }
}
