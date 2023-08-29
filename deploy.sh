#!/usr/bin/env bash
dfx stop
# set -e
# trap 'dfx stop' EXIT
trap 'echo "DONE"' EXIT

dfx start --background --clean

dfx canister create dnft_backend
dfx canister create dnft_frontend
# dfx canister create internet_identity


dfx build

# dfx canister install internet_identity
dfx canister install dnft_frontend

dfx deploy --argument "(principal\"$(dfx identity get-principal)\")" dnft_backend

echo "Creating dNFT"

dfx canister call dnft_backend mintNFTWithLinkWithoutTo '("url:sample_link")'

echo "dNFT has been created!"

echo " "



