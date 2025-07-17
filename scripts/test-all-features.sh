#!/bin/bash
# test-all-features.sh - Comprehensive test to exercise all Claude Code SDK functionality
# Used for docker-slim to understand what files/binaries are actually needed

set -e

echo "=== Testing Claude Code SDK Features ==="

# 1. Basic tools
echo "Testing basic tools..."
node --version
npm --version
git --version
bash --version
sh -c "echo 'sh works'"

# 2. Claude Code CLI
echo "Testing Claude Code CLI..."
claude --version || true
# Don't actually auth, just test the binary works
claude --help || true

# 3. TypeScript/Node operations
echo "Testing TypeScript/Node..."
# Test require/import of Claude Code SDK
node -e "const claude = require('@anthropic-ai/claude-code'); console.log('SDK loaded')" || true
# Test tsx
tsx --version || true
echo "console.log('tsx test')" > /tmp/test.ts
tsx /tmp/test.ts || true
rm -f /tmp/test.ts

# 4. Python operations (if Python image)
if command -v python3 &> /dev/null; then
    echo "Testing Python..."
    python3 --version
    python3 -c "import claude_code_sdk; print('Python SDK loaded')" || true
    pip3 --version || true
fi

# 5. File operations that Claude might use
echo "Testing file operations..."
ls -la /
find /tmp -name "*.txt" 2>/dev/null | head -5 || true
grep --version || true
# Test ripgrep specifically (Claude uses this)
rg --version || true
echo "test content" > /tmp/test.txt
rg "test" /tmp || true
rm -f /tmp/test.txt

# 6. Network operations
echo "Testing network tools..."
curl --version || true
wget --version 2>/dev/null || echo "wget not installed"
# Test HTTPS to ensure certificates work
curl -s https://api.github.com/zen || true

# 7. Development tools Claude might need
echo "Testing development tools..."
nano --version 2>/dev/null || echo "nano not installed"
tar --version || true
gzip --version || true

# 8. Git operations in detail
echo "Testing git operations..."
cd /tmp
git init test-repo
cd test-repo
git config user.email "test@example.com"
git config user.name "Test User"
echo "test" > file.txt
git add .
git commit -m "test commit"
git log --oneline
cd /
rm -rf /tmp/test-repo

# 9. npm operations
echo "Testing npm operations..."
cd /tmp
npm init -y
# Don't actually install, just test npm works
npm list
rm -f package.json

# 10. Environment and locale
echo "Testing environment..."
locale || true
env | grep -E "(PATH|NODE_PATH|HOME)" || true

# 11. User permissions
echo "Testing user permissions..."
whoami
id
# Test writing to home directory
touch ~/test-file && rm ~/test-file

# 12. SSL certificates (critical for HTTPS)
echo "Testing SSL certificates..."
ls /etc/ssl/certs/ | head -5 || true

# 13. Claude SDK actual usage simulation
echo "Testing Claude SDK usage patterns..."
cat > /tmp/test-claude.js << 'EOF'
// Simulate what the SDK might do internally
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// Test file operations
fs.writeFileSync('/tmp/claude-test.txt', 'test');
fs.readFileSync('/tmp/claude-test.txt', 'utf8');
fs.unlinkSync('/tmp/claude-test.txt');

// Test process spawning (Claude might spawn git, etc)
try {
  const git = spawn('git', ['--version']);
  git.on('close', (code) => {
    console.log(`git process exited with code ${code}`);
  });
} catch (e) {
  console.log('Process spawn test complete');
}

console.log('Claude SDK simulation complete');
EOF
node /tmp/test-claude.js || true
rm -f /tmp/test-claude.js

# 14. Authentication file locations
echo "Testing Claude auth locations..."
ls -la ~/.claude/ 2>/dev/null || echo "No .claude directory yet"
# Test creating auth directory structure
mkdir -p ~/.claude/commands ~/.claude/hooks
touch ~/.claude/.credentials.json
echo '{}' > ~/.claude/.credentials.json
ls -la ~/.claude/
rm -rf ~/.claude/

# 15. Error handling paths
echo "Testing error handling..."
node -e "throw new Error('test error')" 2>&1 || true
node -e "process.exit(1)" || true

echo "=== All tests completed ==="