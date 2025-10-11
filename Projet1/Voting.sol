// SPDX-License-Identifier: MIT
pragma solidity 0.8.28; //Exi2


/** Process : 
Proc1 - L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
Proc2 - L'administrateur du vote commence la session d'enregistrement de la proposition.
Proc3 - Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
Proc4 - L'administrateur de vote met fin à la session d'enregistrement des propositions.
Proc5 - L'administrateur du vote commence la session de vote.
Proc6 - Les électeurs inscrits votent pour leur proposition préférée.
Proc7 - L'administrateur du vote met fin à la session de vote.
Proc8 - L'administrateur du vote comptabilise les votes.
Proc9 - Tout le monde peut vérifier les derniers détails de la proposition gagnante.

Exigences : 
Exi1 - Votre smart contract doit s’appeler “Voting”. 
Exi2 - Votre smart contract doit utiliser la dernière version du compilateur.
Exi3 - L’administrateur est celui qui va déployer le smart contract. 
Exi4 - Votre smart contract doit définir les structures de données suivantes : 
    struct Voter { bool isRegistered; bool hasVoted; uint votedProposalId; } 
    struct Proposal { string description; uint voteCount; }
Exi5 - Votre smart contract doit définir une énumération qui gère les différents états d’un vote
    enum WorkflowStatus { 
        RegisteringVoters, 
        ProposalsRegistrationStarted, 
        ProposalsRegistrationEnded, 
        VotingSessionStarted, 
        VotingSessionEnded, 
        VotesTallied }
Exi6 - Votre smart contract doit définir un uint winningProposalId qui représente l’id du gagnant ou une fonction getWinner qui retourne le gagnant.
Exi7 - Votre smart contract doit importer le smart contract la librairie “Ownable” d’OpenZepplin.
Exi8 - Votre smart contract doit définir les événements suivants : 
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    vent Voted (address voter, uint proposalId);

 */

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol"; //Exi7

contract Voting is Ownable { //Exi1

struct Voter { //Exi4
    bool isRegistered;
    bool hasVoted;
    uint votedProposalId;
}
struct Proposal { //Exi4
    string description;
    uint voteCount;
}
enum WorkflowStatus { //Exi5
    RegisteringVoters, 
    ProposalsRegistrationStarted, 
    ProposalsRegistrationEnded, 
    VotingSessionStarted, 
    VotingSessionEnded, 
    VotesTallied
    }
//Exi8
event VoterRegistered(address voterAddress);
event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
event ProposalRegistered(uint proposalId);
event Voted (address voter, uint proposalId);

mapping (address => Voter) whitelist;
Proposal[] proposallist;
Proposal winner;
WorkflowStatus public currentState = WorkflowStatus.RegisteringVoters;

constructor () Ownable(msg.sender){} //Exi3

modifier isVoter(){
    require (whitelist[msg.sender].isRegistered == true, "You are not allowed to do this, contact the Administrator");
    _;
}
//Proc1
function register (address _address) external onlyOwner{
    require (whitelist[_address].isRegistered == false, "Address already registered");
    whitelist[_address].isRegistered = true;
    emit VoterRegistered(_address);
}
//Proc2, Proc4, Proc5, Proc7
function nextWorkflowPhase () external onlyOwner {
    WorkflowStatus previousStatus = currentState;
    if (currentState == WorkflowStatus.RegisteringVoters){
        currentState = WorkflowStatus.ProposalsRegistrationStarted;
    } else if (currentState == WorkflowStatus.ProposalsRegistrationStarted){
        currentState = WorkflowStatus.ProposalsRegistrationEnded;
    } else if(currentState == WorkflowStatus.ProposalsRegistrationEnded){
        currentState = WorkflowStatus.VotingSessionStarted;
    } else if (currentState == WorkflowStatus.VotingSessionStarted){
        currentState = WorkflowStatus.VotingSessionEnded;
    } else if (currentState == WorkflowStatus.VotingSessionEnded){
        currentState = WorkflowStatus.VotesTallied;
    } else {
        revert("reset the workflow for a new vote session");
    }
    emit WorkflowStatusChange(previousStatus, currentState);
}
//Proc3
function registerProposal (string memory _description) external isVoter {
    require (currentState == WorkflowStatus.ProposalsRegistrationStarted, "Wait for the start of the proposal session");
    proposallist.push(Proposal(_description, 0));
    emit ProposalRegistered(proposallist.length-1);
}
//Proc6
function vote (uint _proposalId) external isVoter {
    require (currentState == WorkflowStatus.VotingSessionStarted,"Wait for the start of the voting session");
    require (whitelist[msg.sender].hasVoted==false, "You has already voted");
    proposallist[_proposalId].voteCount += 1;
    whitelist[msg.sender].hasVoted = true;
    whitelist[msg.sender].votedProposalId = _proposalId;
    emit Voted(msg.sender,_proposalId);
}
//Proc8
function calculWinner () external onlyOwner {
    require (currentState == WorkflowStatus.VotingSessionEnded, "close the voting session first");
    uint index;
    bool wehaveaWinner = 1;
    for (uint i=1;i<proposallist.length;i++){
        if (proposallist[i].voteCount > proposallist[index].voteCount){
            wehaveaWinner = true;
            index = i;
        } else if(proposallist[i].voteCount == proposallist[index].voteCount) {
            wehaveaWinner = false;
        } else {
            continue;
        }
    }
    if (wehaveaWinner == true){
        winner.description = proposallist[index].description;
        }else {
            revert ("it's a tie, vote again");
        }
}
//Proc9 - Exi6
function getWinner () public view returns (string memory){
    require (currentState == WorkflowStatus.VotesTallied, "The voting session is not closed");
    require (keccak256(abi.encodePacked((winner.description))) != keccak256(abi.encodePacked((""))), "There is no winner");
    return winner.description;
}

}