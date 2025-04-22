//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Voting} from "../src/voting.sol";

contract DeployVoting is Script {
    Voting voting;

    function run() public returns (Voting) {
        vm.startBroadcast();
        voting = new Voting();
        vm.stopBroadcast();
        //should register an upKeep for this contract programmetically here
        //and fund it using Link
        return voting;
    }
}
