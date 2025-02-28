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
        // DeploymentFaucetScript deployFaucet = new DeploymentFaucetScript();
        // deployFaucet.run();
        // console.log("Faucet deployed");

        // Add tokens to faucet
        // AddTokenScript addTokens = new AddTokenScript();
        // addTokens.setFaucetAddress(deployFaucet.faucetAddress());
        // addTokens.setLINKAddress(0x24b1ca69816247Ef9666277714FADA8B1F2D901E);
        // addTokens.setWBTCAddress(0xc2CC2835219A55a27c5184EaAcD9b8fCceF00F85);
        // addTokens.setWETHAddress(0xb2e9Eabb827b78e2aC66bE17327603778D117d18);
        // addTokens.setUSDCAddress(0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F);
        // addTokens.setPEPEAddress(0x7FB2a815Fa88c2096960999EC8371BccDF147874);
        // addTokens.setLINKAddress(0x24b1ca69816247Ef9666277714FADA8B1F2D901E);
        // addTokens.setWBTCAddress(0xc2CC2835219A55a27c5184EaAcD9b8fCceF00F85);
        // addTokens.run();
        // console.log("Tokens added to faucet");

        // // Setup faucet parameters
        // SetupFaucetScript setupFaucet = new SetupFaucetScript();
        // setupFaucet.setFaucetAddress(deployFaucet.faucetAddress());
        // setupFaucet.run();
        // console.log("Faucet parameters set");

//   WETH address: 0xb2e9Eabb827b78e2aC66bE17327603778D117d18
//   USDC address: 0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F
//   PEPE address: 0x7FB2a815Fa88c2096960999EC8371BccDF147874
//   LINK address: 0x24b1ca69816247Ef9666277714FADA8B1F2D901E
//   WBTC address: 0xc2CC2835219A55a27c5184EaAcD9b8fCceF00F85

        // Deposit initial tokens
        // DepositTokenScript depositTokens = new DepositTokenScript();
        // depositTokens.setFaucetAddress(deployFaucet.faucetAddress());
        // depositTokens.setWETHAddress(0xb2e9Eabb827b78e2aC66bE17327603778D117d18);
        // depositTokens.setUSDCAddress(0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F);
        // depositTokens.setPEPEAddress(0x7FB2a815Fa88c2096960999EC8371BccDF147874);
        // depositTokens.setLINKAddress(0x24b1ca69816247Ef9666277714FADA8B1F2D901E);
        // depositTokens.setWBTCAddress(0xc2CC2835219A55a27c5184EaAcD9b8fCceF00F85);
        // depositTokens.run();
        // console.log("Initial tokens deposited");
    }
} 