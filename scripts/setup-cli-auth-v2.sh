#!/bin/bash

# Setup Claude CLI authentication using OAuth token - Version 2
# This version creates both .credentials.json and .claude.json

set -e

if [ -z "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo "Error: CLAUDE_CODE_OAUTH_TOKEN environment variable is not set"
    exit 1
fi

# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Create .credentials.json in .claude directory
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

# Create .claude.json in home directory with OAuth account info
# This mimics what the CLI creates during normal authentication
cat > ~/.claude.json << EOF
{
  "numStartups": 1,
  "installMethod": "unknown",
  "autoUpdates": true,
  "firstStartTime": "$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)",
  "userID": "$(echo -n "$USER$(date +%s)" | sha256sum | cut -d' ' -f1)",
  "projects": {
    "/app": {
      "allowedTools": [],
      "history": [],
      "mcpContextUris": [],
      "mcpServers": {},
      "enabledMcpjsonServers": [],
      "disabledMcpjsonServers": [],
      "hasTrustDialogAccepted": true,
      "projectOnboardingSeenCount": 1,
      "hasClaudeMdExternalIncludesApproved": false,
      "hasClaudeMdExternalIncludesWarningShown": false
    }
  },
  "oauthAccount": {
    "accountUuid": "00000000-0000-0000-0000-000000000001",
    "emailAddress": "docker@claude-sdk.local",
    "organizationUuid": "00000000-0000-0000-0000-000000000002",
    "organizationRole": "admin",
    "workspaceRole": null,
    "organizationName": "Claude SDK Docker"
  },
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "1.0.53",
  "subscriptionNoticeCount": 0,
  "hasAvailableSubscription": true
}
EOF

# Set proper permissions
chmod 600 ~/.claude/.credentials.json
chmod 600 ~/.claude.json

echo "Claude CLI authentication configured successfully (v2)"
echo "Created both .credentials.json and .claude.json"