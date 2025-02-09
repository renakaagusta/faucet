// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";

contract DeploymentFaucetScript is Script {
    address public faucetAddress;

    function run() public {     
        vm.startBroadcast();
        
        Faucet faucetContract = new Faucet();

        console.log("Deployed Faucet at:", address(faucetContract));

        faucetAddress = address(faucetContract);

        vm.stopBroadcast();
    }
}
