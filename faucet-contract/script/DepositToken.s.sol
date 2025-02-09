// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";

contract DepositTokenScript is Script {
    address public faucetAddress;
    address public idrtAddress;
    address public usdtAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        idrtAddress = vm.envAddress("IDRT_ADDRESS");
        usdtAddress = vm.envAddress("USDT_ADDRESS");
    }

        function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }

    function setIdrtAddress(address _idrtAddress) public {
        idrtAddress = _idrtAddress;
    }

    function setUsdtAddress(address _usdtAddress) public {
        usdtAddress = _usdtAddress;
    }

    function run() public {      
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

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