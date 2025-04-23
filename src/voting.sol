//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;
/**
 * @title Voting System Project
 * @author Eshan
 * @notice A decentralized voting system where an admin can register candidates and users can register and vote.
 * @dev Handles candidate setup, user registration, voting, result calculation, and Chainlink Automation-based state transitions.
 */

contract Voting {
    /*///////////////////////////////////////////////
                Events
    ////////////////////////////////////////////////*/

    event CandidatesAdded(uint256 Candidate_1, uint256 Candidate_2);
    event registeringOpened(uint256 time);
    event votingOpened(uint256 time);
    event WinnerPicked(uint256 indexed votingRoundId, uint256 indexed winnerId, uint256 voteCount, uint256 wonByVotes);

    /*///////////////////////////////////////////////
                Errors
    ////////////////////////////////////////////////*/

    error alreadyRegistered();
    error votingIsNotOpen();
    error registeringIsNotOpenYet();
    error VotingIsNOtClosedYet();
    error votingIsNotEnded();
    error notAuthorized();
    error alreadyVoted();
    error invalidCandidateId(uint256 id);
    error notRegisteredForVoting();
    error qulifiedVotersNotResetted();

    /*///////////////////////////////////////////////
                Enums
    ////////////////////////////////////////////////*/

    // Represents the phase of voting
    enum VotingStatus {
        REGISTERING,
        OPEN,
        ENDED
    }

    // Represents tasks to trigger via automation
    enum AutomationTasks {
        OPEN_REGISTRATION,
        OPEN_VOTING,
        OPEN_COUNTING
    }

    /*///////////////////////////////////////////////
                Mappings
    ////////////////////////////////////////////////*/

    // Maps candidate ID to number of votes received
    mapping(uint256 candidateId => uint256 voteCount) public voteCounts;

    // Tracks if an address has already voted
    mapping(address => bool) public isVoted;

    // Tracks if an address has registered to vote
    mapping(address => bool) public isRegistered;

    //Track previous Voting Round Results
    mapping(uint256 => resultContainer) public votingResultRecords;

    /*///////////////////////////////////////////////
                State variables
    ////////////////////////////////////////////////*/

    struct resultContainer{
        uint256 votingRound;
        uint256 winnerId;
        uint256 voteCount;
        uint256 wonByVotes;
    }

    address[] private qulifiedVoters;
    address[] private voters;
    VotingStatus public currentVotingStatus = VotingStatus.ENDED; // Initial state
    address immutable i_admin;
    uint256 currentCandidate_1;
    uint256 currentCandidate_2;
    uint256 public recentWinner;
    uint256 registerOpenedTime;
    uint256 votingOpenedTime;
    uint256 public currentVotingRound = 0;
    uint256 private constant REGISTERING_OPEN_TIME = 3600;
    uint256 private constant VOTING_OPEN_TIME = 3600;

    constructor() {
        i_admin = msg.sender;
    }

    /*///////////////////////////////////////////////
                Modifiers
    ////////////////////////////////////////////////*/

    // Restricts access to admin-only functions
    modifier onlyAdmin() {
        if (msg.sender != i_admin) {
            revert notAuthorized();
        }
        _;
    }

    /*///////////////////////////////////////////////
                Functions
    ////////////////////////////////////////////////*/

    /**
     * @notice Allows the admin to set up two candidates and open the registration phase.
     * @dev Initializes candidate IDs and their corresponding vote counts to 0.
     * Transitions the voting status to `REGISTERING` and stores the timestamp.
     * Emits {CandidatesAdded} and {registeringOpened} events.
     * @param _Candidate_1 ID of the first candidate
     * @param _Candidate_2 ID of the second candidate
     * @custom:modifier onlyAdmin Only the admin can call this function
     */
    function setCandidates(uint256 _Candidate_1, uint256 _Candidate_2) public onlyAdmin {
        if (currentVotingStatus != VotingStatus.ENDED) {
            revert votingIsNotEnded();
        }

        currentVotingRound ++;
        currentCandidate_1 = _Candidate_1;
        currentCandidate_2 = _Candidate_2;

        voteCounts[_Candidate_1] = 0;
        voteCounts[_Candidate_2] = 0;

        currentVotingStatus = VotingStatus.REGISTERING;
        registerOpenedTime = block.timestamp;

        emit CandidatesAdded(_Candidate_1, _Candidate_2);
        emit registeringOpened(registerOpenedTime);
    }

    /**
     * @notice Registers the caller for voting if the registration phase is open.
     * @dev Ensures that the user has not already registered.
     * Emits a {registeringOpened} event when registration opens.
     */
    function registerVoting() public {
        if (currentVotingStatus != VotingStatus.REGISTERING) {
            revert registeringIsNotOpenYet();
        }
        if (isRegistered[msg.sender] == true) {
            revert alreadyRegistered();
        }

        isRegistered[msg.sender] = true;
        qulifiedVoters.push(msg.sender);
    }

    /**
     * @notice Allows a registered user to vote for one of the candidates.
     * @dev The function checks if voting is open and if the user has registered and hasn't already voted.
     * @param _CandidateId The candidate ID that the user is voting for.
     * @custom:reverts If the candidate ID is invalid or the user has already voted.
     */
    function vote(uint256 _CandidateId) public {
        if (currentVotingStatus != VotingStatus.OPEN) {
            revert votingIsNotOpen();
        }

        if (isRegistered[msg.sender] != true) {
            revert notRegisteredForVoting();
        }

        if (isVoted[msg.sender] == true) {
            revert alreadyVoted();
        }
        if (_CandidateId != currentCandidate_1 && _CandidateId != currentCandidate_2) {
            revert invalidCandidateId(_CandidateId);
        }
        isVoted[msg.sender] = true;
        voters.push(msg.sender);
        voteCounts[_CandidateId] += 1;
    }

    /**
     * @notice Ends the voting process and calculates the result based on the votes.
     * @dev Resets the voting round after determining the winner.
     * Emits a {VotingResults} event when voting has concluded.
     */
    function votingResults() public {
        if (currentVotingStatus != VotingStatus.ENDED) {
            revert VotingIsNOtClosedYet();
        }

        if (voteCounts[currentCandidate_1] == voteCounts[currentCandidate_2]) {
            recentWinner = 0;
        } else if (voteCounts[currentCandidate_1] < voteCounts[currentCandidate_2]) {
            recentWinner = currentCandidate_2;
        } else {
            recentWinner = currentCandidate_1;
        }

        votingResultRecords[currentVotingRound] = resultContainer({
            votingRound:currentVotingRound,
            winnerId:recentWinner,
            voteCount:voteCounts[recentWinner],
            wonByVotes:voters.length - voteCounts[recentWinner]

        });

        emit WinnerPicked (currentVotingRound,recentWinner,voteCounts[recentWinner],voters.length - voteCounts[recentWinner]);

        resetVotingRound();
    }

    /**
     * @notice Checks the upkeep for Chainlink Automation, if registration or voting periods need to be transitioned.
     * @param data Data passed to the function.
     * @return upkeepNeeded Whether the upkeep is needed.
     * @return data Data required for upkeep.
     */
    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory data) {
        if (
            currentVotingStatus == VotingStatus.REGISTERING
                && block.timestamp - registerOpenedTime > REGISTERING_OPEN_TIME
        ) {
            upkeepNeeded = true;
            data = abi.encode(AutomationTasks.OPEN_VOTING);
        } else if (currentVotingStatus == VotingStatus.OPEN && block.timestamp - votingOpenedTime > VOTING_OPEN_TIME) {
            upkeepNeeded = true;
            data = abi.encode(AutomationTasks.OPEN_COUNTING);
        }
    }

    /**
     * @notice Performs the transition between the different voting phases, including opening voting and counting results.
     * @param performData The data that tells which phase to transition to.
     * @custom:modifier onlyAdmin Only the admin can trigger this action.
     */
    function performUpkeep(bytes memory performData) public {
        AutomationTasks task = abi.decode(performData, (AutomationTasks));

        if (task == AutomationTasks.OPEN_VOTING) {
            currentVotingStatus = VotingStatus.OPEN;
            votingOpenedTime = block.timestamp;
            emit votingOpened(votingOpenedTime);
        } else if (task == AutomationTasks.OPEN_COUNTING) {
            currentVotingStatus = VotingStatus.ENDED;
            votingResults();
        }
    }
    /**
     * @notice Resets the voting round by clearing all registrations, votes, and resetting the state.
     * @dev Used after the results have been counted and a new round needs to begin.
     */

    function resetVotingRound() public {
        for (uint256 i = 0; qulifiedVoters.length > i; i++) {
            address qulifiedVoter = qulifiedVoters[i];
            address voter = voters[i];
            isVoted[voter] = false;
            isRegistered[qulifiedVoter] = false;
        }
        qulifiedVoters = new address[](0);
    }

    /*///////////////////////////////////////////////
                Getter Functions
    ////////////////////////////////////////////////*/

    function getQulifiedVoters(uint256 index) public view returns (address) {
        return qulifiedVoters[index];
    }

    function getVoters(uint256 index) public view returns (address) {
        return voters[index];
    }

    function getQulifiedVotersLength() public view returns (uint256) {
        return qulifiedVoters.length;
    }

    function getAdmin() public view returns (address) {
        return i_admin;
    }

    function getRecentWinner() public view returns (uint256) {
        return recentWinner;
    }

    function getCurrentVotingStatus() public view returns (VotingStatus) {
        return currentVotingStatus;
    }
}
