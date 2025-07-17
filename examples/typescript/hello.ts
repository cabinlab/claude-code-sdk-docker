#!/usr/bin/env tsx

import { query } from '@anthropic-ai/claude-code';

async function main() {
  console.log('🤖 Claude Code TypeScript SDK Example\n');

  try {
    // Simple conversation
    console.log('📤 Asking Claude about TypeScript...\n');
    console.log('Claude:');
    
    let responseText = '';
    for await (const message of query({
      prompt: 'Hello! What programming language is this example written in? Please be brief.',
      abortController: new AbortController(),
      options: {
        model: 'claude-3-5-sonnet-20241022',
      }
    })) {
      if (message.type === 'assistant' && message.message?.content) {
        for (const block of message.message.content) {
          if (block.type === 'text') {
            process.stdout.write(block.text);
            responseText += block.text;
          }
        }
      }
    }
    
    // Example with another query
    console.log('\n\n📝 Haiku example:');
    console.log('Claude:\n');
    
    for await (const message of query({
      prompt: 'Write a haiku about TypeScript',
      abortController: new AbortController(),
      options: {
        model: 'claude-3-5-sonnet-20241022',
      }
    })) {
      if (message.type === 'assistant' && message.message?.content) {
        for (const block of message.message.content) {
          if (block.type === 'text') {
            process.stdout.write(block.text);
          }
        }
      }
    }
    console.log('\n');
    
  } catch (error: any) {
    console.error('Error:', error.message);
    console.log('\nMake sure CLAUDE_CODE_OAUTH_TOKEN is set in your environment');
  }
}

// Run the example
main().catch(console.error);