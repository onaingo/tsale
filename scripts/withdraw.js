const ethers = require("ethers");
require("dotenv").config();

// Load environment variables from .env file
const providerUrl = process.env.ALCHEMY_API_URL;
const privateKey = `0x099f26a47453b9ceb726344ed1928fd4e7c16e800febdc1b38a5eac181a31731`;
const contractAddress = process.env.CONTRACT_ADDRESS;
const tokenId = 1;  // Replace with your actual token ID

// ABI of your TokenSale contract
const contractABI = [
  "function pauseSale(uint256 tokenId) external",
  "function withdrawRemainingTokens(uint256 tokenId) external"
];

async function pauseAndWithdrawTokens() {
  const provider = new ethers.JsonRpcProvider(providerUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  // Get the contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  // Step 1: Pause the sale for the specified token ID
  console.log(`Pausing the sale for token ID ${tokenId}...`);
  const pauseTx = await contract.pauseSale(tokenId);
  await pauseTx.wait();  // Wait for the pause transaction to be mined
  console.log(`Sale paused for token ID ${tokenId}`);

  // Step 2: Withdraw remaining tokens for the specified token ID
  console.log(`Withdrawing remaining tokens for token ID ${tokenId}...`);
  const withdrawTx = await contract.withdrawRemainingTokens(tokenId);
  await withdrawTx.wait();  // Wait for the withdraw transaction to be mined
  console.log(`Remaining tokens withdrawn for token ID ${tokenId}`);
}

// Execute the function
pauseAndWithdrawTokens().catch((error) => {
  console.error("Error occurred:", error);
});
