#!/usr/bin/env bash
dfx stop
# set -e
# trap 'dfx stop' EXIT
trap 'echo "DONE"' EXIT

dfx start --background --clean

dfx canister create dnft_backend
dfx canister create dnft_frontend
dfx canister create icrc_backend 

dfx build

dfx canister install icrc_backend
dfx canister install dnft_frontend

dfx deploy --argument "(principal\"$(dfx identity get-principal)\")" dnft_backend

echo "Creating dNFT"

dfx canister call dnft_backend mintNFTWithLinkWithoutTo '("url:sample_link")'

echo "dNFT DIP721 has been created!"

dfx canister call icrc_backend mintDemo '("url:sample_link_for ICRC7")'

echo "dNFT ICRC7 has been created!"

echo " "



