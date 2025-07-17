#!/bin/bash

# Docker entrypoint script for Claude Code SDK containers
# Handles authentication setup and container initialization

set -e

# Function to setup authentication from OAuth token
setup_oauth_auth() {
    if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
        echo "Setting up Claude CLI authentication from OAuth token..."
        
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
        
        # Only create .claude.json if it doesn't exist (preserve existing session data)
        if [ ! -f ~/.claude.json ]; then
            echo "Creating new .claude.json..."
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
        fi
        
        # Set proper permissions
        chmod 600 ~/.claude/.credentials.json
        [ -f ~/.claude.json ] && chmod 600 ~/.claude.json
        
        echo "OAuth authentication setup complete"
    else
        echo "No CLAUDE_CODE_OAUTH_TOKEN found. You can:"
        echo "1. Set CLAUDE_CODE_OAUTH_TOKEN environment variable with a long-lived token"
        echo "2. Or authenticate interactively by running 'claude' in the container"
    fi
}

# Main entrypoint logic
echo "Starting Claude Code SDK container..."

# Setup authentication if OAuth token is provided
setup_oauth_auth

# Execute the command passed to docker run
exec "$@"