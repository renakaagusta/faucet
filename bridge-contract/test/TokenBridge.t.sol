// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TokenBridge} from "../src/TokenBridge.sol";
import {MockToken} from "../src/MockToken.sol";

contract TokenBridgeTest is Test {
    TokenBridge bridge;
    MockToken token;

    uint256 constant SOURCE_CHAIN_ID = 1;
    uint256 constant TARGET_CHAIN_ID = 2;
    
    address owner = address(1);
    address sequencer = address(2);
    address user = address(3);
    address recipient = address(4);
    
    uint256 constant TEST_AMOUNT = 100 ether;
    bytes32 messageId;

    function setUp() public {
        // Deploy token
        token = new MockToken("USDC", "USDC");
        
        // Deploy bridge with owner
        vm.prank(owner);
        bridge = new TokenBridge(owner);
        
        // Set sequencer
        vm.prank(owner);
        bridge.setSequencer(sequencer);
        
        // Add token to supported tokens
        vm.prank(owner);
        bridge.addSupportedToken(TARGET_CHAIN_ID, address(token));
        
        // Fund user with tokens
        token.mint(user, TEST_AMOUNT);

        // Fund bridge with tokens
        token.transfer(address(bridge), TEST_AMOUNT);
    }

    function test_SetSequencer() public {
        assertEq(bridge.sequencer(), sequencer);
        
        address newSequencer = address(5);
        vm.prank(owner);
        bridge.setSequencer(newSequencer);
        
        assertEq(bridge.sequencer(), newSequencer);
    }
    
    function test_AddAndRemoveSupportedToken() public {
        address newToken = address(6);
        
        // Initially not supported
        assertEq(bridge.supportedTokens(TARGET_CHAIN_ID, newToken), false);
        
        // Add token
        vm.prank(owner);
        bridge.addSupportedToken(TARGET_CHAIN_ID, newToken);
        assertEq(bridge.supportedTokens(TARGET_CHAIN_ID, newToken), true);
        
        // Remove token
        vm.prank(owner);
        bridge.removeSupportedToken(TARGET_CHAIN_ID, newToken);
        assertEq(bridge.supportedTokens(TARGET_CHAIN_ID, newToken), false);
    }
    
    function test_BridgeToken() public {
        // Approve tokens
        vm.prank(user);
        token.approve(address(bridge), TEST_AMOUNT);

        uint256 initialBridgeBalance = token.balanceOf(address(bridge));
        uint256 initialUserBalance = token.balanceOf(user);
        // Bridge tokens
        vm.prank(user);
        messageId = bridge.bridgeToken(address(token), recipient, TEST_AMOUNT, TARGET_CHAIN_ID);
        
        // Check token transfer
        assertEq(token.balanceOf(address(bridge)), initialBridgeBalance + TEST_AMOUNT);
        assertEq(token.balanceOf(user), initialUserBalance - TEST_AMOUNT);
        
        // Message ID should not be empty
        assertTrue(messageId != bytes32(0));
    }
    
    function test_CompleteTransfer() public {
        // Setup: Bridge tokens first
        test_BridgeToken();
        
        uint256 initialBridgeBalance = token.balanceOf(address(bridge));
        uint256 initialRecipientBalance = token.balanceOf(recipient);

        // Complete the transfer
        vm.prank(sequencer);
        bridge.completeTransfer(messageId, address(token), recipient, TEST_AMOUNT, TARGET_CHAIN_ID);
        
        // Check token transfer
        assertEq(token.balanceOf(address(bridge)), initialBridgeBalance - TEST_AMOUNT);
        assertEq(token.balanceOf(recipient), initialRecipientBalance + TEST_AMOUNT);
        
        // Message should be marked as processed
        assertTrue(bridge.processedMessages(messageId));
    }
    
    function test_RevertIf_NonSequencerCompletesTransfer() public {
        // Setup: Bridge tokens first
        test_BridgeToken();
        
        // Try to complete transfer as non-sequencer
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(TokenBridge.OnlySequencer.selector, user));
        bridge.completeTransfer(messageId, address(token), recipient, TEST_AMOUNT, TARGET_CHAIN_ID);
    }
    
    function test_RevertIf_MessageAlreadyProcessed() public {
        // Setup: Bridge and complete transfer
        test_CompleteTransfer();
        
        // Try to process the same message again
        vm.prank(sequencer);
        vm.expectRevert(abi.encodeWithSelector(TokenBridge.MessageAlreadyProcessed.selector, messageId));
        bridge.completeTransfer(messageId, address(token), recipient, TEST_AMOUNT, TARGET_CHAIN_ID);
    }
    
    function test_RevertIf_UnsupportedToken() public {
        address unsupportedToken = address(7);
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(TokenBridge.UnsupportedToken.selector, unsupportedToken));
        bridge.bridgeToken(unsupportedToken, recipient, TEST_AMOUNT, TARGET_CHAIN_ID);
    }
    
    function test_RescueTokens() public {
        uint256 initialBridgeBalance = token.balanceOf(address(bridge));
        uint256 initialOwnerBalance = token.balanceOf(owner);

        // Setup: Bridge tokens first
        test_BridgeToken();
        
        // Rescue tokens
        vm.prank(owner);
        bridge.rescueTokens(address(token), TEST_AMOUNT);
  
        // Check token transfer
        assertEq(token.balanceOf(address(bridge)), initialBridgeBalance);
        assertEq(token.balanceOf(owner), initialOwnerBalance + TEST_AMOUNT);
    }
}
