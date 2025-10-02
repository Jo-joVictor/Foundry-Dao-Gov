// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury
 * @dev Simple contract that stores a value and can only be changed through governance
 * This is like Patrick Collins' Box.sol but for a DAO treasury
 */
contract Treasury is Ownable {
    uint256 private value;

    event ValueChanged(uint256 newValue);

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Store a new value in the contract
     * Can only be called by the owner (which will be the Timelock/governance)
     */
    function store(uint256 newValue) public onlyOwner {
        value = newValue;
        emit ValueChanged(newValue);
    }

    /**
     * @dev Retrieve the stored value
     */
    function retrieve() public view returns (uint256) {
        return value;
    }

    /**
     * @dev Get the current version
     */
    function version() public pure returns (uint256) {
        return 1;
    }
}