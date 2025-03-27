// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract TokenBridge is Ownable {
    address public sequencer;
    
    // Mapping to track processed messages to prevent replay attacks
    mapping(bytes32 => bool) public processedMessages;
    
    // Mapping of supported tokens
    mapping(uint256 => mapping(address => bool)) public supportedTokens;
    
    error UnsupportedToken(address token);
    error ZeroAmount();
    error OnlySequencer(address sender);
    error MessageAlreadyProcessed(bytes32 messageId);
    error InsufficientBalance(uint256 balance, uint256 required);
    
    event BridgeInitiated(
        bytes32 indexed messageId, 
        address indexed token,
        address from, 
        address to, 
        uint256 amount,
        uint256 targetChainId
    );
    
    event BridgeCompleted(
        bytes32 indexed messageId, 
        address indexed token,
        address to, 
        uint256 amount,
        uint256 chainId
    );
    
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    /**
     * @dev Sets the sequencer address
     * @param _sequencer The address of the sequencer
     */
    function setSequencer(address _sequencer) external onlyOwner {
        sequencer = _sequencer;
    }
    
    /**
     * @dev Adds a token to the list of supported tokens
     * @param token The address of the token to add
     */
    function addSupportedToken(uint256 chainId, address token) external onlyOwner {
        supportedTokens[chainId][token] = true;
    }
    
    /**
     * @dev Removes a token from the list of supported tokens
     * @param token The address of the token to remove
     */
    function removeSupportedToken(uint256 targetChainId, address token) external onlyOwner {
        supportedTokens[targetChainId][token] = false;
    }
    
    /**
     * @dev Locks tokens on the source chain and initiates a bridge request
     * @param token The address of the token to bridge
     * @param to The address to receive tokens on the destination chain
     * @param amount The amount of tokens to bridge
     * @return messageId The unique identifier for this bridge request
     */
    function bridgeToken(address token, address to, uint256 amount, uint256 targetChainId) 
        external
        returns (bytes32 messageId) 
    {
        if (!supportedTokens[targetChainId][token]) revert UnsupportedToken(token);
        if (amount == 0) revert ZeroAmount();
        
        // Transfer tokens from sender to this contract
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        
        // Generate a unique message ID
        messageId = keccak256(abi.encodePacked(
            targetChainId, 
            msg.sender, 
            to, 
            token,
            amount, 
            block.timestamp
        ));
        
        // Emit event for the sequencer to pick up
        emit BridgeInitiated(messageId, token, msg.sender, to, amount, targetChainId);
        
        return messageId;
    }
    
    /**
     * @dev Releases tokens on the destination chain to complete a bridge request
     * @param messageId The unique identifier for this bridge request
     * @param token The address of the token to release
     * @param to The address to receive tokens
     * @param amount The amount of tokens to release
     */
    function completeTransfer(bytes32 messageId, address token, address to, uint256 amount, uint256 sourceChainId) 
        external 
    {
        if (msg.sender != sequencer) revert OnlySequencer(msg.sender);
        if (!supportedTokens[sourceChainId][token]) revert UnsupportedToken(token);
        if (processedMessages[messageId]) revert MessageAlreadyProcessed(messageId);
        if (amount == 0) revert ZeroAmount();
        
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance < amount) revert InsufficientBalance(balance, amount);

        // Mark message as processed to prevent replay
        processedMessages[messageId] = true;
        
        // Transfer tokens from this contract to recipient
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transfer(to, amount);
        require(success, "Token transfer failed");
        
        // Emit event for tracking
        emit BridgeCompleted(messageId, token, to, amount, sourceChainId);
    }
    
    /**
     * @dev Emergency function to recover any tokens accidentally sent to the contract
     * @param token The address of the token to recover
     * @param amount The amount to recover
     */
    function rescueTokens(address token, uint256 amount) external onlyOwner {
        IERC20 tokenContract = IERC20(token);
        bool success = tokenContract.transfer(owner(), amount);
        require(success, "Token rescue failed");
    }
}