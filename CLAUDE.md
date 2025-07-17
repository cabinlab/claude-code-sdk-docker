# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This repository develops best-practice Docker containers for the Claude Code SDK and CLI that solve the authentication problem in containerized environments. The standard Claude Code OAuth flow is interactive and browser-based, which doesn't work well in containers. This project implements long-lived access token support as the solution.

## Key Problem Being Solved

The Claude Code SDK attempts to use the CLI auth flow (invoked by `claude`) to create session-based OAuth tokens. This requires frequently using the CLI to manually exec into containers to reauth, as the interactive process requires a web browser. In containerized environments, this creates several problems:
- Containers typically don't have GUI/browser access
- Session tokens expire, requiring repeated manual intervention
- Standard Docker practices conflict with interactive authentication inside containers

Our solution: Move the CLI authentication work outside the container. Users run `claude setup-token` on their host machine to generate a long-lived access token (`sk-ant-oat01-*`), which can then be passed to containers as an environment variable, eliminating the need for interactive authentication inside containers.

## Architecture Decisions

### Authentication Strategy
- Primary method: `CLAUDE_CODE_OAUTH_TOKEN` environment variable with long-lived tokens
- The containers modify the standard authentication flow to accept tokens via environment variables
- Fallback support for legacy session tokens and direct API keys

### Image Structure
1. **Base TypeScript image** (`Dockerfile.typescript`):
   - Provides Claude Code CLI + SDK for JavaScript/TypeScript
   - Includes tsx for direct TypeScript execution
   - Sets up non-root user and proper permissions

2. **Python extension** (`Dockerfile`):
   - Extends the TypeScript base (multi-language support)
   - Adds Python 3.11 and claude-code-sdk-python
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