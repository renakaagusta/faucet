// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract DeploymentTokenScript is Script {
    address public idrtAddress;
    address public usdtAddress;
    
    function run() public {      
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();
        
        IDRT idrt = new IDRT("IDRT", "IDRT");

        console.log("Deployed IDRT at:", address(idrt));

        USDT usdt = new USDT("USDT", "USDT");

        console.log("Deployed USDT at:", address(usdt));

        idrtAddress = address(idrt);
        usdtAddress = address(usdt);

        idrt.mint(deployer, 1e27);
        usdt.mint(deployer, 1e27);

        vm.stopBroadcast();
    }
}
