// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TransactionRecorder {
    event TransactionRecorded(uint256 index, address from, address to, bytes data);
    event TransactionValidated(uint256 index, bool isSafe);

    struct Transaction {
        address from;
        address to;
        bytes data;
        bool isSafe;
        uint256 timestamp;
    }

    Transaction[] public transactions;
    Transaction[] public validatedTransactions;

    function storeTransaction(address _to, bytes calldata _data) external {
        transactions.push(Transaction(msg.sender, _to, _data, false, block.timestamp));
        emit TransactionRecorded(transactions.length - 1, msg.sender, _to, _data);
    }

    function _validateTransaction(uint256 _index, bool _isSafe) internal {
        Transaction memory transaction = transactions[_index];
        transaction.isSafe = _isSafe;
        validatedTransactions.push(transaction);
        emit TransactionValidated(validatedTransactions.length - 1, _isSafe);
    }

    function getAllTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function getAllValidatedTransactions() external view returns (Transaction[] memory) {
        return validatedTransactions;
    }
}
