// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MY_TOKEN is ERC20("MY_TOKEN","MT"){

    function mint(uint _amount) public{
        _mint(msg.sender, _amount);
    }
}