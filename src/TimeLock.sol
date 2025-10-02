// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title TimeLock
 * @dev Custom TimelockController for the DAO
 * This contract adds a delay between proposal approval and execution
 * Gives the community time to react if a malicious proposal passes
 */
contract TimeLock is TimelockController {
    /**
     * @dev Constructor
     * @param minDelay Minimum delay (in seconds) before execution
     * @param proposers List of addresses that can propose (usually just the Governor)
     * @param executors List of addresses that can execute (address(0) = anyone)
     * @param admin Admin address (should be revoked after setup)
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) TimelockController(minDelay, proposers, executors, admin) {}
}