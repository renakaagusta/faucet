// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TokenBridge} from "../src/TokenBridge.sol";
import {MockToken} from "../src/MockToken.sol";
import {console} from "forge-std/Test.sol";

contract TokenBridgeCrossChainTest is Test {
    // Chain IDs and RPC URLs arrays
    uint256[] chainIds;
    string[] rpcUrls;
    
    // Chain-specific fork IDs
    uint256[] forkIds;
    
    // Contracts on each chain
    mapping(uint256 => TokenBridge) bridges;
    mapping(uint256 => MockToken) tokens;
    
    // Actors
    address deployer = makeAddr("deployer");
    address sequencer = makeAddr("sequencer");
    address user = makeAddr("user");
    address recipient = makeAddr("recipient");
    
    // Test parameters
    uint256 constant INITIAL_BALANCE = 1000 ether;
    uint256 constant BRIDGE_AMOUNT = 1 ether;
    bytes32 messageId;
    
    function setUp() public {
        // Load chain IDs and RPC URLs from .env using comma separation
        string[] memory chainIdStrs = vm.envString("CHAIN_IDS", ",");
        rpcUrls = vm.envString("RPC_URLS", ",");
        
        require(chainIdStrs.length == rpcUrls.length, "Chain IDs and RPC URLs length mismatch");
        require(chainIdStrs.length >= 2, "Need at least 2 chains for testing");

        // Convert chain ID strings to uint256
        chainIds = new uint256[](chainIdStrs.length);
        for (uint i = 0; i < chainIdStrs.length; i++) {
            chainIds[i] = vm.parseUint(chainIdStrs[i]);
            console.log("Chain ID:", chainIds[i]);
            console.log("RPC URL:", rpcUrls[i]);
        }

        // Create forks for all chains
        for (uint i = 0; i < chainIds.length; i++) {
            forkIds.push(vm.createFork(rpcUrls[i]));
            
            // Setup each chain
            vm.selectFork(forkIds[i]);
            
            // Fund deployer and users
            vm.deal(deployer, 10 ether);
            vm.deal(user, 10 ether);
            vm.deal(recipient, 10 ether);
            
            // Deploy token on each chain
            vm.startPrank(deployer);
            tokens[chainIds[i]] = new MockToken("USDC", "USDC");
            tokens[chainIds[i]].mint(user, INITIAL_BALANCE);
            vm.stopPrank();
            
            // Deploy and configure bridge on each chain
            vm.startPrank(deployer);
            bridges[chainIds[i]] = new TokenBridge(deployer);
            bridges[chainIds[i]].setSequencer(sequencer);
            
            // Add supported tokens for all possible target chains
            for (uint j = 0; j < chainIds.length; j++) {
                if (i != j) {  // Don't add support for bridging to same chain
                    bridges[chainIds[i]].addSupportedToken(chainIds[j], address(tokens[chainIds[i]]));
                }
            }
            
            tokens[chainIds[i]].transfer(address(bridges[chainIds[i]]), INITIAL_BALANCE);
            vm.stopPrank();
        }
        
        // Start on the first chain for testing
        vm.selectFork(forkIds[0]);
    }
    
    function test_CrossChainBridge() public {
        uint256 sourceChainId = chainIds[0];
        uint256 targetChainId = chainIds[1];
        
        // Step 1: User initiates bridge on source chain
        vm.selectFork(forkIds[0]);
        vm.startPrank(user);
        tokens[sourceChainId].approve(address(bridges[sourceChainId]), BRIDGE_AMOUNT);
        messageId = bridges[sourceChainId].bridgeToken(
            address(tokens[sourceChainId]),
            recipient,
            BRIDGE_AMOUNT,
            targetChainId
        );
        vm.stopPrank();
        
        // Verify source chain state
        assertEq(tokens[sourceChainId].balanceOf(user), INITIAL_BALANCE - BRIDGE_AMOUNT);
        assertGt(tokens[sourceChainId].balanceOf(address(bridges[sourceChainId])), BRIDGE_AMOUNT);
        
        // Step 2: Sequencer completes transfer on target chain
        vm.selectFork(forkIds[1]);
        uint256 recipientInitialBalance = tokens[targetChainId].balanceOf(recipient);
        
        vm.prank(sequencer);
        bridges[targetChainId].completeTransfer(
            messageId,
            address(tokens[targetChainId]),
            recipient,
            BRIDGE_AMOUNT,
            sourceChainId
        );
        
        // Verify target chain state
        assertEq(tokens[targetChainId].balanceOf(recipient), recipientInitialBalance + BRIDGE_AMOUNT);
        assertTrue(bridges[targetChainId].processedMessages(messageId));
        
        // Log success
        console.log("Successfully bridged tokens from chain", sourceChainId, "to chain", targetChainId);
        console.log("Message ID:", uint256(messageId));
        console.log("Recipient received:", tokens[targetChainId].balanceOf(recipient));
    }
    
    function test_RevertIf_DuplicateMessageProcessed() public {
        // First complete a successful bridge
        test_CrossChainBridge();
        
        uint256 sourceChainId = chainIds[0];
        uint256 targetChainId = chainIds[1];
        
        // Try to process the same message ID again
        vm.selectFork(forkIds[1]);
        
        vm.prank(sequencer);
        vm.expectRevert(abi.encodeWithSelector(TokenBridge.MessageAlreadyProcessed.selector, messageId));
        bridges[targetChainId].completeTransfer(
            messageId,
            address(tokens[targetChainId]),
            recipient,
            BRIDGE_AMOUNT,
            sourceChainId
        );
    }
}
