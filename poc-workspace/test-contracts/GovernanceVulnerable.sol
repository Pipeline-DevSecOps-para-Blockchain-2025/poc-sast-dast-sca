// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Governance Vulnerable Contract for Testing
 * 
 * This contract contains governance-specific vulnerabilities commonly found
 * in DAO and governance implementations.
 */

contract GovernanceVulnerable {
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        mapping(address => bool) hasVoted;
        mapping(address => uint256) votes;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public votingPower;
    mapping(address => uint256) public delegatedPower;
    mapping(address => address) public delegates;
    
    uint256 public proposalCount;
    uint256 public quorum = 1000; // Minimum votes needed
    uint256 public votingPeriod = 7 days;
    address public admin;
    bool public paused;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 votes);
    event ProposalExecuted(uint256 indexed proposalId);
    event PowerDelegated(address indexed delegator, address indexed delegatee, uint256 power);
    
    constructor() {
        admin = msg.sender;
        votingPower[msg.sender] = 10000; // Initial voting power
    }
    
    // Vulnerability 1: Reentrancy in proposal execution
    function executeProposal(uint256 proposalId) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting still active");
        require(!proposal.executed, "Already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal failed");
        require(proposal.forVotes >= quorum, "Quorum not met");
        
        // Vulnerable: External call before state change
        (bool success, ) = proposal.proposer.call(abi.encodeWithSignature("onProposalExecuted(uint256)", proposalId));
        
        // State change after external call
        proposal.executed = true;
        
        emit ProposalExecuted(proposalId);
    }
    
    // Vulnerability 2: Vote manipulation through delegation
    function delegateVotingPower(address delegatee, uint256 amount) public {
        require(votingPower[msg.sender] >= amount, "Insufficient voting power");
        
        // Vulnerable: No check for circular delegation
        delegates[msg.sender] = delegatee;
        votingPower[msg.sender] -= amount;
        delegatedPower[delegatee] += amount;
        
        emit PowerDelegated(msg.sender, delegatee, amount);
    }
    
    // Vulnerability 3: Flash loan governance attack
    function vote(uint256 proposalId, bool support) public {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp >= proposal.startTime, "Voting not started");
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        // Vulnerable: Uses current voting power (can be manipulated with flash loans)
        uint256 votes = getCurrentVotingPower(msg.sender);
        require(votes > 0, "No voting power");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.votes[msg.sender] = votes;
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }
        
        emit VoteCast(proposalId, msg.sender, support, votes);
    }
    
    // Vulnerability 4: Timestamp manipulation
    function createProposal(string memory description) public returns (uint256) {
        // Vulnerable: Uses block.timestamp for timing
        uint256 proposalId = ++proposalCount;
        Proposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        
        emit ProposalCreated(proposalId, msg.sender, description);
        return proposalId;
    }
    
    // Vulnerability 5: Admin privilege escalation
    function setQuorum(uint256 newQuorum) public {
        // Vulnerable: Only basic access control
        require(msg.sender == admin, "Not admin");
        quorum = newQuorum; // Can be set to 0 to bypass voting
    }
    
    // Vulnerability 6: Double voting through contract recreation
    function voteWithContract(uint256 proposalId, bool support) public {
        // Vulnerable: No check for contract voters
        vote(proposalId, support);
    }
    
    // Vulnerability 7: Proposal spam attack
    function createMultipleProposals(string[] memory descriptions) public {
        // Vulnerable: No rate limiting
        for (uint256 i = 0; i < descriptions.length; i++) {
            createProposal(descriptions[i]);
        }
    }
    
    // Vulnerability 8: Voting power manipulation
    function mintVotingPower(address to, uint256 amount) public {
        // Vulnerable: No proper access control
        require(msg.sender == admin, "Not admin");
        votingPower[to] += amount; // Admin can mint unlimited voting power
    }
    
    // Vulnerability 9: Emergency pause without timelock
    function emergencyPause() public {
        // Vulnerable: Immediate pause without timelock
        require(msg.sender == admin, "Not admin");
        paused = true;
    }
    
    // Vulnerability 10: Delegate voting without consent
    function forceDelegation(address from, address to, uint256 amount) public {
        // Vulnerable: Admin can force delegation
        require(msg.sender == admin, "Not admin");
        require(votingPower[from] >= amount, "Insufficient power");
        
        votingPower[from] -= amount;
        delegatedPower[to] += amount;
        delegates[from] = to;
    }
    
    // Vulnerability 11: Proposal execution without proper validation
    function executeArbitraryCall(address target, bytes memory data) public {
        // Vulnerable: Admin can execute arbitrary calls
        require(msg.sender == admin, "Not admin");
        (bool success, ) = target.call(data);
        require(success, "Call failed");
    }
    
    // Vulnerability 12: Vote buying through transferable tokens
    function transferVotingPower(address to, uint256 amount) public {
        // Vulnerable: Voting power is transferable (enables vote buying)
        require(votingPower[msg.sender] >= amount, "Insufficient power");
        votingPower[msg.sender] -= amount;
        votingPower[to] += amount;
    }
    
    // Helper functions
    function getCurrentVotingPower(address voter) public view returns (uint256) {
        return votingPower[voter] + delegatedPower[voter];
    }
    
    function getProposal(uint256 proposalId) public view returns (
        address proposer,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed
        );
    }
    
    function hasVoted(uint256 proposalId, address voter) public view returns (bool) {
        return proposals[proposalId].hasVoted[voter];
    }
    
    function getVotes(uint256 proposalId, address voter) public view returns (uint256) {
        return proposals[proposalId].votes[voter];
    }
    
    // Safe functions
    function unpause() public {
        require(msg.sender == admin, "Not admin");
        paused = false;
    }
    
    function transferAdmin(address newAdmin) public {
        require(msg.sender == admin, "Not admin");
        require(newAdmin != address(0), "Zero address");
        admin = newAdmin;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }
}