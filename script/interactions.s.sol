//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "@Cyfrin/foundry-devops/src/DevOpsTools.sol";
import {Voting} from "../src/voting.sol";

abstract contract CodeConstants {
    uint256 public MOCK_CANDITATE_1 = 123;
    uint256 public MOCK_CANDITATE_2 = 456;

    address mostRecentDeployment = getRecentDeployment();

    function getRecentDeployment() public view returns (address) {
        return DevOpsTools.get_most_recent_deployment("Voting", block.chainid);
    }
}

contract SetCanditates is CodeConstants, Script {
    function run() public {
        vm.startBroadcast();
        setCanditates();
        vm.stopBroadcast();
    }

    function setCanditates() public {
        
        Voting(mostRecentDeployment).setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
        
    }
}

contract Vote is CodeConstants, Script {
    function run() public {
        vm.startBroadcast();
        vote(MOCK_CANDITATE_1);
        vm.stopBroadcast();
    }

    function vote(uint256 canditateId) public {
        
        Voting(mostRecentDeployment).vote(canditateId);
        
    }

    // contract RegisterUpkeep is Script{

    // }

    // contract fundSubscription is Script{

    // }
}
