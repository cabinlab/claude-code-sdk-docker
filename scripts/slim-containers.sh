#!/bin/bash
# slim-containers.sh - Automate docker-slim optimization for Claude Code containers

set -e

echo "=== Docker-slim optimization for Claude Agent SDK containers ==="

# Check if docker-slim is installed
if ! command -v docker-slim &> /dev/null; then
    echo "Error: docker-slim is not installed"
    echo "Install it from: https://github.com/slimtoolkit/slim"
    exit 1
fi

# Function to slim a container
slim_container() {
    local SOURCE_IMAGE=$1
    local TARGET_IMAGE=$2
    local VARIANT=$3
    
    echo "Optimizing $SOURCE_IMAGE -> $TARGET_IMAGE"
    
    # Make test script executable
    chmod +x scripts/test-all-features.sh
    
    # Run docker-slim with comprehensive testing
    docker-slim build \
        --target "$SOURCE_IMAGE" \
        --tag "$TARGET_IMAGE" \
        --config-file scripts/docker-slim-config.yaml \
        --exec-file scripts/test-all-features.sh \
        --mount "$PWD:/app" \
        --env CLAUDE_CODE_OAUTH_TOKEN="${CLAUDE_CODE_OAUTH_TOKEN:-dummy-token}" \
        --http-probe=false \
        --continue-after=30 \
        --show-clogs
    
    # Show size comparison
    echo "Size comparison:"
    docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}" | grep -E "(${SOURCE_IMAGE}|${TARGET_IMAGE})"
}

# Function to validate slimmed image
validate_slim() {
    local IMAGE=$1
    local VARIANT=$2
    
    echo "Validating $IMAGE..."
    
    # Basic validation
    docker run --rm "$IMAGE" node --version || { echo "FAIL: node"; return 1; }
    docker run --rm "$IMAGE" npm --version || { echo "FAIL: npm"; return 1; }
    docker run --rm "$IMAGE" git --version || { echo "FAIL: git"; return 1; }
    docker run --rm "$IMAGE" claude --version || { echo "FAIL: claude"; return 1; }
    
    # Test Claude SDK can be loaded
    docker run --rm "$IMAGE" node -e "require('@anthropic-ai/claude-agent-sdk')" || { echo "FAIL: SDK load"; return 1; }
    
    # Python-specific tests
    if [[ "$VARIANT" == *"python"* ]]; then
        docker run --rm "$IMAGE" python3 --version || { echo "FAIL: python3"; return 1; }
        docker run --rm "$IMAGE" pip3 --version || { echo "FAIL: pip3"; return 1; }
    fi
    
    echo "✓ Validation passed for $IMAGE"
}

# Main execution
VARIANTS=("typescript" "python" "alpine" "alpine-python")

for VARIANT in "${VARIANTS[@]}"; do
    SOURCE="ghcr.io/cabinlab/claude-code-sdk-docker:$VARIANT"
    TARGET="ghcr.io/cabinlab/claude-code-sdk-docker:$VARIANT-slim"
    
    # Check if source image exists
    if docker image inspect "$SOURCE" &> /dev/null; then
        echo "Processing $VARIANT variant..."
        slim_container "$SOURCE" "$TARGET" "$VARIANT"
        validate_slim "$TARGET" "$VARIANT"
        echo "---"
    else
        echo "Skipping $VARIANT - image not found locally"
    fi
done

echo "=== Docker-slim optimization complete ==="
echo "Original images are preserved. Slimmed images have '-slim' suffix."