#!/bin/bash

# op-aws-credentials.sh - Simple AWS credential process for 1Password
# Usage: op-aws-credentials.sh <item-name> [vault-name]
# In ~/.aws/config, add credential_process = <path>/op-aws-credentials.sh "<op-entry-name>" "<op-profile>" to base profile

set -euo pipefail

# Check if op is installed
if ! command -v op &> /dev/null; then
    echo "Error: 1Password CLI (op) is not installed" >&2
    exit 1
fi

# Get arguments
ITEM_NAME="${1:-}"
VAULT_NAME="${2:-}"

if [ -z "$ITEM_NAME" ]; then
    echo "Error: Item name is required" >&2
    echo "Usage: $0 <item-name> [vault-name]" >&2
    exit 1
fi

# Build vault option if specified
VAULT_OPT=""
if [ -n "$VAULT_NAME" ]; then
    VAULT_OPT="--vault \"$VAULT_NAME\""
fi

# Get credentials directly using op item get with field names
ACCESS_KEY_ID=$(eval "op item get \"$ITEM_NAME\" --fields \"access key id\" --reveal $VAULT_OPT" 2>/dev/null || \
                eval "op item get \"$ITEM_NAME\" --fields \"access_key_id\" --reveal $VAULT_OPT" 2>/dev/null || \
                eval "op item get \"$ITEM_NAME\" --fields \"Access Key ID\" --reveal $VAULT_OPT" 2>/dev/null || \
                eval "op item get \"$ITEM_NAME\" --fields \"AWS_ACCESS_KEY_ID\" --reveal $VAULT_OPT" 2>/dev/null || \
                echo "")

SECRET_ACCESS_KEY=$(eval "op item get \"$ITEM_NAME\" --fields \"secret access key\" --reveal $VAULT_OPT" 2>/dev/null || \
                    eval "op item get \"$ITEM_NAME\" --fields \"secret_access_key\" --reveal $VAULT_OPT" 2>/dev/null || \
                    eval "op item get \"$ITEM_NAME\" --fields \"Secret Access Key\" --reveal $VAULT_OPT" 2>/dev/null || \
                    eval "op item get \"$ITEM_NAME\" --fields \"AWS_SECRET_ACCESS_KEY\" --reveal $VAULT_OPT" 2>/dev/null || \
                    echo "")

# Check if we found the credentials
if [ -z "$ACCESS_KEY_ID" ] || [ -z "$SECRET_ACCESS_KEY" ]; then
    echo "Error: Could not find AWS credentials in 1Password item" >&2
    echo "Make sure the item has fields named 'access key id' and 'secret access key'" >&2
    exit 1
fi

# Output credentials in the format expected by AWS credential_process
printf '{\n'
printf '  "Version": 1,\n'
printf '  "AccessKeyId": "%s",\n' "$ACCESS_KEY_ID"
printf '  "SecretAccessKey": "%s"\n' "$SECRET_ACCESS_KEY"
printf '}\n' 
