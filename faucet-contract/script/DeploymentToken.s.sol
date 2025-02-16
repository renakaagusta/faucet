// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Token} from "../src/Token.sol";

contract DeploymentTokenScript is Script {
    address public wethAddress;
    address public usdcAddress;
    
    function run() public {      
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();
        
        Token weth = new Token("WETH", "WETH");

        console.log("Deployed WETH at:", address(weth));

        Token usdc = new Token("USDC", "USDC");

        console.log("Deployed USDC at:", address(usdc));

        wethAddress = address(weth);
        usdcAddress = address(usdc);

        weth.mint(deployer, 1e27);
        usdc.mint(deployer, 1e27);

        vm.stopBroadcast();
    }
}
