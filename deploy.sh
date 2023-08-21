#!/usr/bin/env bash
dfx stop
set -e
# trap 'dfx stop' EXIT
trap 'echo "DONE"' EXIT

dfx start --background --clean

dfx canister create dnft_backend
dfx canister create dnft_frontend
dfx canister create internet_identity


dfx build

dfx canister install internet_identity
dfx canister install dnft_frontend

dfx deploy --argument "(principal\"$(dfx identity get-principal)\")" dnft_backend

echo "Creating dNFT"

dfx canister call dnft_backend mintNFTWithLinkWithoutTo '("url:sample_link")'

echo "dNFT has been created!"

# echo "Metadata: "

# dfx canister call dnft_backend getMetadataDip721 "0"

echo " "

# echo "Call Verification canister for current principal"

# dfx canister call ver init $(dfx identity get-principal)

# echo "Call Reputation canister and increase reputation balance for current user"

# dfx canister call rep incrementBalance '("'$(dfx identity get-principal)'", 1)'

# echo "dNFT metadata will track reputation balance changes!"


