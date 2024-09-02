# Deploy the TokenSale contract
1.) Run this command after installing all yarn dependencies
npx hardhat run scripts/deploy.js --network sepolia

2.) Replace the ENV contract variable with the new sale contract
3.) Update any other dotenv variables as necessary

# functions commands:
NOTE: Make sure to run these scripts in the root directory.

1.) Create the token sale.
    a.) Update the token ID to match seqid.
    b.) Replace token address with the new FNFT contract address.
node scripts/createSale.js

2.) Approve tokens and deposit to contract.
    a.) Update token id to match current contract seqid.
node scripts/sendTokens.js