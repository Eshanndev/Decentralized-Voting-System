//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Voting} from "../../src/voting.sol";
import {DeployVoting} from "../../script/DeployVoting.s.sol";

contract TestVoting is Test {
    address public USER1 = makeAddr("user1");
    uint256 public MOCK_CANDITATE_1 = 123;
    uint256 public MOCK_CANDITATE_2 = 456;
    uint256 REGISTERING_OPEN_TIME = 3600;
    


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

    modifier canditatesSet(){
        address admin = voting.getAdmin();
        vm.prank(admin);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
        _;
    }

    modifier registrationTimePassed(){
        vm.warp(block.timestamp + REGISTERING_OPEN_TIME + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier performUpkeepRanAndVotingOpened(){
        (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if(upkeepNeeded){
            voting.performUpkeep(data);
        }
        _;
    }

    modifier voteForCanditate_1(){
        _;
        voting.vote(MOCK_CANDITATE_1);
    }

    modifier performUpkeepRanAndVotingCounting(){
        (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if(upkeepNeeded){
            voting.performUpkeep(data);
        }
        _;
    }

    // modifier VotingProcessDone(){
    //     _;
    // }

    /*///////////////////////////////////////////////
                  Test State variables
    ////////////////////////////////////////////////*/

    function test_votingStatusInitializedAsEnded()public view {
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    

    /*///////////////////////////////////////////////
                  Test setCanditates
    ////////////////////////////////////////////////*/

    function test_setCanditatesWhenAdminCall() public canditatesSet{
        
        
    }

    function test_setCanditatesRevertIfSenderIsNotAdmin() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.notAuthorized.selector);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
    }

    /*///////////////////////////////////////////////
                  Test registerVoting
    ////////////////////////////////////////////////*/

    function test_userCanRegisterToVoting() public canditatesSet userRegistered {
        address QulifiedVoter = voting.getQulifiedVoters(0);
        assert(USER1 == QulifiedVoter);
    }

    function test_registerVotingIsRevertingIfUserAlreadyRegistered() public canditatesSet userRegistered {
        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyRegistered.selector);
        voting.registerVoting();
    }

    function test_isRegisteredMappingUpdateWhenRegister()public canditatesSet userRegistered{
        bool isRegistered = voting.isRegistered(USER1);
        assert(isRegistered == true);
    }



    

    /*///////////////////////////////////////////////
                  Test Vote
    ////////////////////////////////////////////////*/

    function test_CanNotVoteIfStatusIsNotOpen()public canditatesSet userRegistered voteForCanditate_1{
        vm.expectRevert(Voting.votingIsNotOpen.selector);
        
    }

    function test_CanNotVoteIfNotRegistered()public canditatesSet registrationTimePassed performUpkeepRanAndVotingOpened voteForCanditate_1{
        

        
        
        vm.prank(USER1);
        vm.expectRevert(Voting.notRegisteredForVoting.selector);
        
    }

    function test_canNotVoteIfAlreadyVoted()public canditatesSet userRegistered registrationTimePassed performUpkeepRanAndVotingOpened {
        

        
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyVoted.selector);
        voting.vote(MOCK_CANDITATE_1);

    }

    function test_canNotVoteIfCabditateIdInvalid()public canditatesSet userRegistered registrationTimePassed performUpkeepRanAndVotingOpened{
        

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Voting.invalidCanditateId.selector, 789));
        voting.vote(789);
    }

    function test_voteUpdateIsVoted()public canditatesSet userRegistered registrationTimePassed performUpkeepRanAndVotingOpened{
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        bool isVoted = voting.isVoted(USER1);
        assert(isVoted == true);
    }

    function test_voteIncreaseVotingCount()public canditatesSet userRegistered registrationTimePassed performUpkeepRanAndVotingOpened{

        uint256 startingVoteCount = voting.voteCounts(MOCK_CANDITATE_1);

        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        uint256 endingVoteCount = voting.voteCounts(MOCK_CANDITATE_1);

        assert(endingVoteCount == startingVoteCount +1);

    }

    /*///////////////////////////////////////////////
                  Test Voting Results
    ////////////////////////////////////////////////*/

    function test_VotingStatusClosedWhenVotingOpenTimePassed()public {

    }
}
