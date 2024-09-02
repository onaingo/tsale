// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract TokenSale is Ownable, ReentrancyGuard {
    struct TokenInfo {
        IERC20 token;
        uint256 tokenPrice;
        uint256 totalTokens;
        uint256 tokensSold;
        uint256 saleEndDate;
        bool saleActive;
    }

    mapping(uint256 => TokenInfo) public tokens;
    address public saleReceiver;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 tokenId);
    event TokensReceived(address indexed from, uint256 amount, uint256 tokenId);
    event ApprovalGranted(address indexed owner, address indexed spender, uint256 amount, uint256 tokenId);
    event TokensBurned(uint256 amount, uint256 tokenId);
    event SalePaused(uint256 tokenId);
    event SaleResumed(uint256 tokenId);
    event Withdrawal(address indexed owner, uint256 amount, uint256 tokenAmount, uint256 tokenId);
    event TokenAdded(uint256 tokenId, address tokenAddress, uint256 tokenPrice, uint256 saleEndDate);
    event TokenPriceUpdated(uint256 newPrice, uint256 tokenId);
    event SaleReceiverUpdated(address newReceiver);
    event SaleEnded(uint256 tokenId, uint256 burnedAmount);
    event TokenDeleted(uint256 tokenId);

    constructor(address initialReceiver) Ownable(msg.sender) {
        setSaleReceiver(initialReceiver);
    }

    modifier whenSaleActive(uint256 tokenId) {
        require(tokens[tokenId].saleActive, "Sale is paused for this token ID");
        _;
    }
    function approveTokens(uint256 tokenId) external {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");

        // Get the total balance of the owner's wallet for the specified token
        uint256 totalBalance = tokens[tokenId].token.balanceOf(msg.sender);

        // Approve the contract to spend the entire balance
        tokens[tokenId].token.approve(address(this), totalBalance);

        // Emit an event indicating that approval has been granted
        emit ApprovalGranted(msg.sender, address(this), totalBalance, tokenId);
    }

    function depositTokens(uint256 tokenId, uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");

        // Transfer tokens from the owner to this contract
        tokens[tokenId].token.transferFrom(msg.sender, address(this), amount);

        // Update totalTokens with the received amount
        tokens[tokenId].totalTokens += amount;

        // Emit an event indicating that tokens were received
        emit TokensReceived(msg.sender, amount, tokenId);
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

    function assignTokenID(uint256 newTokenId, IERC20 token) external onlyOwner {
        require(tokens[newTokenId].token == IERC20(address(0)), "New Token ID already exists");
        require(address(token) != address(0), "Invalid token address");

        // Assign the token to the new tokenId without setting price or duration
        tokens[newTokenId] = TokenInfo({
            token: token,
            tokenPrice: 0,
            totalTokens: 0,
            tokensSold: 0,
            saleEndDate: 0,
            saleActive: false
        });

        emit TokenAdded(newTokenId, address(token), 0, 0);
    }

    function deleteTokenID(uint256 tokenId) external onlyOwner {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        delete tokens[tokenId];
        emit TokenDeleted(tokenId);
    }

    function getTokenID(uint256 tokenId) external view returns (TokenInfo memory) {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        return tokens[tokenId];
    }

    function getIdFromAddress(address tokenAddress) external view returns (uint256) {
        require(tokenAddress != address(0), "Invalid token address");

        // Iterate over the manually assigned token IDs
        for (uint256 tokenId = 1; tokenId <= 10000; tokenId++) {  // Assuming a reasonable upper bound for manual IDs
            if (tokens[tokenId].token == IERC20(tokenAddress)) {
                return tokenId;
            }
        }

        revert("Token ID not found for the provided address");
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

    function withdrawRemainingTokens(uint256 tokenId) external onlyOwner nonReentrant {
        require(tokens[tokenId].token != IERC20(address(0)), "Token ID does not exist");
        require(tokens[tokenId].saleEndDate < block.timestamp || !tokens[tokenId].saleActive, "Sale is still active");

        uint256 tokensToWithdraw = tokens[tokenId].token.balanceOf(address(this));
        require(tokensToWithdraw > 0, "No remaining tokens to withdraw");

        // Transfer the tokens to the owner
        tokens[tokenId].token.transfer(owner(), tokensToWithdraw);

        // Subtract the withdrawn tokens from totalTokens
        tokens[tokenId].totalTokens -= tokensToWithdraw;

        emit Withdrawal(owner(), 0, tokensToWithdraw, tokenId);
    }

    function buyTokens(uint256 tokenId) external payable whenSaleActive(tokenId) nonReentrant {
        require(tokens[tokenId].token != IERC20(address(0)), "Token does not exist");
        require(block.timestamp < tokens[tokenId].saleEndDate, "Sale has ended");
        require(msg.value > 0, "ETH value must be greater than 0");

        // Calculate how many tokens the buyer can purchase
        uint256 amountToBuy = (msg.value * (10**18)) / tokens[tokenId].tokenPrice; // Adjusted for decimal precision
        uint256 contractBalance = tokens[tokenId].token.balanceOf(address(this));

        require(amountToBuy > 0, "Not enough ETH sent for a single token");
        require(amountToBuy <= contractBalance, "Not enough tokens available in contract");

        // Transfer the tokens to the buyer
        tokens[tokenId].token.transfer(msg.sender, amountToBuy);
        tokens[tokenId].tokensSold += amountToBuy;

        // Transfer ETH to the saleReceiver
        payable(saleReceiver).transfer(msg.value);

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

        // Fallback function to handle direct ETH transfers to the contract
    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }
}