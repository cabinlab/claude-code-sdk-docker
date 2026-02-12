#!/usr/bin/env node

/**
 * Example JavaScript application using Claude Agent SDK with OAuth authentication
 * This demonstrates how to use Claude Agent SDK in a Docker container
 */

const { query } = require("@anthropic-ai/claude-agent-sdk");

async function exampleUsage() {
    console.log("🤖 Claude Agent SDK Example (JavaScript)");
    console.log("========================================\n");
    
    // Check authentication
    const oauthToken = process.env.CLAUDE_CODE_OAUTH_TOKEN;
    const sessionToken = process.env.CLAUDE_CODE_SESSION;
    
    if (!oauthToken && !sessionToken) {
        console.error("❌ No authentication token found!");
        console.log("Please set CLAUDE_CODE_OAUTH_TOKEN environment variable");
        return false;
    }
    
    console.log("✓ Authentication token found");
    if (oauthToken) {
        console.log(`  OAuth token: ${oauthToken.substring(0, 20)}...`);
    }
    if (sessionToken) {
        console.log(`  Session token: ${sessionToken.substring(0, 20)}...`);
    }
    
    try {
        const prompt = `
        Hello Claude! Please help me understand how to use the Claude Agent SDK.
        Can you give me a brief overview of what it can do?
        `;
        
        console.log("📤 Sending prompt to Claude...\n");
        console.log("💬 Claude's Response:");
        console.log("─".repeat(50));
        
        // Stream the response
        let responseContent = "";
        const messages = [];
        
        for await (const message of query({
            prompt: prompt.trim(),
            abortController: new AbortController(),
            options: {
                model: 'claude-3-5-sonnet-20241022',
                // You can add other options here:
                // maxTurns: 1,
                // systemPrompt: 'You are a helpful assistant',
                // allowedTools: ['Read', 'Write', 'Bash'],
            }
        })) {
            messages.push(message);
            
            // Extract and display text content from assistant messages
            if (message.type === 'assistant' && message.message?.content) {
                for (const block of message.message.content) {
                    if (block.type === 'text') {
                        const content = block.text;
                        process.stdout.write(content);
                        responseContent += content;
                    }
                }
            }
        }
        
        console.log("\n" + "─".repeat(50));
        console.log("✅ Response complete!");
        console.log(`📊 Total characters received: ${responseContent.length}`);
        console.log(`📋 Messages processed: ${messages.length}`);
        return true;
        
    } catch (error) {
        console.error(`❌ Error: ${error.message || error}`);
        return false;
    }
}

async function main() {
    try {
        const success = await exampleUsage();
        if (!success) {
            process.exit(1);
        }
    } catch (error) {
        console.error(`💥 Fatal error: ${error.message || error}`);
        process.exit(1);
    }
}

// Run the example
if (require.main === module) {
    main();
}