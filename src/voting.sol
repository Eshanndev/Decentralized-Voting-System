//SPDX-License-Identifier:MIT
pragma solidity^0.8.19;

contract Voting {

  error alreadyRegistered(address voterApplicant);

  address[] public qulifiedVoters;

  function registerVoting() public {
    // check if the address is already registered or not
    //if not add to the voters qulifiedVoters array
    bool isAlreadyRegistered;
    for (uint256 i = 0; i< qulifiedVoters.length ; i++){
      if(qulifiedVoters[i] == msg.sender){
        isAlreadyRegistered = true;
    }

   if (isAlreadyRegistered){
    revert alreadyRegistered(msg.sender);
   }
   unchecked {
    qulifiedVoters.push(msg.sender);
   }

  }

}