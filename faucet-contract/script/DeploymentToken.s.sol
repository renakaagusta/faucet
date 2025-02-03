// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract DeploymentTokenScript is Script {
    function setUp() public {}

    function run() public {      
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();
        
        IDRT idrt = new IDRT();

        console.log("Deployed IDRT at:", address(idrt));

        USDT usdt = new USDT();

        console.log("Deployed USDT at:", address(usdt));

        vm.stopBroadcast();
    }
}
