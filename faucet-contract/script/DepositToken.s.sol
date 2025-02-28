// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {Token} from "../src/Token.sol";

contract DepositTokenScript is Script {
    address public faucetAddress;
    address public wethAddress;
    address public usdcAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        wethAddress = vm.envAddress("WETH_ADDRESS");
        usdcAddress = vm.envAddress("USDC_ADDRESS");
    }

    function setFaucetAddress(address _faucetAddress) public {
        faucetAddress = _faucetAddress;
    }

    function setWETHAddress(address _wethAddress) public {
        wethAddress = _wethAddress;
    }

    function setUSDCAddress(address _usdcAddress) public {
        usdcAddress = _usdcAddress;
    }

    function run() public {      
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Faucet faucet = Faucet(faucetAddress);
        Token weth = Token(wethAddress);
        Token usdc = Token(usdcAddress);
        
        uint256 depositAmount = 1 * 10**24;
        
        weth.mint(msg.sender, depositAmount);
        usdc.mint(msg.sender, depositAmount);

        weth.approve(faucetAddress, depositAmount);
        usdc.approve(faucetAddress, depositAmount);

        faucet.depositToken(wethAddress, depositAmount);
        faucet.depositToken(usdcAddress, depositAmount);

        console.log("Deposited", depositAmount, "WETH and USDC to faucet at", faucetAddress);

        vm.stopBroadcast();
    }
}