// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./Koentji.sol";

contract Faucet {
    address public tokenAddress;

    uint256 public faucetAmount = 1000;
    uint256 public faucetCooldown = 1 minutes;
    mapping(address => uint256) public lastRequestTime;

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    function getLastRequestTime() public view returns (uint256) {
        return lastRequestTime[msg.sender];
    }
    
    function getAvailabilityTime() public view returns (uint256) {
        return lastRequestTime[msg.sender] + faucetCooldown;
    }

    function getCooldown() public view returns (uint256) {
        return faucetCooldown;
    }
    
    function getCurrentTimestamp() public view returns (uint256) {
        return block.timestamp;
    }

    function requestToken(address receiver) public {
        require(block.timestamp > lastRequestTime[msg.sender], "Please wait until the cooldown time is passed");
        require(ERC20(tokenAddress).balanceOf(address(this)) > faucetAmount, "The amount of balance is not enough");

        bool result = ERC20(tokenAddress).transfer(receiver, faucetAmount);

        require(result, "The transfer process doesn't executed successfully");

        lastRequestTime[msg.sender] = block.timestamp + faucetCooldown;
    }
}
