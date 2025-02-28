// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeploymentTokenScript is Script {
    address public wethAddress;
    address public usdcAddress;
    address public wbtcAddress;
    address public linkAddress;
    address public pepeAddress;
    
    function run() public {      
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();
        
        // Token weth = new Token("WETH", "WETH");

        // console.log("WETH_ADDRESS=%s", address(weth));

        // Token usdc = new Token("USDC", "USDC");

        // console.log("USDC_ADDRESS=%s", address(usdc));

        // wethAddress = address(weth);
        // usdcAddress = address(usdc);

        // weth.mint(deployer, 1e27);
        // usdc.mint(deployer, 1e27);

        wethAddress = 0xb2e9Eabb827b78e2aC66bE17327603778D117d18;
        usdcAddress = 0x02950119C4CCD1993f7938A55B8Ab8384C3CcE4F;
        pepeAddress = 0x7FB2a815Fa88c2096960999EC8371BccDF147874;
        linkAddress = 0x24b1ca69816247Ef9666277714FADA8B1F2D901E;
        wbtcAddress = 0xc2CC2835219A55a27c5184EaAcD9b8fCceF00F85;

        address faucetAddress = 0x213a52377f0a320fb8623f7FFf7B2990719c0f23;

        Token(wethAddress).mint(faucetAddress, 1e27);
        Token(usdcAddress).mint(faucetAddress, 1e27);
        Token(pepeAddress).mint(faucetAddress, 1e27);
        Token(linkAddress).mint(faucetAddress, 1e27);
        Token(wbtcAddress).mint(faucetAddress, 1e27);

        vm.stopBroadcast();
    }
}
