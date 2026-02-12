# Claude Agent SDK Docker Authentication Guide

This guide provides technical details about how authentication works in the Claude Agent SDK Docker containers.

**For setup instructions**, see the [README Quick Start](../README.md#quick-start-for-claude-pro-and-max-users).

## Table of Contents
- [How It Works](#how-it-works)
- [Authentication File Structure](#authentication-file-structure)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)

## Authentication Methods Supported

1. **Long-lived OAuth Tokens** (`sk-ant-oat01-*`) 1-year expiration
2. **Interactive Browser Authentication** - Session-based OAuth. Requires `docker exec` into container to perform manual CLI auth flow. Persists across container restarts, but shorter period to expiration
3. **Anthropic API Keys** (`sk-ant-api03-*`) - Should work by default. Direct API access (not tested as of July 2025) ⚠️ If set, likely overrides Pro/Max usage and uses API credits first

## How It Works

### Container Startup Process

When a container starts, the entrypoint script (`docker-entrypoint.sh`) performs the following:

1. **Checks for OAuth Token**: If `CLAUDE_CODE_OAUTH_TOKEN` is set, it automatically configures authentication
2. **Creates Credential Files**: 
   - `~/.claude/.credentials.json` - Contains the authentication token
   - `~/.claude.json` - Contains session configuration and user metadata
3. **Preserves Existing Sessions**: If `.claude.json` already exists (from a previous session), it's preserved

### Auth Persistence

The containers use Docker volumes to persist authentication data for all 3 methods:

```yaml
volumes:
  - claude-auth:/home/claude/.claude  # Persists CLI authentication
```

This ensures that:
- Manual authentication sessions persist across container restarts
- You don't need to re-authenticate after stopping/starting containers
- Multiple containers can share the same authentication volume

## Authentication File Structure

The authentication system creates two key files:

1. **`~/.claude/.credentials.json`** - Stores the actual authentication token:
   ```json
   {
     "claudeAiOauth": {
       "accessToken": "sk-ant-oat01-...",
       "refreshToken": "sk-ant-oat01-...",
       "expiresAt": "2099-12-31T23:59:59.999Z",
       "scopes": ["read", "write"],
       "subscriptionType": "pro"
     }
   }
   ```

2. **`~/.claude.json`** - Stores session configuration and metadata:
   ```json
   {
     "oauthAccount": {
       "accountUuid": "...",
       "emailAddress": "docker@claude-sdk.local",
       "organizationName": "Claude SDK Docker"
     },
     "hasCompletedOnboarding": true,
     "projects": {
       "/app": {
         "allowedTools": [],
         "hasTrustDialogAccepted": true
       }
     }
   }
   ```

## Troubleshooting

### Authentication Not Working

1. **Check token format**: Ensure your token starts with `sk-ant-oat01-`
2. **Verify environment variable**: Run `docker-compose config` to check if the token is being passed
3. **Check container logs**: 
   ```bash
   docker-compose logs typescript
   ```
   Look for "OAuth authentication setup complete"

### Session Not Persisting

1. **Verify volume mount**: Check that the `claude-auth` volume is properly mounted:
   ```bash
   docker volume ls | grep claude-auth
   ```

2. **Check file permissions**: The claude user should own the auth files:
   ```bash
   docker-compose exec typescript ls -la ~/.claude/
   ```

### Interactive Authentication Issues

If the CLI hangs during interactive auth:
1. Make sure you're running with TTY: `docker-compose exec -it typescript bash`
2. Complete the browser flow on your local machine
3. The CLI should automatically detect when authentication is complete

### Multiple Containers & Claude Accounts

#### Shared Authentication (Default)

By default, containers share the same authentication volume, allowing you to authenticate once and use the same credentials across TypeScript and Python containers:

```yaml
volumes:
  claude-auth:  # Shared volume for all containers
```

#### Separate Authentication Per Container

For increased security or when using different Claude accounts/methods per container, you can create separate volumes in `compose.yaml`:

```yaml
services:
  typescript:
    image: ghcr.io/[org]/claude-agent-sdk:typescript
    environment:
      - CLAUDE_CODE_OAUTH_TOKEN=${OAUTH_TOKEN_1}
    volumes:
      - claude-auth-dev:/home/claude/.claude
  
  python:
    image: ghcr.io/[org]/claude-agent-sdk:typescript
    environment:
      - CLAUDE_CODE_OAUTH_TOKEN=${OAUTH_TOKEN_2}
    volumes:
      - claude-auth-prod:/home/claude/.claude

volumes:
  claude-auth-dev:
  claude-auth-prod:
```

#### Mixed Authentication Methods

You can also mix authentication methods across containers:

```yaml
services:
  # OAuth token for development
  dev:
    image: ghcr.io/[org]/claude-agent-sdk:typescript
    environment:
      - CLAUDE_CODE_OAUTH_TOKEN=${OAUTH_TOKEN}
    volumes:
      - claude-auth-dev:/home/claude/.claude
  
  # API key for testing
  test:
    image: ghcr.io/[org]/claude-agent-sdk:typescript
    environment:
      - ANTHROPIC_API_KEY=${API_KEY}
    volumes:
      - claude-auth-test:/home/claude/.claude
  
  # Interactive auth
  experiment:
    image: ghcr.io/[org]/claude-agent-sdk:typescript
    volumes:
      - claude-auth-exp:/home/claude/.claude
    # No token - use 'docker exec' to authenticate interactively

volumes:
  claude-auth-dev:
  claude-auth-test:
  claude-auth-exp:
```

This approach provides:
- **Security isolation**: Each container has its own credentials
- **Account separation**: Use different Claude accounts per environment
- **Method flexibility**: Mix OAuth, API keys, and interactive auth as needed
- **Easy rotation**: Update individual tokens without affecting other containers

## Security Best Practices

1. **Use secrets in production**: For production deployments, use proper secret management
2. **Never commit tokens**: `.env` files are gitignored, but consider using environment variables as in 1 ☝️ to avoid accidental token exposure
3. **Rotate tokens**: Generate new tokens periodically for security