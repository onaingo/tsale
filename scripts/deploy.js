async function main() {
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Get the contract factory for TokenSale
  const TokenSale = await ethers.getContractFactory("TokenSale");
  const saleReceiver = "0xDaAC417BdA0Ca44F94bd9fAE3fDf0e468ab9A081"; // Replace with your actual sale receiver address

  // Deploy the contract
  const tokenSale = await TokenSale.deploy(saleReceiver);

  // Wait for deployment to be mined and confirm with additional confirmations
  const txReceipt = await tokenSale.deploymentTransaction().wait(3);  // Wait for 3 confirmations

  // Log the deployed contract's address
  console.log("TokenSale contract deployed to:", txReceipt.contractAddress);

  // Optional: Verify the contract on Etherscan with force flag
  await hre.run("verify:verify", {
    address: txReceipt.contractAddress,
    constructorArguments: [saleReceiver],
    force: true,  // Forces re-verification
  });
}

// Run the script
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
