//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {SetCanditates, Vote} from "../../script/interactions.s.sol";
import {Voting} from "../../src/voting.sol";
import {DevOpsTools} from "@Cyfrin/foundry-devops/src/DevOpsTools.sol";

contract TestInteractions is Test {

  uint256 REGISTERING_OPEN_TIME = 3600;
  // address public USER1 = makeAddr("user1");

  SetCanditates setCanditates;
  Vote vote;
  Voting voting;
  
    function setUp()public {
      setCanditates = new SetCanditates();
      vote = new Vote();
      
      vm.prank(address(setCanditates));
      voting = new Voting();
    }

    function test_interactions()public {
      
      setCanditates.runSetCanditates(address(voting));
      assert(Voting.VotingStatus.REGISTERING == voting.getCurrentVotingStatus());

      vm.prank(address(vote));// might change this after making a interaction contract for registering
      voting.registerVoting();

      vm.warp(block.timestamp + REGISTERING_OPEN_TIME + 1);
      vm.roll(block.number + 1);

      (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if (upkeepNeeded) {
            voting.performUpkeep(data);
        }

      
      vote.runVote(address(voting));
    }



    
}
