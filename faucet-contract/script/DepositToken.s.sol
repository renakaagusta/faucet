// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Faucet} from "../src/Faucet.sol";
import {Token} from "../src/Token.sol";

contract DepositTokenScript is Script {
    address public faucetAddress;
    address public wethAddress;
    address public usdcAddress;
    address public pepeAddress;
    address public linkAddress;
    address public wbtcAddress;

    function setUp() public {
        faucetAddress = vm.envAddress("FAUCET_ADDRESS");
        wethAddress = vm.envAddress("WETH_ADDRESS");
        usdcAddress = vm.envAddress("USDC_ADDRESS");
        pepeAddress = vm.envAddress("PEPE_ADDRESS");
        linkAddress = vm.envAddress("LINK_ADDRESS");
        wbtcAddress = vm.envAddress("WBTC_ADDRESS");
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

    function setPEPEAddress(address _pepeAddress) public {
        pepeAddress = _pepeAddress;
    }
    
    function setLINKAddress(address _linkAddress) public {
        linkAddress = _linkAddress;
    }

    function setWBTCAddress(address _wbtcAddress) public {
        wbtcAddress = _wbtcAddress;
    }

    function run() public {      
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Faucet faucet = Faucet(faucetAddress);
        Token weth = Token(wethAddress);
        Token usdc = Token(usdcAddress);
        Token pepe = Token(pepeAddress);
        Token link = Token(linkAddress);
        Token wbtc = Token(wbtcAddress);
        
        uint256 depositAmount = 100 * 10**18; // Reduced amount to avoid potential issues
        
        // First add tokens to faucet if not already added
        // try faucet.addToken(wethAddress) {} catch {}
        // try faucet.addToken(usdcAddress) {} catch {}
        // try faucet.addToken(pepeAddress) {} catch {}
        // try faucet.addToken(linkAddress) {} catch {}
        // try faucet.addToken(wbtcAddress) {} catch {}

        // Then approve and deposit
        weth.approve(faucetAddress, depositAmount);
        usdc.approve(faucetAddress, depositAmount);
        pepe.approve(faucetAddress, depositAmount);
        link.approve(faucetAddress, depositAmount);
        wbtc.approve(faucetAddress, depositAmount);

        faucet.depositToken(wethAddress, depositAmount);
        faucet.depositToken(usdcAddress, depositAmount);
        faucet.depositToken(pepeAddress, depositAmount);
        faucet.depositToken(linkAddress, depositAmount);
        faucet.depositToken(wbtcAddress, depositAmount);

        console.log("Deposited tokens to faucet at", faucetAddress);

        vm.stopBroadcast();
    }
}