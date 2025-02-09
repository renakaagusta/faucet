// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Faucet {
    event AddToken(address token);
    event UpdateFaucetAmount(uint256 amount);
    event UpdateFaucetCooldown(uint256 cooldown);
    event RequestToken(address requester, address receiver, address token);
    event DepositToken(address depositor, address token, uint256 amount);

    address public owner;
    address[] public availableTokens;

    uint256 public faucetAmount = 0;
    uint256 public faucetCooldown = 0;
    mapping(address => uint256) public lastRequestTime;

    constructor() {
        owner = msg.sender;
    }

    function addToken(address _token) public {
        // require(msg.sender == owner, "Only owner can invoke this method");

        for (uint256 i = 0; i < availableTokens.length; i++) {
            if (_token == availableTokens[i]) {
                revert("The token has already exist");
            }
        }

        availableTokens.push(_token);

        emit AddToken(_token);
    }

    function getAvailableTokensLength() view public returns(uint256) {
        return availableTokens.length;
    }

    function updateFaucetAmount(uint256 _faucetAmount) public {
        require(msg.sender == owner, "Only owner can invoke this method");

        faucetAmount = _faucetAmount;

        emit UpdateFaucetAmount(_faucetAmount);
    }
    
    function updateFaucetCooldown(uint256 _faucetCooldown) public {
        require(msg.sender == owner, "Only owner can invoke this method");

        faucetCooldown = _faucetCooldown;

        emit UpdateFaucetCooldown(_faucetCooldown);
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

    function requestToken(address _receiver, address _token) public {
        // require(faucetAmount > 0, "Faucet amount isn't set yet");
        // require(faucetCooldown > 0, "Faucet cooldown isn't set yet");
        // require(block.timestamp > lastRequestTime[msg.sender], "Please wait until the cooldown time is passed");
        // require(ERC20(_token).balanceOf(address(this)) > faucetAmount, "The amount of balance is not enough");

        bool result = ERC20(_token).transfer(_receiver, faucetAmount);

        require(result, "The transfer process doesn't executed successfully");

        lastRequestTime[msg.sender] = block.timestamp + faucetCooldown;

        emit RequestToken(msg.sender, _receiver, _token);
    }

    function depositToken(address _token, uint256 _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        
        bool exists = false;
        for (uint256 i = 0; i < availableTokens.length; i++) {
            if (_token == availableTokens[i]) {
                exists = true;
                break;
            }
        }
        require(exists, "Token not supported by faucet");

        bool success = ERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Transfer failed");

        emit DepositToken(msg.sender, _token, _amount);
    }


}