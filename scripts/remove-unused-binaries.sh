#!/bin/sh
# remove-unused-binaries.sh - Remove platform-specific binaries we don't need in Linux containers
# This script should be run during Docker build to reduce image size

set -e

echo "Removing unnecessary platform-specific binaries..."

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_DIR="x64-linux" ;;
    aarch64) ARCH_DIR="arm64-linux" ;;
    *) echo "Unknown architecture: $ARCH"; exit 1 ;;
esac

# Find Claude Agent SDK module location
CLAUDE_DIR=$(find /usr/local/lib/node_modules/@anthropic-ai/claude-agent-sdk -name "ripgrep" -type d 2>/dev/null | head -1 || true)

if [ -z "$CLAUDE_DIR" ]; then
    CLAUDE_DIR=$(find /usr/lib/node_modules/@anthropic-ai/claude-agent-sdk -name "ripgrep" -type d 2>/dev/null | head -1 || true)
fi

if [ -z "$CLAUDE_DIR" ]; then
    echo "Claude Agent SDK module not found, skipping cleanup"
    exit 0
fi

echo "Found Claude Agent SDK ripgrep at: $CLAUDE_DIR"
cd "$CLAUDE_DIR"

# List current size
echo "Current ripgrep directory size:"
du -sh .

# Remove non-Linux platforms
echo "Removing non-Linux platform binaries..."
rm -rf *-win32 *-darwin 2>/dev/null || true

# Remove non-matching Linux architectures
echo "Removing non-matching Linux architectures (keeping $ARCH_DIR)..."
for dir in *-linux; do
    if [ "$dir" != "$ARCH_DIR" ]; then
        rm -rf "$dir" 2>/dev/null || true
    fi
done

# Remove unused ripgrep executables
echo "Cleaning up ripgrep executables..."
find . -name "rg" -type f | while read -r rg_file; do
    if [[ "$rg_file" != *"$ARCH_DIR"* ]]; then
        rm -f "$rg_file" 2>/dev/null || true
    fi
done

# Remove JetBrains plugin files if not needed
JETBRAINS_DIR=$(find /usr/local/lib/node_modules/@anthropic-ai/claude-agent-sdk -name "jetbrains" -type d 2>/dev/null | head -1 || true)
if [ -n "$JETBRAINS_DIR" ]; then
    echo "Removing JetBrains plugin files..."
    rm -rf "$JETBRAINS_DIR"
fi

# Show new size
echo "Optimized ripgrep directory size:"
du -sh .

# Calculate savings
echo "Space saved by removing unused binaries"