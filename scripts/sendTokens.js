const ethers = require("ethers");
require("dotenv").config();

// Load environment variables from .env file
const providerUrl = process.env.ALCHEMY_API_URL;
const privateKey = process.env.PRIVATE_KEY;
const contractAddress = process.env.CONTRACT_ADDRESS;
const tokenId = 1;  // Replace with your actual token ID

// ABI of your TokenSale contract
const contractABI = [
  "function approveTokens(uint256 tokenId) external",
  "function depositTokens(uint256 tokenId, uint256 amount) external",
  "function tokens(uint256 tokenId) view returns (address token, uint256 tokenPrice, uint256 totalTokens, uint256 tokensSold, uint256 saleEndDate, bool saleActive)"
];

async function approveAndDepositTokens() {
  const provider = new ethers.JsonRpcProvider(providerUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  // Get the contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  // Get the token address and decimals from the contract using the tokenId
  const tokenDetails = await contract.tokens(tokenId);
  const tokenAddress = tokenDetails[0];

  // Create an instance of the ERC20 token contract
  const tokenContract = new ethers.Contract(tokenAddress, [
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function balanceOf(address account) external view returns (uint256)",
    "function decimals() external view returns (uint8)",
    "function totalSupply() external view returns (uint256)"
  ], wallet);

  // Get the total supply of the token
  const totalSupply = await tokenContract.totalSupply();

  // Get the number of decimals for the token
  const decimals = await tokenContract.decimals();

  // Calculate the amount to deposit: (totalSupply / 2) - 1
  // Do the calculation in wei to avoid fractional values
  const totalSupplyInUnits = ethers.formatUnits(totalSupply, decimals); // Convert to human-readable format
  const totalSupplyNumber = parseFloat(totalSupplyInUnits); // Convert to JavaScript number for math
  let amountToDepositNumber = Math.floor(totalSupplyNumber / 2) - 1; // Perform the division and subtraction

  // Convert back to BigInt for ethers.js with the correct decimals
  const amountToDeposit = ethers.parseUnits(amountToDepositNumber.toString(), decimals);

  // Step 1: Approve the calculated amount for spending by the contract
  console.log(`Approving ${totalSupplyInUnits} tokens...`);
  const approveTx = await tokenContract.approve(contractAddress, totalSupply);
  await approveTx.wait();  // Wait for the approval transaction to be mined
  console.log("Tokens approved!");

  // Step 2: Deposit tokens into the contract
  console.log(`Depositing ${amountToDepositNumber} tokens...`);
  const depositTx = await contract.depositTokens(tokenId, amountToDeposit);
  await depositTx.wait();  // Wait for the transaction to be confirmed
  console.log(`${amountToDepositNumber} tokens deposited successfully!`);
}

// Execute the function
approveAndDepositTokens().catch((error) => {
  console.error("Error occurred:", error);
});
