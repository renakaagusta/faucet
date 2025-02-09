// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {DeploymentTokenScript} from "./DeploymentToken.s.sol";
import {DeploymentFaucetScript} from "./DeploymentFaucet.s.sol";
import {AddTokenScript} from "./AddToken.s.sol";
import {SetupFaucetScript} from "./SetupFaucet.s.sol";
import {DepositTokenScript} from "./DepositToken.s.sol";

contract DeployAllScript is Script {
    function run() public {
        // Deploy tokens
        DeploymentTokenScript deployTokens = new DeploymentTokenScript();
        deployTokens.run();
        console.log("Tokens deployed");

        // Deploy faucet
        DeploymentFaucetScript deployFaucet = new DeploymentFaucetScript();
        deployFaucet.run();
        console.log("Faucet deployed");

        // // Add tokens to faucet
        AddTokenScript addTokens = new AddTokenScript();
        addTokens.setFaucetAddress(deployFaucet.faucetAddress());
        addTokens.setIdrtAddress(deployTokens.idrtAddress());
        addTokens.setUsdtAddress(deployTokens.usdtAddress());
        addTokens.run();
        console.log("Tokens added to faucet");

        // Setup faucet parameters
        SetupFaucetScript setupFaucet = new SetupFaucetScript();
        setupFaucet.setFaucetAddress(deployFaucet.faucetAddress());
        setupFaucet.run();
        console.log("Faucet parameters set");

        // Deposit initial tokens
        DepositTokenScript depositTokens = new DepositTokenScript();
        depositTokens.setFaucetAddress(deployFaucet.faucetAddress());
        depositTokens.setIdrtAddress(deployTokens.idrtAddress());
        depositTokens.setUsdtAddress(deployTokens.usdtAddress());
        depositTokens.run();
        console.log("Initial tokens deposited");
    }
} 