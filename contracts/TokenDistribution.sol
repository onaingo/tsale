// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenSale is Ownable, ReentrancyGuard {
    struct TokenInfo {
        IERC20 token;
        uint256 tokenPrice; // Price per token in wei
        uint256 totalTokens;
        uint256 tokensSold;
        uint256 saleEndDate; // Unix timestamp of sale end date
        bool saleActive;     // Indicates if the sale is active for this tokenId
    }

    mapping(uint256 => TokenInfo) public tokens;

    address public saleReceiver; // Address to receive the ETH for token sales

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 tokenId);
    event TokensBurned(uint256 amount, uint256 tokenId);
    event SalePaused(uint256 tokenId);
    event SaleResumed(uint256 tokenId);
    event Withdrawal(address indexed owner, uint256 amount, uint256 tokenAmount, uint256 tokenId);
    event TokenAdded(uint256 tokenId, address tokenAddress, uint256 tokenPrice, uint256 saleEndDate);
    event TokenPriceUpdated(uint256 newPrice, uint256 tokenId);
    event SaleReceiverUpdated(address newReceiver);
    event SaleEnded(uint256 tokenId, uint256 burnedAmount);
    event TokenDeleted(uint256 tokenId);
    event TokenReassigned(uint256 oldTokenId, uint256 newTokenId);

    constructor(address initialReceiver) Ownable(msg.sender) {
        setSaleReceiver(initialReceiver);
    }

    modifier whenSaleActive(uint256 tokenId) {
        require(tokens[tokenId].saleActive, "Sale is paused for this token ID");
        _;
    }

    function setSaleReceiver(address newReceiver) public onlyOwner {
        require(newReceiver != address(0), "Invalid receiver address");
        saleReceiver = newReceiver;
        emit SaleReceiverUpdated(newReceiver);
    }

    function addTokenSale(uint256 tokenId, IERC20 token, uint256 tokenPrice, uint256 duration) external onlyOwner {
        require(tokens[tokenId].token == IERC20(address(0)), "Token ID already exists");
        require(tokenPrice > 0, "Price must be greater than 0");
        require(address(token) != address(0), "Invalid token address");
        require(duration > 0, "Duration must be greater than 0");

        uint256 saleEndDate = block.timestamp + duration;

        tokens[tokenId] = TokenInfo({
            token: token,
            tokenPrice: tokenPrice,
            totalTokens: 0,
            tokensSold: 0,
            saleEndDate: saleEndDate,
            saleActive: true
        });

        emit TokenAdded(tokenId, address(token), tokenPrice, saleEndDate);
    }

    function deleteTokenID(uint256 tokenId) external onlyOwner {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        delete tokens[tokenId];  // Remove the token sale information
        emit TokenDeleted(tokenId);
    }

    function assignTokenID(uint256 oldTokenId, uint256 newTokenId) external onlyOwner {
        require(tokens[oldTokenId].token != IERC20(address(0)), "Old Token ID does not exist");
        require(tokens[newTokenId].token == IERC20(address(0)), "New Token ID already exists");

        tokens[newTokenId] = tokens[oldTokenId];
        delete tokens[oldTokenId];  // Remove the old token ID mapping
        emit TokenReassigned(oldTokenId, newTokenId);
    }

    function getTokenID(uint256 tokenId) external view returns (TokenInfo memory) {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        return tokens[tokenId];
    }

    function getContractFromID(uint256 tokenId) external view returns (address) {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        return address(tokens[tokenId].token);
    }

    function pauseSale(uint256 tokenId) external onlyOwner {
        require(tokens[tokenId].saleActive, "Sale is already paused");
        tokens[tokenId].saleActive = false;
        emit SalePaused(tokenId);
    }

    function resumeSale(uint256 tokenId) external onlyOwner {
        require(!tokens[tokenId].saleActive, "Sale is already active");
        tokens[tokenId].saleActive = true;
        emit SaleResumed(tokenId);
    }

    function buyTokens(uint256 tokenId) external payable whenSaleActive(tokenId) nonReentrant {
        require(tokens[tokenId].token != IERC20(address(0)), "Token does not exist");
        require(block.timestamp < tokens[tokenId].saleEndDate, "Sale has ended");

        uint256 amountToBuy = msg.value / tokens[tokenId].tokenPrice;
        uint256 contractBalance = tokens[tokenId].token.balanceOf(address(this));

        require(amountToBuy > 0, "Not enough ETH sent");
        require(amountToBuy <= contractBalance, "Not enough tokens available");

        tokens[tokenId].token.transfer(msg.sender, amountToBuy);
        tokens[tokenId].tokensSold += amountToBuy;

        uint256 excessPayment = msg.value - (amountToBuy * tokens[tokenId].tokenPrice);
        if (excessPayment > 0) {
            payable(msg.sender).transfer(excessPayment);
        }

        payable(saleReceiver).transfer(address(this).balance);

        emit TokensPurchased(msg.sender, amountToBuy, tokenId);
    }

    function remainingTokens(uint256 tokenId) external view returns (uint256) {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        return tokens[tokenId].token.balanceOf(address(this));
    }

    function burnRemainingTokens(uint256 tokenId) public onlyOwner nonReentrant {
        require(tokens[tokenId].token != IERC20(address(0)), "Token does not exist");

        uint256 remaining = tokens[tokenId].token.balanceOf(address(this));
        require(remaining > 0, "No remaining tokens to burn");

        tokens[tokenId].token.transfer(address(0), remaining);
        emit TokensBurned(remaining, tokenId);
    }

    function checkAndBurn(uint256 tokenId) external nonReentrant {
        require(block.timestamp >= tokens[tokenId].saleEndDate, "Sale has not ended yet");
        burnRemainingTokens(tokenId);
        emit SaleEnded(tokenId, tokens[tokenId].token.balanceOf(address(this)));
    }

    function getSaleEndTime(uint256 tokenId) external view returns (uint256) {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        return tokens[tokenId].saleEndDate;
    }

    function renounceOwnership() public override onlyOwner {
        transferOwnership(address(0));
    }
}