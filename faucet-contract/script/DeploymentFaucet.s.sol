// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeploymentFaucetScript is Script {
    Faucet public faucet;

    function setUp() public {
    }

    function run() public {     
        address deployer = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast();
        
        faucet = new Faucet();

        console.log("Deployed Faucet at:", address(faucet));

        vm.stopBroadcast();
    }
}
