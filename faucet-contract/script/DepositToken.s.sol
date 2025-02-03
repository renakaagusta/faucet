// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract DepositTokenScript is Script {
    function run() public {      
        string memory rpcUrl = vm.envString("RPC_URL");
        string memory privateKey = vm.envString("PRIVATE_KEY");
        
        vm.createSelectFork(rpcUrl);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        address idrtAddress = vm.envAddress("IDRT_ADDRESS");
        address usdtAddress = vm.envAddress("USDT_ADDRESS");

        Faucet faucet = Faucet(faucetAddress);
        IDRT idrt = IDRT(idrtAddress);
        USDT usdt = USDT(usdtAddress);
        
        uint256 depositAmount = 1000 * 10**18;
        
        idrt.mint(msg.sender, depositAmount);
        usdt.mint(msg.sender, depositAmount);

        idrt.approve(faucetAddress, depositAmount);
        usdt.approve(faucetAddress, depositAmount);

        faucet.depositToken(idrtAddress, depositAmount);
        faucet.depositToken(usdtAddress, depositAmount);

        console.log("Deposited", depositAmount, "IDRT and USDT to faucet at", faucetAddress);

        vm.stopBroadcast();
    }
}