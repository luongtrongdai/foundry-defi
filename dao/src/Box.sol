// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Box is Ownable {
    event NumberChange(uint256 number);

    uint256 private s_number;

    constructor() Ownable(msg.sender) {}

    function storeNumber(uint256 _number) public onlyOwner {
        s_number = _number;

        emit NumberChange(_number);
    }

    function getNumber() public view returns (uint256) {
        return s_number;
    }
}
