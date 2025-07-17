#!/bin/bash

# Claude Code OAuth Authentication Script for Docker
# This script helps authenticate Claude Code in a Docker container

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Claude Code Docker Authentication${NC}"
echo "================================="
echo ""

# Function to check if container is running
check_container() {
    if ! docker compose ps | grep -q "Up"; then
        echo -e "${RED}Error: Container is not running${NC}"
        echo "Please start the container first:"
        echo "  docker compose up -d"
        exit 1
    fi
}

# Function to get container name
get_container_name() {
    docker compose ps --services | head -n 1
}

# Check if OAuth token is already set
if [ -n "$CLAUDE_CODE_OAUTH_TOKEN" ]; then
    echo -e "${GREEN}✓ OAuth token found in environment${NC}"
    echo "Token: ${CLAUDE_CODE_OAUTH_TOKEN:0:20}..."
    echo ""
    echo "Starting container with OAuth token..."
    docker compose up -d
    echo ""
    echo -e "${GREEN}✓ Container started with OAuth authentication${NC}"
    echo ""
    echo "Test the authentication:"
    echo "  docker compose exec claude-app npm test"
    exit 0
fi

# No OAuth token found, proceed with interactive authentication
echo -e "${YELLOW}No OAuth token found in environment${NC}"
echo "Proceeding with interactive authentication..."
echo ""

# Check if container is running
check_container

# Get container name
CONTAINER_NAME=$(get_container_name)

echo "Entering container for authentication..."
echo ""
echo -e "${YELLOW}Instructions:${NC}"
echo "1. You will be dropped into the container shell"
echo "2. Run: claude setup-token"
echo "3. Follow the OAuth flow in your browser"
echo "4. After successful authentication, type 'exit'"
echo ""
echo "Press Enter to continue..."
read -r

# Enter container for authentication
docker compose exec "$CONTAINER_NAME" /bin/bash

echo ""
echo -e "${GREEN}Authentication completed!${NC}"
echo ""
echo "The authentication will persist in the docker volume."
echo ""
echo "Test the authentication:"
echo "  docker compose exec $CONTAINER_NAME npm test"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Get your long-lived OAuth token:"
echo "   # The token will be shown after completing setup-token"
echo "2. Set it as an environment variable for future use:"
echo "   export CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-your-token-here"