# Simple DAO Governance

A decentralized autonomous organization (DAO) governance system built with Solidity and Foundry, featuring OpenZeppelin's Governor contract with timelock controls, voting tokens, and treasury management.

## Features

- **ERC20 Voting Tokens**: Governance tokens with delegation and voting power
- **Governor Contract**: Full-featured governance with proposal, voting, and execution
- **Timelock Controller**: Delay between proposal approval and execution for security
- **Treasury Management**: Controlled contract that can only be modified through governance
- **Quorum-based Voting**: 4% quorum requirement for proposal validity
- **One Week Voting Period**: 50,400 blocks for community deliberation
- **No Proposal Threshold**: Any token holder can create proposals
- **ERC20Permit Support**: Gasless approvals via off-chain signatures

## Quick Start

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### Installation

```bash
git clone <your-repo-url>
cd simple-dao
forge install
```

### Environment Setup

Create a `.env` file:
```bash
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
MY_ADDRESS=your_wallet_address
GOVTOKEN_ADDRESS=deployed_gov_token_address
```

## Usage

### Deploy DAO

```bash
# Deploy to local anvil
forge script script/DeploySimpleDAO.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to Sepolia testnet
forge script script/DeploySimpleDAO.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

### Delegate Voting Power

Before participating in governance, delegate your voting power:

```bash
# Delegate to yourself
forge script script/DelegateVotes.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Or using cast
cast send <GOVTOKEN_ADDRESS> "delegate(address)" <YOUR_ADDRESS> --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Create Proposal

```bash
# Example: Propose to store value 777 in Treasury
cast send <GOVERNOR_ADDRESS> "propose(address[],uint256[],bytes[],string)" \
  "[<TREASURY_ADDRESS>]" \
  "[0]" \
  "[$(cast calldata 'store(uint256)' 777)]" \
  "Store 777 in Treasury" \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Vote on Proposal

```bash
# Vote YES (1), NO (0), or ABSTAIN (2)
cast send <GOVERNOR_ADDRESS> "castVote(uint256,uint8)" <PROPOSAL_ID> 1 \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

# Vote with reason
cast send <GOVERNOR_ADDRESS> "castVoteWithReason(uint256,uint8,string)" <PROPOSAL_ID> 1 "I support this" \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Queue Proposal

After voting period ends and proposal succeeds:

```bash
cast send <GOVERNOR_ADDRESS> "queue(address[],uint256[],bytes[],bytes32)" \
  "[<TREASURY_ADDRESS>]" \
  "[0]" \
  "[$(cast calldata 'store(uint256)' 777)]" \
  $(cast keccak "Store 777 in Treasury") \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Execute Proposal

After timelock delay:

```bash
cast send <GOVERNOR_ADDRESS> "execute(address[],uint256[],bytes[],bytes32)" \
  "[<TREASURY_ADDRESS>]" \
  "[0]" \
  "[$(cast calldata 'store(uint256)' 777)]" \
  $(cast keccak "Store 777 in Treasury") \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY
```

### Check Proposal Status

```bash
# Get proposal state (0=Pending, 1=Active, 2=Canceled, 3=Defeated, 4=Succeeded, 5=Queued, 6=Expired, 7=Executed)
cast call <GOVERNOR_ADDRESS> "state(uint256)(uint8)" <PROPOSAL_ID> --rpc-url $SEPOLIA_RPC_URL

# Get proposal votes
cast call <GOVERNOR_ADDRESS> "proposalVotes(uint256)(uint256,uint256,uint256)" <PROPOSAL_ID> --rpc-url $SEPOLIA_RPC_URL

