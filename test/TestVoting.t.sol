//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Voting} from "../src/Voting.sol";
import {DeployVoting} from "../script/DeployVoting.s.sol";

contract TestVoting is Test {

  address USER1 = mkAddr("user1");

  DeployVoting deployVoting = new DeployVoting();
  Voting voting;
  function setUp(){
    voting = deployVoting.run();

  }

  funtion testTegisterVoting ()public {
    vm.prank(USER1);
    voting.registerVoting();
  }
}