// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title DenialOfService
 * @dev VULNERABLE - Denial of Service (DoS) Attacks (SWC-113)
 * @notice Demonstrates various DoS attack vectors
 * Reference: OWASP Smart Contract Top 10 - SC10:2025 (Denial of Service)
 * https://owasp.org/www-project-smart-contract-top-10/2025/en/src/SC10-denial-of-service.html
 */

contract DenialOfService {
    address[] public users;
    mapping(address => uint256) public balances;

    // VULNERABLE: Unbounded loop can consume excessive gas
    function distributeRewards(uint256 reward) public {
        // If users array is large, this will exceed gas limit
        for (uint256 i = 0; i < users.length; i++) {
            balances[users[i]] += reward;
        }
    }

    function addUser(address user) public {
        users.push(user);
    }

    // VULNERABLE: Transfer to all participants can be blocked by one bad actor
    function refundAll() public {
        for (uint256 i = 0; i < users.length; i++) {
            // If one user is a contract that reverts, entire transaction fails
            (bool success,) = payable(users[i]).call{ value: balances[users[i]] }("");
            require(success, "Refund failed");
        }
    }

    // VULNERABLE: External call that can be exploited for gas bombing
    function executeCallback(address target, bytes memory data) public {
        // Attacker can make this function do arbitrary operations
        (bool success,) = target.call(data);
        require(success, "Call failed");
    }

    // VULNERABLE: Accessing storage in loop is expensive
    uint256[] public data;

    function processData() public {
        // Reading from storage in a loop is expensive
        for (uint256 i = 0; i < data.length; i++) {
            data[i] = data[i] + 1; // Storage write in loop = expensive
        }
    }

    // VULNERABLE: No pagination or limits
    function getAll() public view returns (address[] memory) {
        return users; // Large array causes issues
    }

    // VULNERABLE: Recursive function without depth limit
    uint256 public recursionCount = 0;

    function recursiveCall(uint256 depth) public {
        recursionCount++;
        if (depth > 0) {
            recursiveCall(depth - 1); // Can cause stack overflow
        }
    }
}

/**
 * @title SafeDOS
 * @dev SECURE - Protection against DoS attacks
 * Reference: OWASP Smart Contract Top 10 - SC10:2025
 */

contract SafeDOS {
    address[] public users;
    mapping(address => uint256) public balances;
    uint256 public constant MAX_USERS = 1000;
    uint256 public constant BATCH_SIZE = 10;

    // SECURE: Pagination and batch processing
    function distributeRewards(uint256 reward, uint256 startIndex, uint256 endIndex) public {
        require(endIndex > startIndex, "Invalid range");
        require(endIndex - startIndex <= BATCH_SIZE, "Batch too large");
        require(endIndex <= users.length, "Index out of bounds");

        for (uint256 i = startIndex; i < endIndex; i++) {
            balances[users[i]] += reward;
        }
    }

    function addUser(address user) public {
        require(users.length < MAX_USERS, "Maximum users reached");
        require(user != address(0), "Invalid user");
        users.push(user);
    }

    // SECURE: Refunds with pull pattern instead of push
    mapping(address => uint256) public pendingRefunds;

    function claimRefund() public {
        uint256 amount = pendingRefunds[msg.sender];
        require(amount > 0, "No refund pending");
        pendingRefunds[msg.sender] = 0;

        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Refund failed");
    }

    function initiateRefunds(address[] memory refundUsers) public {
        require(refundUsers.length <= BATCH_SIZE, "Too many refunds");
        for (uint256 i = 0; i < refundUsers.length; i++) {
            pendingRefunds[refundUsers[i]] = balances[refundUsers[i]];
        }
    }

    // SECURE: Limited external call scope
    uint256 public callLimit = 10_000;

    function executeCallback(address target, bytes memory data) public {
        require(data.length <= callLimit, "Data too large");
        (bool success,) = target.call{ gas: 50_000 }(data); // Limited gas
        // Don't require success - handle failure gracefully
    }

    // SECURE: Batch processing with memory
    uint256[] public data;

    function processData(uint256 startIndex, uint256 endIndex) public {
        require(endIndex > startIndex, "Invalid range");
        require(endIndex - startIndex <= BATCH_SIZE, "Batch too large");

        for (uint256 i = startIndex; i < endIndex; i++) {
            data[i] = data[i] + 1;
        }
    }

    // SECURE: Paginated retrieval
    function getUsers(uint256 offset, uint256 limit) public view returns (address[] memory) {
        require(limit <= BATCH_SIZE, "Limit too large");
        require(offset < users.length, "Offset out of bounds");

        uint256 end = offset + limit > users.length ? users.length : offset + limit;
        address[] memory result = new address[](end - offset);

        for (uint256 i = 0; i < end - offset; i++) {
            result[i] = users[offset + i];
        }

        return result;
    }

    // SECURE: Depth-limited recursion
    uint256 public maxDepth = 10;

    function recursiveCall(uint256 depth) public {
        require(depth <= maxDepth, "Recursion depth exceeded");
        if (depth > 0) {
            recursiveCall(depth - 1);
        }
    }

    // SECURE: Circuit breaker pattern
    bool public emergencyStop = false;

    modifier whenNotStopped() {
        require(!emergencyStop, "Contract is stopped");
        _;
    }

    function emergencyWithdraw() public whenNotStopped {
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Withdrawal failed");
    }

    function toggleEmergencyStop() public {
        emergencyStop = !emergencyStop;
    }
}

/**
 * @title RateLimitedContract
 * @dev SECURE - Rate limiting to prevent DoS
 */
contract RateLimitedContract {
    mapping(address => uint256) public lastCall;
    uint256 public constant RATE_LIMIT = 1 minutes;

    modifier rateLimit() {
        require(block.timestamp >= lastCall[msg.sender] + RATE_LIMIT, "Rate limit exceeded");
        lastCall[msg.sender] = block.timestamp;
        _;
    }

    function limitedOperation() public rateLimit {
        // Protected operation
    }
}
