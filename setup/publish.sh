#!/bin/bash

# check dependencies are available.
for i in jq sui; do
  if ! command -V ${i} 2>/dev/null; then
    echo "${i} is not installed"
    exit 1
  fi
done

# default network is testnet
NETWORK="https://fullnode.devnet.sui.io:443"

# If otherwise specified chose testnet or devnet
if [ $# -ne 0 ]; then
  if [ $1 = "testnet" ]; then
    NETWORK="https://fullnode.testnet.sui.io:443"
  fi
  if [ $1 = "devnet" ]; then
    NETWORK="https://fullnode.devnet.sui.io:443"
  fi
fi

publish_res=$(sui client publish --gas-budget 200000000 --skip-dependency-verification --json ../mysticons)

echo ${publish_res} >.publish.res.json

if [[ "$publish_res" =~ "error" ]]; then
  # If yes, print the error message and exit the script
  echo "Error during move contract publishing.  Details : $publish_res"
  exit 1
fi
echo "Contract Deployment finished!"

echo "Setting up environmental variables..."

DIGEST=$(echo "${publish_res}" | jq -r '.digest')
PACKAGE_ID=$(echo "${publish_res}" | jq -r '.effects.created[] | select(.owner == "Immutable").reference.objectId')
newObjs=$(echo "$publish_res" | jq -r '.objectChanges[] | select(.type == "created")')
ADMIN_CAP_ID=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::genesis::AdminCap")).objectId')
PUBLISHER_ID=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::Publisher")).objectId')
UPGRADE_CAP_ID=$(echo "$newObjs" | jq -r 'select (.objectType | contains("::package::UpgradeCap")).objectId')


cat >src/.env <<-API_ENV
SUI_NETWORK=$NETWORK
DIGEST=$DIGEST
UPGRADE_CAP_ID=$UPGRADE_CAP_ID
PACKAGE_ID=$PACKAGE_ID
ADMIN_CAP_ID=$ADMIN_CAP_ID
PUBLISHER_ID=$PUBLISHER_ID
ADMIN_PHRASE=$ADMIN_PHRASE
ADMIN_ADDRESS=$ADMIN_ADDRESS
API_ENV

