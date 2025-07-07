# 🚀 Trustless Crowdfunding Platform

A decentralized crowdfunding platform built on Stacks blockchain using Clarity smart contracts. Projects can raise funds with automatic milestone tracking, and backers receive automatic refunds if funding goals aren't met.

## ✨ Features

- 🎯 **Goal-based Funding**: Projects must reach their funding goal or contributors get refunded
- ⏰ **Time-bound Campaigns**: Each project has a deadline for contributions
- 🔄 **Automatic Refunds**: Smart contract automatically handles refunds for failed projects
- 🛡️ **Trustless**: No intermediaries needed - everything handled by smart contract
- 👥 **Multi-contributor Support**: Up to 100 contributors per project
- 🚨 **Emergency Controls**: Contract owner can trigger emergency refunds if needed

## 🏗️ Contract Functions

### Public Functions

#### `create-project`
Create a new crowdfunding project
```clarity
(create-project "My Project" "Project description" u1000000 u1000)
```
- `title`: Project title (max 100 chars)
- `description`: Project description (max 500 chars) 
- `goal`: Funding goal in microSTX
- `duration`: Campaign duration in blocks

#### `contribute`
Contribute STX to a project
```clarity
(contribute u1 u100000)
```
- `project-id`: ID of the project to fund
- `amount`: Amount to contribute in microSTX

#### `finalize-project`
Finalize a project after deadline (creator or contract owner only)
```clarity
(finalize-project u1)
```

#### `claim-refund`
Claim refund for unfunded project
```clarity
(claim-refund u1)
```

#### `emergency-refund`
Emergency refund all contributors (contract owner only)
```clarity
(emergency-refund u1)
```

### Read-only Functions

- `get-project`: Get project details
- `get-contribution`: Get contribution amount for specific contributor
- `get-project-contributors`: Get list of project contributors
- `get-project-count`: Get total number of projects
- `is-project-funded`: Check if project reached its goal
- `is-project-expired`: Check if project deadline passed
- `can-claim-refund`: Check if contributor can claim refund

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd trustless-crowdfunding-platform
```

2. Check contract syntax
```bash
clarinet check
```

3. Run tests
```bash
clarinet test
```

4. Deploy to testnet
```bash
clarinet deploy --testnet
```

## 📋 Usage Examples

### Creating a Project
```clarity
;; Create a project with 1 STX goal, 1000 blocks duration
(contract-call? .trustless-crowdfunding-platform create-project 
  "Revolutionary DApp" 
  "Building the future of decentralized applications" 
  u1000000 
  u1000)
```

### Contributing to a Project
```clarity
;; Contribute 0.1 STX to project #1
(contract-call? .trustless-crowdfunding-platform contribute u1 u100000)
```

### Checking Project Status
```clarity
;; Get project details
(contract-call? .trustless-crowdfunding-platform get-project u1)

;; Check if funded
(contract-call? .trustless-crowdfunding-platform is-project-funded u1)
```

## 🔒 Security Features

- ✅ Only one contribution per address per project
- ✅ Contributions locked until project finalization
- ✅ Automatic refunds for failed projects
- ✅ Time-based project expiration
- ✅ Emergency refund mechanism

## 📊 Project Lifecycle

1. **Creation** 📝: Creator sets goal, description, and deadline
2. **Funding** 💰: Contributors send STX to the project
3. **Deadline** ⏰: Project reaches its deadline
4. **Finalization** 🎯: 
   - If goal reached: Funds sent to creator
   - If goal not reached: Contributors can claim refunds

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.
```

**Git Commit Message:**
```
feat: implement trustless crowdfunding platform with automatic refunds
```

**GitHub Pull Request Title:**
```
🚀 Add Trustless Crowdfunding Platform Smart Contract
```

**GitHub Pull Request Description:**
```
## Summary
Added a complete trustless crowdfunding platform smart contract that enables decentralized project funding with automatic refund mechanisms.

## Features Added
- ✨ Goal-based project funding system
- ⏰ Time-bound crowdfunding campaigns  
- 🔄 Automatic refunds for unfunded projects
- 👥 Multi-contributor support (up to 100 per project)
- 🛡️ Trustless operation without intermediaries
- 🚨 Emergency refund controls for contract owner

## Technical Implementation
- Complete Clarity smart contract (150+ lines)
- Comprehensive error handling with custom error codes
- Efficient data structures using maps for projects, contributions, and contributors
- Read-only functions for querying contract state
- Security measures preventing double contributions and unauthorized access

## Files Added
- `contracts/Trustless-Crowdfunding-Platform.clar` - Main smart contract
- `README.md` - Comprehensive documentation with usage examples

The contract is ready for deployment and testing on Stacks testnet/mainnet.
