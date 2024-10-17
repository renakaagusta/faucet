// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract Koentji is ERC20 {
    address public faucetAddress;
    address public ownerAddress;
    
    constructor() ERC20("koentji", "KNJ") {
        ownerAddress = msg.sender;
        _mint(ownerAddress, 10 * (10 ** decimals()));
    }

    function setFaucet(address _faucetAddress) public {
        require(ownerAddress == msg.sender, "Only owner is allowed to invoke this method");
        require(faucetAddress == address(0), "Faucet has been set");

        faucetAddress = _faucetAddress;

        transfer(faucetAddress, 1 * (10 ** decimals()));
    }
}
