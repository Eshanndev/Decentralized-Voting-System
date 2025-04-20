//SPDX-License-Identifier:MIT
pragma solidity ^0.8.19;

contract Voting {
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
    error invalidCanditateId(uint256 id);
    error notRegisteredForVoting();
    error qulifiedVotersNotResetted();

    /*///////////////////////////////////////////////
                Events
    ////////////////////////////////////////////////*/

    event canditatesAdded(uint256 canditate_1, uint256 canditate_2);

    /*///////////////////////////////////////////////
                Enums
    ////////////////////////////////////////////////*/

    enum VotingStatus {
        REGISTERING,
        OPEN,
        CLOSED,
        ENDED
    }

    enum AutomationTasks{
        OPEN_REGISTRATION,
        OPEN_VOTING,
        OPEN_COUNTING
    }

    /*///////////////////////////////////////////////
                Mappings
    ////////////////////////////////////////////////*/

    mapping(uint256 candidateId => int256 voteCount) public voteCounts;
    mapping(address => bool) public isVoted;
    mapping(address => bool) public isRegistered;

    /*///////////////////////////////////////////////
                State variables
    ////////////////////////////////////////////////*/


    address[] private qulifiedVoters;
    VotingStatus public currentVotingStatus = VotingStatus.OPEN;
    address immutable i_admin;
    // uint256[] public currentCanditates;
    uint256 currentCanditate_1;
    uint256 currentCanditate_2;
    uint256 recentWinner;
    uint256 registerOpenedTime;
    uint256 votingOpenedTime;
    uint256 constant private REGISTERING_OPEN_TIME = 3600;
    uint256 constant private VOTING_OPEN_TIME = 3600;
    
    uint256 latestWinner;


    constructor() {
        i_admin = msg.sender;
    }

    /*///////////////////////////////////////////////
                Modifiers
    ////////////////////////////////////////////////*/

    modifier onlyAdmin() {
        if (msg.sender != i_admin) {
            revert notAuthorized();
        }
        _;
    }

    /*///////////////////////////////////////////////
                Functions
    ////////////////////////////////////////////////*/

    function setCanditates(uint256 _canditate_1, uint256 _canditate_2) public onlyAdmin {
        if (currentVotingStatus != VotingStatus.ENDED) {
            revert votingIsNotEnded();
        }
        if (qulifiedVoters.length != 0) {
            revert qulifiedVotersNotResetted();
        }

        currentCanditate_1 = _canditate_1;
        currentCanditate_2 =_canditate_2;

        
        // currentCanditates.push(_canditate_1);
        // currentCanditates.push(_canditate_2);
        voteCounts[_canditate_1] = 0;
        voteCounts[_canditate_2] = 0;

        currentVotingStatus = VotingStatus.REGISTERING;
        registerOpenedTime = block.timestamp;

        emit canditatesAdded(_canditate_1,_canditate_2);
    }


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

    function vote(uint256 _canditateId) public {
        if (currentVotingStatus != VotingStatus.OPEN) {
            revert votingIsNotOpen();
        }

        if (isRegistered[msg.sender] != true) {
            revert notRegisteredForVoting();
        }

        if (isVoted[msg.sender] == true) {
            revert alreadyVoted();
        }
        if (_canditateId != currentCanditate_1 && _canditateId != currentCanditate_2) {
            revert invalidCanditateId(_canditateId);
        }
        isVoted[msg.sender] = true;
        voteCounts[_canditateId] += 1;
    }

    function votingResults()public{

        if(currentVotingStatus != VotingStatus.CLOSED){
            revert VotingIsNOtClosedYet();
        }

        if (voteCounts[currentCanditate_1] == voteCounts[currentCanditate_2]){
            recentWinner = 0;
        }else if(voteCounts[currentCanditate_1] < voteCounts[currentCanditate_2]){
            recentWinner = currentCanditate_2;
        }else {
            recentWinner =  currentCanditate_1;
        }
        
        resetVotingRound();
        currentVotingStatus = VotingStatus.ENDED;

    }

    function checkUpkeep(bytes calldata) external view returns (bool upkeepNeeded, bytes memory data) {
        if (block.timestamp - registerOpenedTime >  REGISTERING_OPEN_TIME){
            upkeepNeeded = true;
            data = abi.encode(AutomationTasks.OPEN_VOTING);
        }
        else if (block.timestamp - votingOpenedTime > VOTING_OPEN_TIME){
            upkeepNeeded = true;
            data = abi.encode(AutomationTasks.OPEN_COUNTING);
        }

    }


    function performUpkeep(bytes memory performData) public {
        AutomationTasks task = abi.decode(performData, (AutomationTasks));

        if (task == AutomationTasks.OPEN_VOTING){
            currentVotingStatus = VotingStatus.OPEN;
            votingOpenedTime = block.timestamp;
        }
        else if (task == AutomationTasks.OPEN_COUNTING){
            currentVotingStatus = VotingStatus.CLOSED;
            votingResults();
        }
    }

    function resetVotingRound()public {
        for (uint256 i = 0; qulifiedVoters.length< i;i++){
            address voter = qulifiedVoters[i];
            isVoted[voter] = false;
            isRegistered[voter] = false;
        }
        qulifiedVoters = new address[](0);

    }

    

    /*///////////////////////////////////////////////
                Getter Functions
    ////////////////////////////////////////////////*/

    function getQulifiedVoters(uint256 index) public view returns (address) {
        return qulifiedVoters[index];
    }

    function getAdmin() public view returns (address) {
        return i_admin;
    }

    function getRecentWinner()public view returns(uint256){
        return recentWinner;
    }
}
