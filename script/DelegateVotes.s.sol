// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {GovToken} from "../src/GovToken.sol";

contract DelegateVotes is Script {
    function run() external {
        address delegator = vm.envAddress("MY_ADDRESS"); // your wallet
        address govTokenAddress = vm.envAddress("GOVTOKEN_ADDRESS"); 

        vm.startBroadcast();

        GovToken token = GovToken(govTokenAddress);
        token.delegate(delegator);

        vm.stopBroadcast();
    }
}