# Check voting power
cast call <GOVTOKEN_ADDRESS> "getVotes(address)(uint256)" <ADDRESS> --rpc-url $SEPOLIA_RPC_URL
```

## Contract Architecture

### Core Contracts

- **GovToken.sol**: ERC20 voting token with delegation and permit functionality
- **SimpleGovernor.sol**: Main governance contract for proposals and voting
- **TimeLock.sol**: Timelock controller for delayed execution
- **Treasury.sol**: Example governed contract that stores a value

### Inheritance Structure

```
GovToken
├── ERC20 (OpenZeppelin)
├── ERC20Permit (OpenZeppelin)
└── ERC20Votes (OpenZeppelin)

SimpleGovernor
├── Governor (OpenZeppelin)
├── GovernorSettings (OpenZeppelin)
├── GovernorCountingSimple (OpenZeppelin)
├── GovernorVotes (OpenZeppelin)
├── GovernorVotesQuorumFraction (OpenZeppelin)
└── GovernorTimelockControl (OpenZeppelin)

TimeLock
└── TimelockController (OpenZeppelin)

Treasury
└── Ownable (OpenZeppelin)
```

### Key Functions

#### GovToken Functions

- `delegate(address)`: Delegate voting power to an address
- `getVotes(address)`: Get current voting power of an address
- `getPastVotes(address, uint256)`: Get voting power at specific block
- `transfer(address, uint256)`: Standard ERC20 transfer
- `permit(...)`: Gasless approval via signature

#### SimpleGovernor Functions

- `propose(address[], uint256[], bytes[], string)`: Create a new proposal
- `castVote(uint256, uint8)`: Vote on a proposal
- `castVoteWithReason(uint256, uint8, string)`: Vote with explanation
- `queue(address[], uint256[], bytes[], bytes32)`: Queue successful proposal
- `execute(address[], uint256[], bytes[], bytes32)`: Execute queued proposal
- `state(uint256)`: Get current proposal state
- `proposalVotes(uint256)`: Get vote counts for proposal
- `votingDelay()`: Get voting delay in blocks
- `votingPeriod()`: Get voting period in blocks
- `quorum(uint256)`: Get quorum requirement at block number

#### TimeLock Functions

- `grantRole(bytes32, address)`: Grant a role (admin only)
- `revokeRole(bytes32, address)`: Revoke a role (admin only)
- `hasRole(bytes32, address)`: Check if address has role
- `getMinDelay()`: Get minimum timelock delay

#### Treasury Functions

- `store(uint256)`: Store a value (owner only)
- `retrieve()`: Get stored value
- `owner()`: Get contract owner (should be TimeLock)

### Deployment Scripts

- **DeploySimpleDAO.s.sol**: Deploys all contracts and configures roles
- **DelegateVotes.s.sol**: Helper script to delegate voting power

## Testing

Run the complete test suite:

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vvv

# Run specific test
forge test --match-test testGovernanceUpdatesBox

# Generate coverage report
forge coverage
```

### Test Coverage

- **Treasury Access Control**: Only governance can modify treasury
- **Full Governance Flow**: Propose, vote, queue, and execute
- **Token Balances**: Verify token distribution
- **Voting Power**: Confirm delegation and voting power
- **Governor Settings**: Validate configuration parameters
- **Proposal States**: Test all proposal state transitions
- **Access Requirements**: Non-token holders cannot propose
- **Multiple Voters**: Verify multi-party voting mechanics

## Governance Configuration

### Parameters

- **Voting Delay**: 1 block (time before voting starts)
- **Voting Period**: 50,400 blocks (approximately 1 week)
- **Proposal Threshold**: 0 tokens (anyone can propose)
- **Quorum**: 4% of total supply
- **Timelock Delay**: 3,600 seconds (1 hour)

### Token Details

**Governance Token (GOV)**
- Name: Governance Token
- Symbol: GOV
- Initial Supply: 1,000,000 GOV
- Decimals: 18
- Standard: ERC20 with Votes and Permit extensions

## Governance Process

### Complete Proposal Lifecycle

1. **Create Proposal**
   - Any token holder can propose
   - Specify targets, values, calldatas, and description
   - Proposal enters Pending state

