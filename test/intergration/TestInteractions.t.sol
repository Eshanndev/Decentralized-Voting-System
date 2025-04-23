// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {SetCandidates, RegisterVoting, Vote} from "../../script/interactions.s.sol";
import {Voting} from "../../src/voting.sol";
import {DevOpsTools} from "@Cyfrin/foundry-devops/src/DevOpsTools.sol";

/**
 * @title TestInteractions
 * @notice Integration test for candidate setting, registration, and voting interaction scripts.
 * @dev This contract tests interactions through separate contracts instead of direct Voting.sol calls.
 */
contract TestInteractions is Test {
    uint256 REGISTERING_OPEN_TIME = 3600;

    SetCandidates setCandidates;
    RegisterVoting registerVoting;
    Vote vote;
    Voting voting;

    /**
     * @notice Deploys interaction contracts and a new Voting contract instance.
     * @dev Uses `vm.prank` to simulate interaction contract deployments as senders.
     */
    function setUp() public {
        setCandidates = new SetCandidates();
        registerVoting = new RegisterVoting();
        vote = new Vote();

        vm.prank(address(setCandidates));
        voting = new Voting();
    }

    /**
     * @notice Tests setting candidates using the interaction contract.
     * @dev Asserts that the voting status is updated to REGISTERING after setting candidates.
     */
    function test_interactions() public {
        setCandidates.runSetCandidates(address(voting));
        assert(Voting.VotingStatus.REGISTERING == voting.getCurrentVotingStatus());
    }

    //TODO:add register and vote interaction tests
}
