//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "@Cyfrin/foundry-devops/src/DevOpsTools.sol";
import {Voting} from "../src/voting.sol";
/**
 * @title Code Constants
 * @notice This abstract contract provides mock candidate IDs for testing the voting contract.
 * @dev Used for local or scripting environments to simulate real candidates.
 */

abstract contract CodeConstants {
    uint256 public MOCK_Candidate_1 = 123;
    uint256 public MOCK_Candidate_2 = 456;
}

abstract contract RecentDeployment {
    /**
     * @notice Retrieves the most recently deployed Voting contract address.
     * @return mostRecentDeployment The address of the latest deployed Voting contract.
     */
    function getMostRecentDeployment() public view returns (address) {
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("Voting", block.chainid);
        return mostRecentDeployment;
    }
}
/**
 * @title Set Candidates Script
 * @notice A script to set candidate IDs for the Voting contract.
 * @dev This uses Foundry’s scripting environment to broadcast a transaction setting candidates.
 */

contract SetCandidates is CodeConstants, RecentDeployment, Script {
    /**
     * @notice Executes the script.
     * @dev Broadcasts a transaction that sets mock candidates in the latest deployed Voting contract.
     */
    function run() public {
        address mostRecentDeployment = getMostRecentDeployment();
        vm.startBroadcast(msg.sender);
        runSetCandidates(mostRecentDeployment);
        vm.stopBroadcast();
    }

    /**
     * @notice Calls the `setCandidates` function on the Voting contract.
     * @param mostRecentDeployment The address of the most recently deployed Voting contract.
     */
    function runSetCandidates(address mostRecentDeployment) public {
        Voting(mostRecentDeployment).setCandidates(MOCK_Candidate_1, MOCK_Candidate_2);
    }
}

contract RegisterVoting is RecentDeployment, Script {
    function run() public {
        address mostRecentDeployment = getMostRecentDeployment();
        vm.startBroadcast();
        runRegisterVoting(mostRecentDeployment);
        vm.stopBroadcast();
    }

    function runRegisterVoting(address mostRecentDeployment) public {
        Voting(mostRecentDeployment).registerVoting();
    }
}
/**
 * @title Vote Script
 * @notice A script to cast a vote in the Voting contract.
 * @dev This uses Foundry’s scripting environment to broadcast a vote transaction.
 */

contract Vote is CodeConstants, RecentDeployment, Script {
    /**
     * @notice Executes the vote script.
     * @dev Broadcasts a transaction that votes for a mock candidate in the Voting contract.
     */
    function run() public {
        address mostRecentDeployment = getMostRecentDeployment();
        vm.startBroadcast();
        runVote(mostRecentDeployment);
        vm.stopBroadcast();
    }
    /**
     * @notice Casts a vote for MOCK_Candidate_1.
     * @param mostRecentDeployment The address of the most recently deployed Voting contract.
     */

    function runVote(address mostRecentDeployment) public {
        Voting(mostRecentDeployment).vote(MOCK_Candidate_1);
    }
}
