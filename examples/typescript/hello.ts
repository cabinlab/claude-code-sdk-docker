#!/usr/bin/env tsx

import { Claude } from '@anthropic-ai/claude-code';

async function main() {
  // Initialize Claude (uses CLAUDE_CODE_OAUTH_TOKEN from environment)
  const claude = new Claude();

  console.log('🤖 Claude Code TypeScript SDK Example\n');

  try {
    // Simple conversation
    const response = await claude.sendMessage('Hello! What programming language is this example written in?');
    
    console.log('Claude:', response.text);
    
    // Example with streaming
    console.log('\n📝 Streaming example:');
    console.log('Claude: ');
    
    const stream = await claude.sendMessage('Write a haiku about TypeScript', { 
      stream: true 
    });
    
    for await (const chunk of stream) {
      process.stdout.write(chunk.text);
    }
    console.log('\n');
    
  } catch (error) {
    console.error('Error:', error.message);
    console.log('\nMake sure CLAUDE_CODE_OAUTH_TOKEN is set in your environment');
  }
}

// Run the example
main().catch(console.error);