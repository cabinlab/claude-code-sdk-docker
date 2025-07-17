# Claude Code Docker SDK

[![Build and Publish](https://github.com/cabinlab/claude-code-sdk-docker/actions/workflows/build-and-publish.yml/badge.svg)](https://github.com/cabinlab/claude-code-sdk-docker/actions/workflows/build-and-publish.yml)

### Docker images with Official Claude Code SDK built-in. 

Images:

 -  TypeScript (727MB) - SDK and CLI are already included in the standard [@anthropic-ai/claude-code package](https://www.npmjs.com/package/@anthropic-ai/claude-code) on NPM. 
 - 🐍 Python (813MB) - adds Python 3 and Anthropic's [claude-code-sdk-python](https://github.com/anthropics/claude-code-sdk-python) aka [claude-code-sdk](https://pypi.org/project/claude-code-sdk/) on PyPI.

## Why use these images?

### ✅ Claude Pro and Max subscription compatibility

***Problem:*** As of July, 2025, the Claude Code SDKs use the CLI OAuth flow, which is clunky inside a container. 

***Solution:*** These containers replace the CLI authentication with Long-lived access tokens. See: `claude setup-token --help`

## Available Images

- `ghcr.io/cabinlab/claude-code-sdk:latest` - CLI + TypeScript SDK
- `ghcr.io/cabinlab/claude-code-sdk:typescript` - Same as latest
- `ghcr.io/cabinlab/claude-code-sdk:python` - Above + Python SDKs

## Quick Start (for Claude Pro and Max users)

1. **Get your OAuth token** (on host machine):
   ```bash
   claude setup-token
   ```
   ```bash
   # Follow Anthropic's 2 or 3 screens of auth flow CLI --> Browser --> CLI
   ```
   ```bash
   # Copy the token that starts with "sk-ant-oat01-"
   ```

2. **Set environment variable**:
   #### RECOMMENDED:

   ```bash
   export CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-your-token-here
   ```
   
   ALTERNATE:

   ```bash
   # Copy .env.example to .env
   cp .env.example .env
   ```
   ```bash
   # Edit .env and update this line with your actual token
   CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-your-token-here
   ```

3. **Start the containers**:
   ```bash
   # Start containers (automatically uses .env file)
   docker compose up -d
   ```

4. **Test it works**:
   ```bash
   # TypeScript (using compose.yaml)
   docker compose exec typescript node /app/scripts/test-auth.js
   
   # Python (using compose-python.yaml)
   docker compose -f compose-python.yaml exec python python /app/scripts/test_auth.py
   ```

### Using Docker Compose (Full Examples)

**Note:** This project includes two compose files:
- `compose.yaml` - TypeScript container only
- `compose-python.yaml` - Python container (which includes TypeScript)

#### Option 1: Run TypeScript
```bash
# Start TypeScript container
docker compose up -d

# Run TypeScript example
docker compose exec typescript tsx /app/examples/typescript/hello.ts

# Interactive TypeScript development
docker compose exec typescript bash
```

#### Option 2: Run Python (Includes Typescript!)
```bash
# Start Python container
docker compose -f compose-python.yaml up -d

# Run Python example
docker compose -f compose-python.yaml exec python python /app/examples/python/hello.py

# Interactive Python development
docker compose -f compose-python.yaml exec python python

# Tip: If you only use Python, rename the file for convenience
mv compose-python.yaml compose.yaml
```

### Using Docker Run

For users who prefer direct docker commands:

```bash
# TypeScript
docker run --rm -it \
  -e CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..." \
  -v $(pwd):/app \
  -p 3000:3000 \
  ghcr.io/cabinlab/claude-code-sdk:typescript \
  bash

# Python
docker run --rm -it \
  -e CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..." \
  -v $(pwd):/app \
  -p 3000:3000 \
  ghcr.io/cabinlab/claude-code-sdk:python \
  python
```

## Features

### Included Tools

#### Base (CLI + Typescript SDK)
- **Non-root user** - Security best practice
- **Claude Code CLI** - Familiar Claude Code CLI and auth flow
- **TypeScript SDK** - Native TypeScript/JavaScript support
- **tsx** - Run TypeScript files directly without compilation
- **Git, cURL, jq** - Essential development tools

#### Python
- **Python SDK** - Python bindings (in `:python` image)


### Claude Config Scaffolding

Each container includes a `.claude/` directory with:

- **Slash Commands** - Directory and instructions for extending Claude Code with custom commands
- **Hooks** - Directory and instructions to leverage Claude's behavior
- Example configurations and documentation

Mount your own configuration:
```bash
docker run -v ~/.claude:/home/claude/.claude ...
```

## Authentication

### Which method should I use?

#### Claude Pro/Max users
- Long-lived tokens [Recommended] → See [Quick Start](#quick-start-for-claude-pro-and-max-users) above
- Session based tokens - This is the standard Claude Code auth flow

#### Anthropic API Keys
- Anthropic API keys → Set `ANTHROPIC_API_KEY` in your `.env` file
- Can also be used through standard Claude Code auth flow
- ⚠️ Likely overrides OAuth/Subscription plan settings
- ✅ Use API ***OR*** Subscription, not both together

For technical details and troubleshooting, see our [Authentication Guide](docs/AUTHENTICATION.md).

### Advanced: Docker Secrets (Optional)

For enhanced security in local development, you can use Docker Secrets to keep your token out of shell history and environment variable listings:

1. Create your secret file:
   ```bash
   mkdir -p .secrets
   echo "sk-ant-oat01-your-token-here" > .secrets/oauth_token.txt
   ```

2. Uncomment the Docker Secrets lines in `compose.yaml` or `compose-python.yaml`

3. Run normally:
   ```bash
   docker compose up -d
   ```

## Building Your Own Images

<details>
<summary><b>Extending the Base Images</b> (click to expand)</summary>

### For TypeScript Projects

```dockerfile
# For TypeScript projects
FROM ghcr.io/cabinlab/claude-code-sdk:typescript

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
CMD ["npm", "start"]
```

### For Python Projects

```dockerfile
# For Python projects
FROM ghcr.io/cabinlab/claude-code-sdk:python

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "main.py"]
```

### Building Locally

```bash
# Build TypeScript base
docker build -f Dockerfile.typescript -t claude-code-sdk:typescript .

# Build Python extension
docker build --build-arg BASE_IMAGE=claude-code-sdk:typescript \
  -t claude-code-sdk:python .
```

</details>

## Security

- Containers run as non-root user `claude`
- OAuth tokens should never be built into images
- Use `.aiexclude` to prevent Claude from accessing sensitive files
- Mount secrets at runtime, don't embed them

## Examples

See the `examples/` directory for sample code in:
- JavaScript
- TypeScript (with direct execution via tsx)
- Python

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - see LICENSE file for details