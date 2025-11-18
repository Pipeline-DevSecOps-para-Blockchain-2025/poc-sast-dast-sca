// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title InsecureRandomness
 * @dev VULNERABLE - Insecure Randomness (SWC-120)
 * @notice Demonstrates how block properties can be exploited for "randomness"
 * Reference: OWASP Smart Contract Top 10 - SC09:2025 (Insecure Randomness)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC09-insecure-randomness.html
 */

contract InsecureRandomness {
    uint256 public lastWinner;
    uint256 public jackpot;

    // VULNERABLE: Using block.timestamp as randomness source
    // Miners/validators can manipulate block.timestamp within limits
    function play() public payable {
        require(msg.value >= 0.1 ether, "Minimum bet is 0.1 ether");
        jackpot += msg.value;

        // Predictable "random" number
        uint256 number = uint256(keccak256(abi.encodePacked(block.timestamp))) % 100;

        if (number > 50) {
            lastWinner = uint256(uint160(msg.sender));
            uint256 payout = jackpot;
            jackpot = 0;
            (bool success,) = msg.sender.call{ value: payout }("");
            require(success, "Payout failed");
        }
    }

    // VULNERABLE: Using blockhash which is manipulable
    function unsafeRandom() public view returns (uint256) {
        return uint256(blockhash(block.number - 1)) % 1000;
    }

    // VULNERABLE: Using multiple block properties for "entropy"
    function lottery() public payable {
        require(msg.value >= 1 ether, "Minimum bet is 1 ether");

        // All of these can be influenced by miners
        bytes32 random = keccak256(
            abi.encodePacked(block.timestamp, block.difficulty, block.number, msg.sender, blockhash(block.number - 1))
        );

        if (uint256(random) % 10 == 0) {
            // Winner!
        }
    }

    // VULNERABLE: Nonce can be predicted
    uint256 public nonce = 0;

    function pseudoRandom() public returns (uint256) {
        nonce++;
        return uint256(keccak256(abi.encodePacked(nonce, block.timestamp))) % 100;
    }
}

/**
 * @title SecureRandomness
 * @dev SECURE - Using Chainlink VRF for verifiable randomness
 * Reference: OWASP Smart Contract Top 10 - SC09:2025
 */

interface IVRFConsumerBase {
    function requestRandomness(bytes32 keyHash, uint256 fee) external returns (bytes32 requestId);
}

contract SecureRandomness {
    bytes32 public lastRequestId;
    uint256 public lastRandomValue;
    mapping(bytes32 => uint256) public randomValues;

    // SECURE: Would use Chainlink VRF in production
    // Here showing the pattern for verifiable randomness
    function requestRandomness() public returns (bytes32) {
        // In production: return vrfCoordinator.requestRandomness(keyHash, fee);
        // For demonstration:
        lastRequestId = keccak256(abi.encodePacked(block.number, msg.sender));
        return lastRequestId;
    }

    // SECURE: Randomness is provided by external oracle
    function fulfillRandomness(bytes32 requestId, uint256 randomness) external {
        // In production, this would be called by the VRF coordinator
        randomValues[requestId] = randomness;
        lastRandomValue = randomness;
    }

    function getRandomness(bytes32 requestId) public view returns (uint256) {
        require(randomValues[requestId] != 0, "Randomness not fulfilled");
        return randomValues[requestId];
    }
}

/**
 * @title CommitRevealRandomness
 * @dev SECURE - Using commit-reveal pattern for on-chain randomness
 * Reference: OWASP Smart Contract Top 10 - SC09:2025
 */
contract CommitRevealRandomness {
    struct Round {
        mapping(address => bytes32) commits;
        mapping(address => uint256) reveals;
        bool finalized;
        uint256 finalRandomness;
        uint256 commitDeadline;
        uint256 revealDeadline;
    }

    mapping(uint256 => Round) public rounds;
    uint256 public roundCounter = 0;

    // SECURE: Two-phase commit-reveal protocol
    function startRound(uint256 commitDuration, uint256 revealDuration) public {
        roundCounter++;
        Round storage round = rounds[roundCounter];
        round.commitDeadline = block.timestamp + commitDuration;
        round.revealDeadline = block.timestamp + commitDuration + revealDuration;
    }

    function commit(uint256 roundId, bytes32 commitment) public {
        Round storage round = rounds[roundId];
        require(block.timestamp < round.commitDeadline, "Commit phase ended");
        round.commits[msg.sender] = commitment;
    }

    function reveal(uint256 roundId, uint256 value, bytes32 salt) public {
        Round storage round = rounds[roundId];
        require(block.timestamp >= round.commitDeadline, "Commit phase not ended");
        require(block.timestamp < round.revealDeadline, "Reveal phase ended");
        require(keccak256(abi.encodePacked(value, salt)) == round.commits[msg.sender], "Invalid reveal");

        round.reveals[msg.sender] = value;
    }

    function finalizeRound(uint256 roundId) public {
        Round storage round = rounds[roundId];
        require(block.timestamp >= round.revealDeadline, "Reveal phase not ended");
        require(!round.finalized, "Round already finalized");

        // Combine all reveals for final randomness
        uint256 combined = 0;
        // In production, would iterate through participants
        combined = uint256(keccak256(abi.encodePacked(block.number, combined))) % 1_000_000;

        round.finalRandomness = combined;
        round.finalized = true;
    }

    function getRandomness(uint256 roundId) public view returns (uint256) {
        require(rounds[roundId].finalized, "Round not finalized");
        return rounds[roundId].finalRandomness;
    }
}
