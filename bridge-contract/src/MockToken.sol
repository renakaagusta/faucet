// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) 
        ERC20(name, symbol) 
    {
        _mint(msg.sender, 1000000 * 10 ** uint256(decimals()));
    }
    
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}