//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "@Cyfrin/foundry-devops/src/DevOpsTools.sol";
import {Voting} from "../src/voting.sol";

abstract contract CodeConstants {
    uint256 public MOCK_CANDITATE_1 = 123;
    uint256 public MOCK_CANDITATE_2 = 456;

    

    
}

contract SetCanditates is CodeConstants, Script {
    function run() public {
        address mostRecentDeployment = getMostRecentDeployment();
        vm.startBroadcast();
        runSetCanditates(mostRecentDeployment);
        vm.stopBroadcast();
    }

    function runSetCanditates(address mostRecentDeployment) public {
        
        Voting(mostRecentDeployment).setCanditates(MOCK_CANDITATE_1,MOCK_CANDITATE_2);
        
    }

    function getMostRecentDeployment()public view returns(address){
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("Voting", block.chainid);
        return mostRecentDeployment;
    }

    //and need to create a func for get recent deployment and should pass ot from when calling inside the run func
}

contract Vote is CodeConstants, Script {
    function run() public {
        address mostRecentDeployment = getMostRecentDeployment();
        vm.startBroadcast();
        runVote(mostRecentDeployment);
        vm.stopBroadcast();
    }

    function runVote(address mostRecentDeployment) public {
        
        Voting(mostRecentDeployment).vote(MOCK_CANDITATE_1);
        
    }

    function getMostRecentDeployment()public view returns(address){
        address mostRecentDeployment = DevOpsTools.get_most_recent_deployment("Voting", block.chainid);
        return mostRecentDeployment;
    }

    // contract RegisterUpkeep is Script{

    // }

    // contract fundSubscription is Script{

    // }
}
