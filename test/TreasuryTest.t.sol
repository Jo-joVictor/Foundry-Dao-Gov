// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {GovToken} from "../src/GovToken.sol";
import {Treasury} from "../src/Treasury.sol";
import {SimpleGovernor} from "../src/SimpleGovernor.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";

contract TreasuryTest is Test {
    GovToken token;
    SimpleGovernor governor;
    Treasury treasury;
    TimeLock timelock;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 1_000_000e18;
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 50400;

    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string description;

    function setUp() public {
        // Deploy token
        token = new GovToken();
        
        // Deploy timelock
        timelock = new TimeLock(
            MIN_DELAY,
            new address[](0),
            new address[](0),
            address(this)
        );
        
        // Deploy governor
        governor = new SimpleGovernor(token, timelock);
        
        // Deploy treasury
        treasury = new Treasury();

        // Setup roles
        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.DEFAULT_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, address(this));

        // Transfer treasury to timelock
        treasury.transferOwnership(address(timelock));

        // Give some tokens to USER
        token.transfer(USER, 100e18);
        
        // Delegate
        token.delegate(address(this));
        vm.prank(USER);
        token.delegate(USER);
    }

    function testCantUpdateTreasuryWithoutGovernance() public {
        vm.expectRevert();
        treasury.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 777;
        
        // 1. Propose
        string memory description = "Store 777 in Treasury";
        targets.push(address(treasury));
        values.push(0);
        calldatas.push(abi.encodeWithSignature("store(uint256)", valueToStore));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 2. Wait for voting delay
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 3. Vote
        string memory reason = "I like 777";
        uint8 voteWay = 1; // voting yes
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // Vote with main account
        governor.castVoteWithReason(proposalId, voteWay, reason);

        // 4. Wait for voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        // 5. Queue the proposal
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        // 6. Wait for timelock
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);

        // 7. Execute
        governor.execute(targets, values, calldatas, descriptionHash);

        // 8. Assert
        assertEq(treasury.retrieve(), valueToStore);
        console.log("Treasury value:", treasury.retrieve());
    }

    function testTokenBalance() public view {
        assertEq(token.balanceOf(address(this)), INITIAL_SUPPLY - 100e18);
        assertEq(token.balanceOf(USER), 100e18);
    }

    function testTokenVotes() public view {
        assertEq(token.getVotes(address(this)), INITIAL_SUPPLY - 100e18);
        assertEq(token.getVotes(USER), 100e18);
    }

    function testTreasuryInitialValue() public view {
        assertEq(treasury.retrieve(), 0);
    }

    function testTreasuryOwner() public view {
        assertEq(treasury.owner(), address(timelock));
    }

    function testGovernorSettings() public view {
        assertEq(governor.votingDelay(), VOTING_DELAY);
        assertEq(governor.votingPeriod(), VOTING_PERIOD);
        assertEq(governor.proposalThreshold(), 0);
    }

    function testProposalStates() public {
        string memory description = "Test proposal";
        targets.push(address(treasury));
        values.push(0);
        calldatas.push(abi.encodeWithSignature("store(uint256)", 123));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Should be Pending
        assertTrue(governor.state(proposalId) == IGovernor.ProposalState.Pending);

        // Move to Active
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);
        assertTrue(governor.state(proposalId) == IGovernor.ProposalState.Active);

        // Vote
        governor.castVote(proposalId, 1);

        // Move to Succeeded
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);
        assertTrue(governor.state(proposalId) == IGovernor.ProposalState.Succeeded);

        // Queue
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);
        assertTrue(governor.state(proposalId) == IGovernor.ProposalState.Queued);

        // Execute
        vm.warp(block.timestamp + MIN_DELAY + 1);
        vm.roll(block.number + MIN_DELAY + 1);
        governor.execute(targets, values, calldatas, descriptionHash);
        assertTrue(governor.state(proposalId) == IGovernor.ProposalState.Executed);
    }

    function testFailProposalWithoutTokens() public {
        address noTokens = makeAddr("noTokens");
        
        targets.push(address(treasury));
        values.push(0);
        calldatas.push(abi.encodeWithSignature("store(uint256)", 999));

        vm.prank(noTokens);
        governor.propose(targets, values, calldatas, "Should fail");
    }

    function testMultipleVoters() public {
        // Create more voters
        address voter2 = makeAddr("voter2");
        address voter3 = makeAddr("voter3");
        
        token.transfer(voter2, 50e18);
        token.transfer(voter3, 50e18);

        vm.prank(voter2);
        token.delegate(voter2);
        
        vm.prank(voter3);
        token.delegate(voter3);

        // Move forward to activate delegation
        vm.roll(block.number + 1);

        // Create proposal
        targets.push(address(treasury));
        values.push(0);
        calldatas.push(abi.encodeWithSignature("store(uint256)", 999));
        
        uint256 proposalId = governor.propose(targets, values, calldatas, "Multi-voter test");

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // Multiple people vote
        vm.prank(USER);
        governor.castVote(proposalId, 1);

        vm.prank(voter2);
        governor.castVote(proposalId, 1);

        vm.prank(voter3);
        governor.castVote(proposalId, 0); // Vote against

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Check votes
        (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) = governor.proposalVotes(proposalId);
        
        console.log("For votes:", forVotes);
        console.log("Against votes:", againstVotes);
        console.log("Abstain votes:", abstainVotes);

        assertTrue(forVotes > againstVotes);
    }
} 