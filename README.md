# Dynamic NFT Canister (Prototype)

This canister implements customizable non-fungible tokens on the Internet Computer.

## Features

- Mint NFTs from any link 
- Manage NFT ownership
- Metadata generated from link
- Get owned NFTs
- View NFT minting history

## Usage

The main methods are:

- `mintNFTWithLink` - Mint an NFT from a provided link
- `mintNFTWithLinkWithoutTo` - Mint an NFT without specifying owner  
- `getDNftByUser` - Get the last NFT minted by a user

It also exposes queries to:

- `getAllNft` - Get all minted NFTs
- `getNftHistoryByUser` - Get a user's NFT minting history

## Technical Details

Implemented in Motoko with:

- `allNfts` - List of minted NFTs
- `transactionId` - Incrementing counter

State persists on the Internet Computer blockchain.

## Next Steps

This is a prototype, the next step is MVP.

## Running the project locally

If you want to test project locally, you can use the following commands:

```bash
# Starts the replica, running in the background
sh ./deploy.sh
```

Once the job completes, your application will be available at `http://localhost:{port}?canisterId={asset_canister_id}`.
