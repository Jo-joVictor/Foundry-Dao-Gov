// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {GovToken} from "../src/GovToken.sol";
import {Treasury} from "../src/Treasury.sol";
import {SimpleGovernor} from "../src/SimpleGovernor.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeploySimpleDAO is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    uint256 public constant VOTING_DELAY = 1; // 1 block
    uint256 public constant VOTING_PERIOD = 50400; // 1 week

    function run() external returns (GovToken, SimpleGovernor, Treasury, TimeLock) {
        vm.startBroadcast();
        
        GovToken token = new GovToken();
        TimeLock timelock = new TimeLock(
            MIN_DELAY,
            new address[](0),
            new address[](0),
            msg.sender
        );
        SimpleGovernor governor = new SimpleGovernor(token, timelock);
        Treasury treasury = new Treasury();

        // Setup roles
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, msg.sender);

        // Transfer treasury ownership to timelock
        treasury.transferOwnership(address(timelock));

        vm.stopBroadcast();

        return (token, governor, treasury, timelock);
    }
}