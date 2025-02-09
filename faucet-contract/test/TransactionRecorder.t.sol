// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import {Test, console} from "forge-std/Test.sol";
import {Faucet} from "../src/Faucet.sol";
import {IDRT} from "../src/IDRT.sol";
import {USDT} from "../src/USDT.sol";
import  "../src/TransactionRecorder.sol";

contract TransactionRecorderTest is Test {
    Faucet public faucet;
    IDRT public idrt;
    USDT public usdt;
    TransactionRecorder public transactionRecorder;

    address anotherAddress;

    event TransactionRecorded(uint256 index, address from, address to, bytes data);

    function setUp() public {
        faucet = new Faucet();
        faucet.updateFaucetAmount(1000);
        faucet.updateFaucetCooldown(60);

        idrt = new IDRT("IDRT", "IDRT");
        usdt = new USDT("USDT", "USDT");

        // faucet.addToken(address(idrt));
        // faucet.addToken(address(usdt));

        transactionRecorder = new TransactionRecorder();

        anotherAddress = vm.addr(2);
    }

    function testTransactionRecorder() public {
        TransactionRecorder.Transaction[] memory transactions = transactionRecorder.getAllTransactions();

        vm.expectEmit(true, true, true, false);
        emit TransactionRecorded(transactions.length + 1, address(this), address(faucet), abi.encodeWithSignature("addToken(uint256,address)", transactions.length, address(this)));

        transactionRecorder.storeTransaction(address(faucet), abi.encodeWithSignature("addToken(address)", address(idrt)));
        
        TransactionRecorder.Transaction[] memory updatedTransactions = transactionRecorder.getAllTransactions();

        assertEq(updatedTransactions.length, transactions.length + 1);
    }

    function testTransactionRecordedExecution() public {
       testTransactionRecorder();

        TransactionRecorder.Transaction[] memory storedTransactions = transactionRecorder.getAllTransactions();

        TransactionRecorder.Transaction memory firstTransaction = storedTransactions[0];

        vm.prank(firstTransaction.from);
        (bool success,) = firstTransaction.to.call(firstTransaction.data);
        
        assertTrue(success, "Transaction execution failed");
    }
}