2. **Voting Delay**
   - Wait 1 block after proposal creation
   - Proposal becomes Active
   - Prevents flash loan attacks

3. **Voting Period**
   - 50,400 blocks for community to vote
   - Token holders vote FOR, AGAINST, or ABSTAIN
   - Voting power based on delegated tokens at proposal creation

4. **Vote Counting**
   - After voting period, tally votes
   - Proposal Succeeds if quorum met and FOR > AGAINST
   - Otherwise proposal Defeated

5. **Queue Proposal**
   - Successful proposals must be queued
   - Enters timelock delay period
   - Proposal state becomes Queued

6. **Timelock Delay**
   - Wait minimum delay (1 hour)
   - Gives community time to react
   - Can exit DAO if malicious proposal passes

7. **Execute Proposal**
   - After timelock, anyone can execute
   - Proposal state becomes Executed
   - Changes take effect

## Security Features

### Timelock Protection

- **Delay Mechanism**: 1 hour minimum between approval and execution
- **Community Exit Window**: Time to withdraw if malicious proposal passes
- **Role-based Access**: Only Governor can propose to Timelock
- **Public Execution**: Anyone can execute after delay

### Role Management

- **Proposer Role**: Only Governor contract
- **Executor Role**: Anyone (address(0))
- **Admin Role**: Revoked after setup for decentralization

### Voting Security

- **Snapshot-based**: Voting power at proposal creation
- **Flash Loan Protection**: Voting delay prevents same-block attacks
- **Delegation System**: Separates token ownership from voting power
- **Quorum Requirement**: 4% participation required

## Gas Optimization

- Uses OpenZeppelin's optimized implementations
- Efficient vote counting with GovernorCountingSimple
- ERC20Votes checkpoint system for historical balances
- Minimal storage in governance contracts

## Common Patterns

### Proposal Encoding

```solidity
// Single action proposal
address[] memory targets = [treasuryAddress];
uint256[] memory values = [0];
bytes[] memory calldatas = [abi.encodeWithSignature("store(uint256)", 777)];
string memory description = "Store 777 in Treasury";
```

### Multi-action Proposal

```solidity
// Multiple actions in one proposal
address[] memory targets = [contract1, contract2];
uint256[] memory values = [0, 0];
bytes[] memory calldatas = [
    abi.encodeWithSignature("function1()"),
    abi.encodeWithSignature("function2(uint256)", 100)
];
```

### Description Hash

```solidity
// Always hash the same description used in propose()
bytes32 descriptionHash = keccak256(abi.encodePacked(description));
```

## Vote Types

- **FOR (1)**: Support the proposal
- **AGAINST (0)**: Oppose the proposal  
- **ABSTAIN (2)**: Participate in quorum without taking a position

## Use Cases

- **Treasury Management**: Control funds through democratic voting
- **Protocol Upgrades**: Approve contract upgrades via governance
- **Parameter Changes**: Adjust protocol settings democratically
- **Grant Distribution**: Allocate funds to projects
- **Emergency Actions**: Community-driven emergency responses

## Extending the DAO

### Adding Governed Contracts

1. Deploy new contract with Ownable
2. Transfer ownership to TimeLock address
3. Create proposals to interact with contract

### Custom Governor Extensions

- Add GovernorTimelockCompound for Compound-style timelock
- Implement custom vote counting mechanisms
- Add proposal cancellation by guardian
- Integrate with additional voting mechanisms

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [Foundry Documentation](https://book.getfoundry.sh/)
- [OpenZeppelin Governor](https://docs.openzeppelin.com/contracts/4.x/api/governance)
- [OpenZeppelin Timelock](https://docs.openzeppelin.com/contracts/4.x/api/governance#TimelockController)
- [ERC20Votes Documentation](https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#ERC20Votes)
- [DAO Governance Best Practices](https://blog.openzeppelin.com/governor-smart-contract)
- [Solidity Documentation](https://docs.soliditylang.org/)
