#!/usr/bin/env python3

"""
Test script to verify Claude Agent SDK OAuth authentication is working
"""

import os
import asyncio
from claude_agent_sdk import query, ClaudeAgentOptions
from claude_agent_sdk.types import AssistantMessage, TextBlock

# Colors for console output
class Colors:
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    RESET = '\033[0m'

def log(color, message):
    print(f"{getattr(Colors, color.upper())}{message}{Colors.RESET}")

async def test_authentication():
    log('blue', '🔍 Testing Claude Agent SDK OAuth Authentication')
    print('=' * 50)
    
    # Check environment variables
    oauth_token = os.getenv('CLAUDE_CODE_OAUTH_TOKEN')
    session_token = os.getenv('CLAUDE_CODE_SESSION')
    
    print('\n📋 Environment Check:')
    log('green' if oauth_token else 'red', 
        f"  CLAUDE_CODE_OAUTH_TOKEN: {'✓ SET' if oauth_token else '✗ NOT SET'}")
    
    if oauth_token:
        log('blue', f"    Preview: {oauth_token[:20]}...")
    
    log('green' if session_token else 'red', 
        f"  CLAUDE_CODE_SESSION: {'✓ SET' if session_token else '✗ NOT SET'}")
    
    if not oauth_token and not session_token:
        log('red', '\n❌ No authentication tokens found!')
        log('yellow', '\nPlease set one of these environment variables:')
        print('  export CLAUDE_CODE_OAUTH_TOKEN=sk-ant-oat01-your-token-here')
        print('  or run interactive authentication:')
        print('  claude auth login')
        return False
    
    # Test Claude Agent SDK
    print('\n🔄 Testing Claude Agent SDK...')
    
    try:
        options = ClaudeAgentOptions(
            model='claude-3-5-sonnet-20241022'
        )
        
        prompt = 'Hello! Please respond with just "Authentication successful" if you can read this.'
        
        log('blue', f'📤 Sending test prompt: "{prompt}"')
        
        response = ''
        message_count = 0
        
        async for message in query(prompt=prompt, options=options):
            message_count += 1
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        response += block.text
        
        print(f'\n📥 Received {message_count} message(s)')
        log('green', f'📝 Response: {response.strip()}')
        
        if response.strip():
            log('green', '\n🎉 SUCCESS: OAuth authentication is working!')
            log('blue', '\n📊 Test Results:')
            print(f"  ✓ Authentication: Working")
            print(f"  ✓ Model: claude-3-5-sonnet-20241022")
            print(f"  ✓ Response received: {len(response)} characters")
            print(f"  ✓ Messages processed: {message_count}")
            return True
        else:
            log('yellow', '\n⚠️  WARNING: Empty response received')
            log('yellow', 'Authentication may be working but Claude didn\'t respond as expected')
            return False
        
    except Exception as error:
        log('red', '\n❌ ERROR: Authentication test failed')
        log('red', f'Error details: {error}')
        
        # Provide helpful debugging information
        print('\n🔧 Debugging steps:')
        print('1. Check if Claude Code CLI is installed:')
        print('   claude --version')
        print('2. Check authentication status:')
        print('   claude auth status')
        print('3. Try re-authenticating:')
        print('   claude auth login')
        
        return False

async def main():
    try:
        success = await test_authentication()
        exit(0 if success else 1)
    except Exception as error:
        log('red', f'\n💥 Unexpected error: {error}')
        exit(1)

if __name__ == "__main__":
    asyncio.run(main())