// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGovernance {
    enum ProposalType { 
        PARAMETER_CHANGE,
        EMERGENCY_ACTION,
        PROTOCOL_UPGRADE,
        ORACLE_CHANGE
    }

    struct Proposal {
        uint256 id;
        address proposer;
        ProposalType proposalType;
        bytes32 parameterId;
        uint256 newValue;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        bool canceled;
    }

    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, ProposalType proposalType);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCanceled(uint256 indexed proposalId);

    function propose(ProposalType proposalType, bytes32 parameterId, uint256 newValue) external returns (uint256);
    function vote(uint256 proposalId, bool support) external;
    function execute(uint256 proposalId) external;
    function cancel(uint256 proposalId) external;
}
