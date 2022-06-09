// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ChiCoin is ERC20 {
    constructor () ERC20("CHI Coin", "CHI") {
        _mint(msg.sender, 10000000000 * (10 ** uint256(decimals())));
    }
}
