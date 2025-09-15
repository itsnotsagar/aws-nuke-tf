#!/bin/bash

# Script to prepare aws-nuke config files with actual account information

set -e

ACCOUNT_ID="$1"
HAS_ALIAS="$2"
ACCOUNT_ALIAS="$3"

# Build your target filename
OUTPUT_FILE="config-prepared.yml"

if [ -z "$ACCOUNT_ID" ]; then
    echo "Error: ACCOUNT_ID is required"
    exit 1
fi

if [ "$HAS_ALIAS" = "true" ]; then
    if [ -z "$ACCOUNT_ALIAS" ]; then
        echo "Error: ACCOUNT_ALIAS is required when HAS_ALIAS is true"
        exit 1
    fi
    
    echo "Preparing config for account with alias: $ACCOUNT_ALIAS ($ACCOUNT_ID)"
    
    # Replace placeholders in config-with-alias.yml
    sed -e "s/{{ ACCOUNT_ID }}/$ACCOUNT_ID/g" -e "s/{{ ACCOUNT_ALIAS }}/$ACCOUNT_ALIAS/g" config-with-alias.yml > "$OUTPUT_FILE"
    
else
    echo "Preparing config for account without alias: $ACCOUNT_ID"
    
    # Replace placeholder in config-without-alias.yml
    sed "s/{{ ACCOUNT_ID }}/$ACCOUNT_ID/g" config-without-alias.yml > "$OUTPUT_FILE"
fi

echo "Config file prepared: $OUTPUT_FILE"
echo "Contents:"
cat "$OUTPUT_FILE"