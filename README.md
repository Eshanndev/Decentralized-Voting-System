
# Decentralized Voting System

This is a decentralized voting system built using Solidity, with integration of Chainlink Automation for automatic state transitions. The system allows users to register, vote, and view results for two candidates. It utilizes Forge for testing.

## Features

- **Registration**: Users can register to vote during the registration phase.
- **Voting**: Registered users can vote for one of the two candidates.
- **Chainlink Automation**: Automatically transitions between registration, voting, and result calculation phases.
- **Solidity**: Smart contract written in Solidity.
- **Forge Testing**: Comprehensive tests written using Foundry's Forge framework.

## Installation

1. **Clone the repository**:
    ```bash
    git clone https://github.com/Eshanndev/Decentralized-Voting-System.git
    cd Decentralized-Voting-System
    ```

2. **Install Foundry** (if not already installed):
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3. **Install dependencies**:
    ```bash
    forge install
    ```

## Usage

### Deploying the Contract

1. **Set Candidates**:
    You can set two candidates by running the following script:

    ```bash
    forge script script/SetCandidates.s.sol --broadcast
    ```

### Running Tests

You can run tests using Forge to ensure the contract is functioning correctly:

```bash
forge test
```

## Smart Contract

The `Voting.sol` smart contract provides functionality for:

- **Setting up candidates**.
- **Registering voters**.
- **Casting votes**.
- **Determining the winner**.

### Key Functions

- `setCandidates`: Sets two candidates for the election.
- `registerVoting`: Registers the caller as a voter.
- `vote`: Casts a vote for a candidate.
- `votingResults`: Calculates the winner based on votes.

## Chainlink Automation

Chainlink Automation is used to automatically transition between the registration, voting, and result calculation phases after certain time intervals.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
