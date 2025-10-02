# 🗳️ Foundry-DAO

A minimal on-chain DAO project built with **Foundry** and **OpenZeppelin Governor**.  
This repo demonstrates how token holders can create proposals, vote, and execute changes on a treasury contract through governance.

---

## 📌 Features
- **Governance Token (GovToken.sol)** – ERC20 token with voting power.
- **Governor (SimpleGovernor.sol)** – Manages proposals, voting, and execution.
- **Timelock (TimeLock.sol)** – Enforces execution delays for approved proposals.
- **Treasury (Treasury.sol)** – A simple contract that stores a value, modifiable only through governance.

---

## ⚙️ Stack
- [Foundry](https://book.getfoundry.sh/) (Solidity development framework)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- Solidity ^0.8.20

---

## 🛠️ Setup & Installation

Clone this repo:
```bash
git clone https://github.com/YOUR-USERNAME/foundry-DAO.git
cd foundry-DAO

forge install

forge build

forge test -vv

forge script script/DeploySimpleDAO.s.sol:DeploySimpleDAO \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY

## Propose

cast send <GOVERNOR_ADDRESS> \
  "propose(address[],uint256[],bytes[],string)" \
  "[<TREASURY_ADDRESS>]" \
  "[0]" \
  "[<CALLDATA>]" \
  "Proposal: Store new value in Treasury" \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL

## Vote

cast send <GOVERNOR_ADDRESS> \
  "castVote(uint256,uint8)" <PROPOSAL_ID> 1 \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
