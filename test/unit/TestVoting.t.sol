//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Voting} from "../../src/voting.sol";
import {DeployVoting} from "../../script/DeployVoting.s.sol";

contract TestVoting is Test {
    address public USER1 = makeAddr("user1");
    address public USER2 = makeAddr("user2");
    uint256 public MOCK_CANDITATE_1 = 123;
    uint256 public MOCK_CANDITATE_2 = 456;
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

    modifier canditatesSet() {
        address admin = voting.getAdmin();
        vm.prank(admin);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
        _;
    }

    modifier userRegistered() {
        vm.prank(USER1);
        voting.registerVoting();
        _;
    }

    modifier user2Registered() {
        vm.prank(USER2);
        voting.registerVoting();
        _;
    }

    modifier registrationTimePassed() {
        vm.warp(block.timestamp + REGISTERING_OPEN_TIME + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier performUpkeepRanAndVotingOpened() {
        (bool upkeepNeeded, bytes memory data) = voting.checkUpkeep("");
        if (upkeepNeeded) {
            voting.performUpkeep(data);
        }
        _;
    }

    modifier voteForCanditate_1() {
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);
        _;
    }

    modifier voteForCanditate_2() {
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_2);
        _;
    }

    modifier voteForCanditate_2_byUSER2() {
        vm.prank(USER2);
        voting.vote(MOCK_CANDITATE_2);
        _;
    }

    modifier votingTimePassed() {
        vm.warp(block.timestamp + VOTING_OPEN_TIME + 1);
        vm.roll(block.number + 1);
        _;
    }

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
                  Test setCanditates
    ////////////////////////////////////////////////*/

    function test_setCanditatesWhenAdminCall() public canditatesSet {}

    function test_setCanditatesRevertIfSenderIsNotAdmin() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.notAuthorized.selector);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
    }

    function test_canNotSetCanditatesIfVotingNotClosed()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        address admin = voting.getAdmin();
        vm.prank(admin);
        vm.expectRevert(Voting.votingIsNotEnded.selector);
        voting.setCanditates(MOCK_CANDITATE_1, MOCK_CANDITATE_2);
    }

    function test_canNotSetCanditatesIfQulifiedVotersArrayNotResetted() public {}

    /*///////////////////////////////////////////////
                  Test registerVoting
    ////////////////////////////////////////////////*/

    function test_canNotRegisterIfRegisteringIsNotOpened() public {
        vm.prank(USER1);
        vm.expectRevert(Voting.registeringIsNotOpenYet.selector);

        voting.registerVoting();
    }

    function test_userCanRegisterToVoting() public canditatesSet userRegistered {
        address QulifiedVoter = voting.getQulifiedVoters(0);
        assert(USER1 == QulifiedVoter);
    }

    function test_registerVotingIsRevertingIfUserAlreadyRegistered() public canditatesSet userRegistered {
        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyRegistered.selector);
        voting.registerVoting();
    }

    function test_isRegisteredMappingUpdateWhenRegister() public canditatesSet userRegistered {
        bool isRegistered = voting.isRegistered(USER1);
        assert(isRegistered == true);
    }

    /*///////////////////////////////////////////////
                  Test Vote
    ////////////////////////////////////////////////*/

    function test_CanNotVoteIfStatusIsNotOpen() public canditatesSet userRegistered {
        vm.expectRevert(Voting.votingIsNotOpen.selector);
        voting.vote(MOCK_CANDITATE_1);
    }

    function test_CanNotVoteIfNotRegistered()
        public
        canditatesSet
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        vm.expectRevert(Voting.notRegisteredForVoting.selector);
        voting.vote(MOCK_CANDITATE_1);
    }

    function test_canNotVoteIfAlreadyVoted()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        vm.prank(USER1);
        vm.expectRevert(Voting.alreadyVoted.selector);
        voting.vote(MOCK_CANDITATE_1);
    }

    function test_canNotVoteIfCabditateIdInvalid()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Voting.invalidCanditateId.selector, 789));
        voting.vote(789);
    }

    function test_voteUpdateIsVoted()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        bool isVoted = voting.isVoted(USER1);
        assert(isVoted == true);
    }

    function test_voteIncreaseVotingCount()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
    {
        uint256 startingVoteCount = voting.voteCounts(MOCK_CANDITATE_1);

        vm.prank(USER1);
        voting.vote(MOCK_CANDITATE_1);

        uint256 endingVoteCount = voting.voteCounts(MOCK_CANDITATE_1);

        assert(endingVoteCount == startingVoteCount + 1);
    }

    /*///////////////////////////////////////////////
                  Test Voting Results
    ////////////////////////////////////////////////*/

    function test_VotingStatusEndedWhenVotingTimePassed()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    function test_votingResultsRevertIfVotingStatusNotEnded()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        votingTimePassed
    {
        vm.expectRevert(Voting.VotingIsNOtClosedYet.selector);
        voting.votingResults();
    }

    function test_canCallVotingResultsIfVotingStatusEnded()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {}

    function test_votingResultsPickCorrectWinner_1()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getRecentWinner() == MOCK_CANDITATE_1);
    }

    function test_votingResultsPickCorrectWinner_2()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_2
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getRecentWinner() == MOCK_CANDITATE_2);
    }

    function test_votingResultsCallResetVotingRound()
        public
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        votingTimePassed
        performUpkeepRanAndVotingCounting
    {
        assert(voting.getQulifiedVotersLength() == 0);
        assert(voting.isVoted(USER1) == false);
        assert(voting.getCurrentVotingStatus() == Voting.VotingStatus.ENDED);
    }

    function test_votingResultsIfVoteCountEquals()
        public
        canditatesSet
        userRegistered
        user2Registered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
        voteForCanditate_2_byUSER2
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
        canditatesSet
        userRegistered
        registrationTimePassed
        performUpkeepRanAndVotingOpened
        voteForCanditate_1
    {
        assert(USER1 == voting.getVoters(0));
    }
}
