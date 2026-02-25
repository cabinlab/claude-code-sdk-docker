# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository provides ready-to-use Docker containers with the Claude Agent SDK and CLI pre-installed and pre-configured for non-interactive use. The CLI normally requires an interactive OAuth flow and onboarding wizard on first run, which is impractical in containers. These images handle that setup automatically.

## Key Problem Being Solved

The Claude CLI's first-run experience involves interactive prompts (onboarding wizard, project trust dialogs) that don't work in headless containers. While the CLI natively supports `CLAUDE_CODE_OAUTH_TOKEN` as an env var for authentication, it still expects onboarding and trust acceptance to have been completed.

Our solution: The entrypoint script pre-provisions the CLI configuration files (`~/.claude.json`, `~/.claude/.credentials.json`) so the CLI starts in a fully configured state — no interactive prompts needed. Users run `claude setup-token` on their host machine to generate a long-lived access token (`sk-ant-oat01-*`) and pass it to the container as an environment variable.

## Architecture Decisions

### Authentication Strategy
- Primary method: `CLAUDE_CODE_OAUTH_TOKEN` environment variable with long-lived tokens
- The entrypoint pre-provisions credential files and onboarding state so the CLI works non-interactively
- Fallback support for interactive auth (via `docker exec`) and direct API keys

### Image Structure
1. **Base TypeScript image** (`Dockerfile.typescript`):
   - Provides Claude Agent SDK CLI + SDK for JavaScript/TypeScript
   - Includes tsx for direct TypeScript execution
   - Sets up non-root user and proper permissions

2. **Python extension** (`Dockerfile`):
   - Extends the TypeScript base (multi-language support)
   - Adds Python 3.11 and claude-agent-sdk-python
   - Maintains all JS/TS capabilities

### Repository Structure
- `examples/` - Demonstration code showing SDK usage in each language
- `scripts/` - Authentication helpers and test scripts
- `compose.yaml` - Docker Compose configuration with proper environment variable handling
- `.claude/` - Claude CLI configuration scaffolding (copied into containers)

## Development Guidelines

When modifying this repository:
1. Maintain compatibility with long-lived OAuth tokens as the primary auth method
2. Ensure examples work with token-based authentication
3. Keep the non-root user setup for security best practices
4. Test that authentication works in both TypeScript and Python environments
5. Document any new environment variables or configuration options in the README