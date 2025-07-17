#!/usr/bin/env python3

"""
Example Python application using Claude Code SDK with OAuth authentication
This demonstrates how to use Claude Code in a Docker container
"""

import os
import asyncio
from claude_code_sdk import query, ClaudeCodeOptions
from claude_code_sdk.types import AssistantMessage, TextBlock

async def example_usage():
    print("🤖 Claude Code SDK Example (Python)")
    print("====================================\n")
    
    # Check authentication
    oauth_token = os.getenv('CLAUDE_CODE_OAUTH_TOKEN')
    session_token = os.getenv('CLAUDE_CODE_SESSION')
    
    if not oauth_token and not session_token:
        print("❌ No authentication token found!")
        print("Please set CLAUDE_CODE_OAUTH_TOKEN environment variable")
        return False
    
    print("✓ Authentication token found")
    if oauth_token:
        print(f"  OAuth token: {oauth_token[:20]}...")
    if session_token:
        print(f"  Session token: {session_token[:20]}...")
    
    try:
        # Configure Claude options
        options = ClaudeCodeOptions(
            model='claude-3-5-sonnet-20241022',
            # You can add other options here:
            # max_turns=1,
            # system_prompt='You are a helpful assistant',
            # allowed_tools=['Read', 'Write', 'Bash'],
        )
        
        prompt = """
        Hello Claude! Please help me understand how to use the Claude Code SDK.
        Can you give me a brief overview of what it can do?
        """
        
        print("📤 Sending prompt to Claude...\n")
        print("💬 Claude's Response:")
        print("─" * 50)
        
        # Stream the response
        response_content = ""
        async for message in query(prompt=prompt.strip(), options=options):
            if isinstance(message, AssistantMessage):
                for block in message.content:
                    if isinstance(block, TextBlock):
                        content = block.text
                        print(content, end="", flush=True)
                        response_content += content
        
        print("\n" + "─" * 50)
        print("✅ Response complete!")
        print(f"📊 Total characters received: {len(response_content)}")
        return True
        
    except Exception as error:
        print(f"❌ Error: {error}")
        return False

async def main():
    try:
        success = await example_usage()
        if not success:
            exit(1)
    except Exception as error:
        print(f"💥 Fatal error: {error}")
        exit(1)

if __name__ == "__main__":
    asyncio.run(main())