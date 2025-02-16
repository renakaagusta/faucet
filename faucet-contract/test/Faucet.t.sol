// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/Test.sol";
import {Faucet} from "../src/Faucet.sol";
import {Token} from "../src/Token.sol";

contract FaucetTest is Test {
    Faucet public faucet;
    Token public weth;
    Token public usdc;

    event AddToken(address token);
    event UpdateFaucetAmount(uint256 amount);
    event UpdateFaucetCooldown(uint256 cooldown);
    event RequestToken(address requester, address receiver, address token);
    event DepositToken(address depositor, address token, uint256 amount);

    address anotherAddress;

    function setUp() public {
        faucet = new Faucet();
        faucet.updateFaucetAmount(1 * 10 ** 18);
        faucet.updateFaucetCooldown(60);

        weth = new Token("WETH", "WETH");
        usdc = new Token("USDC", "USDC");

        anotherAddress = vm.addr(2);
    }

    function testOwnerCanAddToken() public {
        vm.expectEmit(false, false, false, true);

        emit AddToken(address(weth));

        faucet.addToken(address(weth));

        bool isExist = false;

        for(uint256 i = 0; i < faucet.getAvailableTokensLength(); i++) {
            if (faucet.availableTokens(i) == address(weth)) {
                isExist = true;
            }
        }

        assertEq(isExist, true);
    }

    function testNonOwnerCanAddToken() public {
        vm.prank(anotherAddress);
        vm.expectRevert(bytes( "Only owner can invoke this method"));

        faucet.addToken(address(weth));

        bool isExist = false;

        for(uint256 i = 0; i < faucet.getAvailableTokensLength(); i++) {
            if (faucet.availableTokens(i) == address(weth)) {
                isExist = true;
            }
        }

        assertEq(isExist, false);
    }

    function testOwnerCanUpdateFaucetAmount() public {
        vm.expectEmit(false, false, false, true);

        uint256 faucetAmount = 100;

        emit UpdateFaucetAmount(faucetAmount);

        faucet.updateFaucetAmount(faucetAmount);

        assertEq(faucet.faucetAmount(), faucetAmount);
    }

    function testNonOwnerCanUpdateFaucetAmount() public {
        vm.prank(anotherAddress);
        vm.expectRevert(bytes( "Only owner can invoke this method"));

        uint256 faucetAmount = 100;

        faucet.updateFaucetAmount(faucetAmount);
    }

    function testOwnerCanUpdateFaucetCooldown() public {
        vm.expectEmit(false, false, false, true);

        uint256 faucetCooldown = 100;

        emit UpdateFaucetCooldown(faucetCooldown);

        faucet.updateFaucetCooldown(faucetCooldown);

        assertEq(faucet.faucetCooldown(), faucetCooldown);
    }

    function testNonOwnerCanUpdateFaucetCooldown() public {
        vm.prank(anotherAddress);
        vm.expectRevert(bytes( "Only owner can invoke this method"));

        uint256 faucetCooldown = 100;

        faucet.updateFaucetCooldown(faucetCooldown);
    }
}
