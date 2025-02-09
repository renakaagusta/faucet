// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    address public owner;

    event Mint(address receiver, uint256 amount);

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        owner = msg.sender;
        // name = _name;
        // symbol = _symbol;
    }

    function mint(address receiver, uint256 amount) public {
        require(msg.sender == owner, "Only owner can invoke this method");
        
        _mint(receiver, amount);

        emit Mint(receiver, amount);
    } 
}
