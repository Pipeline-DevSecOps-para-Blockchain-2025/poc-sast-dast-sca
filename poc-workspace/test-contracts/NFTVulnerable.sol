// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * NFT Vulnerable Contract for Testing
 * 
 * This contract contains NFT-specific vulnerabilities commonly found
 * in non-fungible token implementations.
 */

contract NFTVulnerable {
    mapping(uint256 => address) public owners;
    mapping(address => uint256) public balances;
    mapping(uint256 => address) public tokenApprovals;
    mapping(address => mapping(address => bool)) public operatorApprovals;
    mapping(uint256 => string) public tokenURIs;
    
    uint256 public totalSupply;
    uint256 public nextTokenId = 1;
    address public owner;
    uint256 public mintPrice = 0.1 ether;
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    
    constructor() {
        owner = msg.sender;
    }
    
    // Vulnerability 1: Reentrancy in NFT transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        require(owners[tokenId] == from, "Not owner");
        require(msg.sender == from || tokenApprovals[tokenId] == msg.sender || operatorApprovals[from][msg.sender], "Not approved");
        
        // Vulnerable: External call before state change
        if (to.code.length > 0) {
            (bool success, ) = to.call(abi.encodeWithSignature("onERC721Received(address,address,uint256,bytes)", msg.sender, from, tokenId, ""));
            require(success, "Transfer rejected");
        }
        
        // State changes after external call (vulnerable)
        owners[tokenId] = to;
        balances[from]--;
        balances[to]++;
        delete tokenApprovals[tokenId];
        
        emit Transfer(from, to, tokenId);
    }
    
    // Vulnerability 2: Missing access control on mint
    function mint(address to, string memory uri) public {
        // Vulnerable: No access control
        uint256 tokenId = nextTokenId++;
        owners[tokenId] = to;
        balances[to]++;
        tokenURIs[tokenId] = uri;
        totalSupply++;
        
        emit Transfer(address(0), to, tokenId);
    }
    
    // Vulnerability 3: Integer overflow in batch operations
    function batchMint(address[] memory recipients) public {
        // Vulnerable: No check for array length, can cause gas issues
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i], "");
        }
    }
    
    // Vulnerability 4: Metadata manipulation
    function setTokenURI(uint256 tokenId, string memory uri) public {
        // Vulnerable: Anyone can change metadata
        tokenURIs[tokenId] = uri;
    }
    
    // Vulnerability 5: Price manipulation in minting
    function publicMint() public payable {
        require(msg.value >= mintPrice, "Insufficient payment");
        
        // Vulnerable: No refund for overpayment
        mint(msg.sender, "default");
    }
    
    // Vulnerability 6: Approval race condition
    function approve(address to, uint256 tokenId) public {
        address tokenOwner = owners[tokenId];
        require(msg.sender == tokenOwner || operatorApprovals[tokenOwner][msg.sender], "Not authorized");
        
        // Vulnerable: Race condition with transferFrom
        tokenApprovals[tokenId] = to;
        emit Approval(tokenOwner, to, tokenId);
    }
    
    // Vulnerability 7: Unchecked external call in royalty payment
    function payRoyalty(uint256 tokenId, uint256 salePrice) public {
        address tokenOwner = owners[tokenId];
        uint256 royalty = (salePrice * 5) / 100; // 5% royalty
        
        // Vulnerable: Unchecked external call
        (bool success, ) = tokenOwner.call{value: royalty}("");
        // No require(success) - silent failure
    }
    
    // Vulnerability 8: Weak randomness for token generation
    function generateRandomTokenId() public view returns (uint256) {
        // Vulnerable: Predictable randomness
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender)));
    }
    
    // Vulnerability 9: Missing zero address check
    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "Not owner");
        // Vulnerable: No zero address check
        owner = newOwner;
    }
    
    // Vulnerability 10: Unprotected burn function
    function burn(uint256 tokenId) public {
        // Vulnerable: Anyone can burn any token
        address tokenOwner = owners[tokenId];
        
        delete owners[tokenId];
        delete tokenApprovals[tokenId];
        delete tokenURIs[tokenId];
        balances[tokenOwner]--;
        totalSupply--;
        
        emit Transfer(tokenOwner, address(0), tokenId);
    }
    
    // Vulnerability 11: Batch operation without gas limit check
    function batchTransfer(address to, uint256[] memory tokenIds) public {
        // Vulnerable: No gas limit consideration
        for (uint256 i = 0; i < tokenIds.length; i++) {
            safeTransferFrom(msg.sender, to, tokenIds[i]);
        }
    }
    
    // Vulnerability 12: Marketplace integration without proper checks
    function marketplaceBuy(uint256 tokenId) public payable {
        address seller = owners[tokenId];
        uint256 price = 1 ether; // Fixed price for simplicity
        
        require(msg.value >= price, "Insufficient payment");
        
        // Vulnerable: Payment sent before ownership transfer
        (bool success, ) = seller.call{value: msg.value}("");
        require(success, "Payment failed");
        
        // Transfer after payment (vulnerable to reentrancy)
        owners[tokenId] = msg.sender;
        balances[seller]--;
        balances[msg.sender]++;
        
        emit Transfer(seller, msg.sender, tokenId);
    }
    
    // Safe functions
    function ownerOf(uint256 tokenId) public view returns (address) {
        return owners[tokenId];
    }
    
    function balanceOf(address owner_) public view returns (uint256) {
        return balances[owner_];
    }
    
    function getApproved(uint256 tokenId) public view returns (address) {
        return tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner_, address operator) public view returns (bool) {
        return operatorApprovals[owner_][operator];
    }
    
    function setApprovalForAll(address operator, bool approved) public {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return tokenURIs[tokenId];
    }
    
    // Emergency functions
    function emergencyWithdraw() public {
        require(msg.sender == owner, "Not owner");
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {}
}