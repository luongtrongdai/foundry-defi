// SPDX-License-Identifier: MIT
// 1. Pragma
pragma solidity 0.8.26;

// 2. Imports
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 3. Interfaces, Libraries, Contracts
contract ManualToken is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _totalSupply);
    }
}
