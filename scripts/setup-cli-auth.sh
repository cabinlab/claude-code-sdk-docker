#!/bin/bash

# Setup Claude CLI authentication using OAuth token
# This script creates the .credentials.json file that the CLI expects

set -e

if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Error: CLAUDE_CODE_OAUTH_TOKEN environment variable is not set"
    exit 1
fi

# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Create .credentials.json with the OAuth token
# The expiresAt is set to a far future date since this is a long-lived token
cat > ~/.claude/.credentials.json << EOF
{
  "claudeAiOauth": {
    "accessToken": "$CLAUDE_CODE_OAUTH_TOKEN",
    "refreshToken": "$CLAUDE_CODE_OAUTH_TOKEN",
    "expiresAt": "2099-12-31T23:59:59.999Z",
    "scopes": ["read", "write"],
    "subscriptionType": "pro"
  }
}
EOF

# Set proper permissions
chmod 600 ~/.claude/.credentials.json

echo "Claude CLI authentication configured successfully"