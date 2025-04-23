//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Voting} from "../../src/voting.sol";
import {DeployVoting} from "../../script/DeployVoting.s.sol";

contract TestVoting is Test {
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    uint256 public MOCK_Candidate_1 = 123;
    uint256 public MOCK_Candidate_2 = 456;
    uint256 REGISTERING_OPEN_TIME = 3600;
    uint256 VOTING_OPEN_TIME = 3600;

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

    //set candidates by admin and change Voting Status to Registering
    modifier CandidatesSet() {
        address admin = voting.getAdmin();
        vm.prank(admin);
        voting.setCandidates(MOCK_Candidate_1, MOCK_Candidate_2);
        _;
    }
    //regisrering for voting USER1

    modifier userRegistered() {
        vm.prank(USER1);
        voting.registerVoting();
        _;
    }

    //registering for voting USER2
    modifier user2Registered() {
        vm.prank(USER2);
        voting.registerVoting();
        _;
    }

    //msimulate time to pass registering time 1 hour
    modifier registrationTimePassed() {
        vm.warp(block.timestamp + REGISTERING_OPEN_TIME + 1);
        vm.roll(block.number + 1);
        _;
    }

    //call perform upKeep to chnge Voting status to OPEN
    modifier performUpkeepRanAndVotingOpened() {
        (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if (upkeepNeeded) {
            voting.performUpkeep(data);
        }
        _;
    }

    modifier voteForCandidate_1() {
        vm.prank(USER1);
        voting.vote(MOCK_Candidate_1);
        _;
    }

    modifier voteForCandidate_2() {
        vm.prank(USER1);
        voting.vote(MOCK_Candidate_2);
        _;
    }

    modifier voteForCandidate_2_byUSER2() {
        vm.prank(USER2);
        voting.vote(MOCK_Candidate_2);
        _;
    }

    //simulate time to pass Voting time
    modifier votingTimePassed() {
        vm.warp(block.timestamp + VOTING_OPEN_TIME + 1);
        vm.roll(block.number + 1);
        _;
    }
    //call perform upKeep to chnge Voting status to ENDED

    modifier performUpkeepRanAndVotingCounting() {
        (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if (upkeepNeeded) {
            voting.performUpkeep(data);
        }
        _;
    }

    /*///////////////////////////////////////////////
                  Test State variables
    ////////////////////////////////////////////////*/

    function test_votingStatusInitializedAsEnded() public view {
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    /*///////////////////////////////////////////////
                  Test setCandidates
    ////////////////////////////////////////////////*/

    function test_setCandidatesWhenAdminCall() public CandidatesSet {}

    function test_setCandidatesRevertIfSenderIsNotAdmin() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.notAuthorized.selector);
        voting.setCandidates(MOCK_Candidate_1, MOCK_Candidate_2);
    }

    function test_canNotSetCandidatesIfVotingNotClosed()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        address admin = voting.getAdmin();
        vm.prank(admin);
        vm.expectRevert(Voting.votingIsNotEnded.selector);
        voting.setCandidates(MOCK_Candidate_1, MOCK_Candidate_2);
    }

    function test_canNotSetCandidatesIfQulifiedVotersArrayNotResetted() public {}

    /*///////////////////////////////////////////////
                  Test registerVoting
    ////////////////////////////////////////////////*/

    function test_canNotRegisterIfRegisteringIsNotOpened() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.registeringIsNotOpenYet.selector);

        voting.registerVoting();
    }

    function test_userCanRegisterToVoting() public CandidatesSet userRegistered {
        address QulifiedVoter = voting.getQulifiedVoters(0);
        assert(USER1 == QulifiedVoter);
    }

    function test_registerVotingIsRevertingIfUserAlreadyRegistered() public CandidatesSet userRegistered {
        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyRegistered.selector);
        voting.registerVoting();
    }

    function test_isRegisteredMappingUpdateWhenRegister() public CandidatesSet userRegistered {
        bool isRegistered = voting.isRegistered(USER1);
        assert(isRegistered == true);
    }

    /*///////////////////////////////////////////////
                  Test Vote
    ////////////////////////////////////////////////*/

    function test_CanNotVoteIfStatusIsNotOpen() public CandidatesSet userRegistered {
        vm.expectRevert(Voting.votingIsNotOpen.selector);
        voting.vote(MOCK_Candidate_1);
    }

    function test_CanNotVoteIfNotRegistered()
        public
        CandidatesSet
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        vm.expectRevert(Voting.notRegisteredForVoting.selector);
        voting.vote(MOCK_Candidate_1);
    }

    function test_canNotVoteIfAlreadyVoted()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        voting.vote(MOCK_Candidate_1);

        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyVoted.selector);
        voting.vote(MOCK_Candidate_1);
    }

    function test_canNotVoteIfCabditateIdInvalid()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Voting.invalidCandidateId.selector, 789));
        voting.vote(789);
    }

    function test_voteUpdateIsVoted()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        voting.vote(MOCK_Candidate_1);

        bool isVoted = voting.isVoted(USER1);
        assert(isVoted == true);
    }

    function test_voteIncreaseVotingCount()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        uint256 startingVoteCount = voting.voteCounts(MOCK_Candidate_1);

        vm.prank(USER1);
        voting.vote(MOCK_Candidate_1);

        uint256 endingVoteCount = voting.voteCounts(MOCK_Candidate_1);

        assert(endingVoteCount == startingVoteCount + 1);
    }

    /*///////////////////////////////////////////////
                  Test Voting Results
    ////////////////////////////////////////////////*/

    function test_VotingStatusEndedWhenVotingTimePassed()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    function test_votingResultsRevertIfVotingStatusNotEnded()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        votingTimePassed
    {
        vm.expectRevert(Voting.VotingIsNOtClosedYet.selector);
        voting.votingResults();
    }

    function test_canCallVotingResultsIfVotingStatusEnded()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {}

    function test_votingResultsPickCorrectWinner_1()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getRecentWinner() == MOCK_Candidate_1);
    }

    function test_votingResultsPickCorrectWinner_2()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_2
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getRecentWinner() == MOCK_Candidate_2);
    }

    function test_votingResultsCallResetVotingRound()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getQulifiedVotersLength() == 0);
        assert(voting.isVoted(USER1) == false);
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    function test_votingResultsIfVoteCountEquals()
        public
        CandidatesSet
        userRegistered
        user2Registered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
        voteForCandidate_2_byUSER2
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getRecentWinner() == 0);
    }

    /*///////////////////////////////////////////////
                  Test getter functions
    ////////////////////////////////////////////////*/

    function test_admin() public view {
        assert(voting.getAdmin() == msg.sender);
    }

    function test_getVoters()
        public
        CandidatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCandidate_1
    {
        assert(USER1 == voting.getVoters(0));
    }
}
