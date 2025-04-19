//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Voting} from "../../src/voting.sol";
import {DeployVoting} from "../../script/DeployVoting.s.sol";

contract TestVoting is Test {
    address public USER1 = makeAddr("user1");
    uint256 public MOCK_CANDITATE_1 = 123;
    uint256 public MOCK_CANDITATE_2 = 456;

    DeployVoting deployVoting = new DeployVoting();
    Voting voting;

    /*///////////////////////////////////////////////
                  setUp 
    ////////////////////////////////////////////////*/

    function setUp() public {
        voting = deployVoting.run();
    }

    /*///////////////////////////////////////////////
                  Modifiers
    ////////////////////////////////////////////////*/

    modifier userRegistered() {
        vm.prank(USER1);
        voting.registerVoting();
        _;
    }

    /*///////////////////////////////////////////////
                  Test setCanditates
    ////////////////////////////////////////////////*/

    function test_setCanditatesWhenAdminCall() public {
        address admin = voting.getAdmin();
        vm.prank(admin);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
        // this might fail
        //have to set the voting status to CLOSED
    }

    function test_setCanditatesRevertIfSenderIsNotAdmin() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.notAuthorized.selector);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
    }

    /*///////////////////////////////////////////////
                  Test registerVoting
    ////////////////////////////////////////////////*/

    function test_userCanRegisterToVoting() public userRegistered {
        address QulifiedVoter = voting.getQulifiedVoters(0);
        assert(USER1 == QulifiedVoter);
    }

    function test_registerVotingIsRevertingIfUserAlreadyRegistered() public userRegistered {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Voting.alreadyRegistered.selector, USER1));
        voting.registerVoting();
    }
}
