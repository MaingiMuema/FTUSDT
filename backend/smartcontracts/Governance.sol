// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IGovernance.sol";
import "./Ownable.sol";

contract Governance is IGovernance, Ownable {
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant EXECUTION_DELAY = 2 days;
    uint256 public constant MIN_VOTING_POWER = 100e18; // 100 tokens minimum to propose
    uint256 public proposalCount;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    
    modifier onlyValidProposal(uint256 proposalId) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        require(!proposals[proposalId].executed, "Proposal already executed");
        require(!proposals[proposalId].canceled, "Proposal already canceled");
        _;
    }
    
    modifier onlyDuringVoting(uint256 proposalId) {
        require(block.timestamp >= proposals[proposalId].votingStart, "Voting not started");
        require(block.timestamp <= proposals[proposalId].votingEnd, "Voting ended");
        _;
    }
    
    function propose(
        ProposalType proposalType,
        bytes32 parameterId,
        uint256 newValue
    ) external override returns (uint256) {
        require(votingPower[msg.sender] >= MIN_VOTING_POWER, "Insufficient voting power");
        
        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.proposalType = proposalType;
        proposal.parameterId = parameterId;
        proposal.newValue = newValue;
        proposal.votingStart = block.timestamp;
        proposal.votingEnd = block.timestamp + VOTING_PERIOD;
        
        emit ProposalCreated(proposalCount, msg.sender, proposalType);
        return proposalCount;
    }
    
    function vote(uint256 proposalId, bool support) 
        external 
        override 
        onlyValidProposal(proposalId)
        onlyDuringVoting(proposalId)
    {
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(votingPower[msg.sender] > 0, "No voting power");
        
        Proposal storage proposal = proposals[proposalId];
        uint256 weight = votingPower[msg.sender];
        
        if (support) {
            proposal.votesFor += weight;
        } else {
            proposal.votesAgainst += weight;
        }
        
        hasVoted[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender, support, weight);
    }
    
    function execute(uint256 proposalId) 
        external 
        override 
        onlyValidProposal(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.votingEnd + EXECUTION_DELAY, "Execution delay not met");
        require(proposal.votesFor > proposal.votesAgainst, "Proposal not passed");
        
        proposal.executed = true;
        
        // Execute the proposal based on its type
        if (proposal.proposalType == ProposalType.PARAMETER_CHANGE) {
            _executeParameterChange(proposal.parameterId, proposal.newValue);
        } else if (proposal.proposalType == ProposalType.EMERGENCY_ACTION) {
            _executeEmergencyAction(proposal.parameterId);
        } else if (proposal.proposalType == ProposalType.PROTOCOL_UPGRADE) {
            _executeProtocolUpgrade(proposal.parameterId, proposal.newValue);
        } else if (proposal.proposalType == ProposalType.ORACLE_CHANGE) {
            _executeOracleChange(proposal.parameterId);
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    function cancel(uint256 proposalId) 
        external 
        override
        onlyValidProposal(proposalId) 
    {
        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || msg.sender == owner(), "Not authorized");
        require(block.timestamp <= proposal.votingEnd, "Voting period ended");
        
        proposal.canceled = true;
        emit ProposalCanceled(proposalId);
    }
    
    // Internal execution functions
    function _executeParameterChange(bytes32 parameterId, uint256 newValue) internal {
        // Implementation for parameter changes
        // This would be connected to the protocol's parameter management
    }
    
    function _executeEmergencyAction(bytes32 actionId) internal {
        // Implementation for emergency actions
        // This would be connected to the protocol's emergency controls
    }
    
    function _executeProtocolUpgrade(bytes32 upgradeId, uint256 newVersion) internal {
        // Implementation for protocol upgrades
        // This would be connected to the protocol's upgrade mechanism
    }
    
    function _executeOracleChange(bytes32 oracleId) internal {
        // Implementation for oracle changes
        // This would be connected to the protocol's oracle management
    }
    
    // Function to update voting power (would be called by token contract)
    function updateVotingPower(address user, uint256 newVotingPower) external onlyOwner {
        votingPower[user] = newVotingPower;
    }
    
    // View functions
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        require(proposalId > 0 && proposalId <= proposalCount, "Invalid proposal ID");
        return proposals[proposalId];
    }
    
    function getVotingPower(address user) external view returns (uint256) {
        return votingPower[user];
    }
}
