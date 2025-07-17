#!/usr/bin/env node

/**
 * Test script to verify Claude Code OAuth authentication is working
 */

const { query } = require("@anthropic-ai/claude-code");

// Colors for console output
const colors = {
    red: '\x1b[31m',
    green: '\x1b[32m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
    reset: '\x1b[0m'
};

function log(color, message) {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

async function testAuthentication() {
    log('blue', '🔍 Testing Claude Code OAuth Authentication');
    console.log('='.repeat(50));
    
    // Check environment variables
    const oauthToken = process.env.CLAUDE_CODE_OAUTH_TOKEN;
    const sessionToken = process.env.CLAUDE_CODE_SESSION;
    
    console.log('\n📋 Environment Check:');
    log(oauthToken ? 'green' : 'red', 
        `  CLAUDE_CODE_OAUTH_TOKEN: ${oauthToken ? '✓ SET' : '✗ NOT SET'}`);
    
    if (oauthToken) {
        log('blue', `    Preview: ${oauthToken.substring(0, 20)}...`);
    }
    
    log(sessionToken ? 'green' : 'red', 
        `  CLAUDE_CODE_SESSION: ${sessionToken ? '✓ SET' : '✗ NOT SET'}`);
    
    if (!oauthToken && !sessionToken) {
        log('red', '\n❌ No authentication tokens found!');
        log('yellow', '\nPlease set one of these environment variables:');
        console.log('  export CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-your-token-here');
        console.log('  or run interactive authentication:');
        console.log('  claude auth login');
        return false;
    }
    
    // Test Claude Code SDK
    console.log('\n🔄 Testing Claude Code SDK...');
    
    try {
        const prompt = 'Hello! Please respond with just "Authentication successful" if you can read this.';
        
        log('blue', `📤 Sending test prompt: "${prompt}"`);
        
        let response = '';
        let messageCount = 0;
        const messages = [];
        
        for await (const message of query({
            prompt: prompt,
            abortController: new AbortController(),
            options: {
                model: 'claude-3-5-sonnet-20241022'
            }
        })) {
            messageCount++;
            messages.push(message);
            
            // Handle assistant messages
            if (message.type === 'assistant' && message.message?.content) {
                for (const block of message.message.content) {
                    if (block.type === 'text') {
                        response += block.text;
                    }
                }
            }
        }
        
        console.log(`\n📥 Received ${messageCount} message(s)`);
        log('green', `📝 Response: ${response.trim()}`);
        
        if (response.trim()) {
            log('green', '\n🎉 SUCCESS: OAuth authentication is working!');
            log('blue', '\n📊 Test Results:');
            console.log(`  ✓ Authentication: Working`);
            console.log(`  ✓ Model: claude-3-5-sonnet-20241022`);
            console.log(`  ✓ Response received: ${response.length} characters`);
            console.log(`  ✓ Messages processed: ${messageCount}`);
            return true;
        } else {
            log('yellow', '\n⚠️  WARNING: Empty response received');
            log('yellow', 'Authentication may be working but Claude didn\'t respond as expected');
            return false;
        }
        
    } catch (error) {
        log('red', '\n❌ ERROR: Authentication test failed');
        log('red', `Error details: ${error.message || error}`);
        
        // Provide helpful debugging information
        console.log('\n🔧 Debugging steps:');
        console.log('1. Check if Claude Code CLI is installed:');
        console.log('   claude --version');
        console.log('2. Check authentication status:');
        console.log('   claude auth status');
        console.log('3. Try re-authenticating:');
        console.log('   claude auth login');
        
        return false;
    }
}

async function main() {
    try {
        const success = await testAuthentication();
        process.exit(success ? 0 : 1);
    } catch (error) {
        log('red', `\n💥 Unexpected error: ${error.message || error}`);
        process.exit(1);
    }
}

// Handle graceful shutdown
process.on('SIGINT', () => {
    log('yellow', '\n\n👋 Test interrupted by user');
    process.exit(0);
});

process.on('SIGTERM', () => {
    log('yellow', '\n\n👋 Test terminated');
    process.exit(0);
});

// Run the test
if (require.main === module) {
    main().catch(error => {
        log('red', `Fatal error: ${error.message || error}`);
        process.exit(1);
    });
}