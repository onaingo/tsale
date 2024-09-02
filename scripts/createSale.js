const ethers = require("ethers");
require("dotenv").config();

// Load environment variables from .env file
const providerUrl = process.env.ALCHEMY_API_URL;
const privateKey = process.env.PRIVATE_KEY;
const contractAddress = process.env.CONTRACT_ADDRESS;

// ABI of your TokenSale contract
const contractABI = [
  "function addTokenSale(uint256 tokenId, address token, uint256 tokenPrice, uint256 duration) external",
];

// Parameters for the new token sale
const tokenId = 1;  // Replace with the desired token ID
const tokenAddress = "0x9FEC9c8315dA365a301F9Fe4DedF446191B3a21e";  // Replace with your actual token contract address
const tokenPrice = ethers.parseUnits("0.01", 18);  // Replace with your desired token price (0.01 ETH in this example)
const durationInMinutes = 30;  // Replace with your desired sale duration in minutes

async function addTokenSale() {
  const provider = new ethers.JsonRpcProvider(providerUrl);
  const wallet = new ethers.Wallet(privateKey, provider);

  // Get the contract instance
  const contract = new ethers.Contract(contractAddress, contractABI, wallet);

  // Convert duration from minutes to seconds
  const duration = durationInMinutes * 60;

  console.log(`Adding new token sale with ID: ${tokenId}...`);

  // Call the addTokenSale function
  const addTokenSaleTx = await contract.addTokenSale(tokenId, tokenAddress, tokenPrice, duration);
  await addTokenSaleTx.wait();  // Wait for the transaction to be confirmed

  console.log(`Token sale added successfully with ID: ${tokenId}`);
}

// Execute the function
addTokenSale().catch((error) => {
  console.error("Error occurred:", error);
});
