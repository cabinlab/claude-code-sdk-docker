declare module "@anthropic-ai/claude-code" {
    export interface SDKTextBlock {
        type: 'text';
        text: string;
    }
    
    export interface SDKToolUseBlock {
        type: 'tool_use';
        id: string;
        name: string;
        input: any;
    }
    
    export interface SDKToolResultBlock {
        type: 'tool_result';
        tool_use_id: string;
        content: string;
        is_error?: boolean;
    }
    
    export type SDKContentBlock = SDKTextBlock | SDKToolUseBlock | SDKToolResultBlock;
    
    export interface SDKAssistantMessage {
        role: 'assistant';
        content: SDKContentBlock[];
    }
    
    export interface SDKUserMessage {
        role: 'user';
        content: string | SDKContentBlock[];
    }
    
    export interface SDKToolMessage {
        role: 'tool';
        content: SDKContentBlock[];
    }
    
    export interface SDKSystemMessage {
        type: 'system';
        subtype: string;
        cwd?: string;
        session_id?: string;
        tools?: string[];
        [key: string]: any;
    }
    
    export interface SDKAssistantMessageWrapper {
        type: 'assistant';
        message: SDKAssistantMessage & {
            id: string;
            model: string;
            usage?: any;
            stop_reason?: string | null;
            stop_sequence?: string | null;
        };
        parent_tool_use_id?: string | null;
        session_id?: string;
    }
    
    export interface SDKResultMessage {
        type: 'result';
        subtype: string;
        is_error: boolean;
        result?: string;
        session_id?: string;
        [key: string]: any;
    }
    
    export type SDKMessage = SDKAssistantMessageWrapper | SDKUserMessage | SDKToolMessage | SDKSystemMessage | SDKResultMessage;
    
    export interface QueryOptions {
        model?: string;
        maxTurns?: number;
        systemPrompt?: string;
        allowedTools?: string[];
        dangerouslySkipPermissions?: boolean;
        [key: string]: any;
    }
    
    export interface QueryParams {
        prompt: string;
        abortController?: AbortController;
        options?: QueryOptions;
        cwd?: string;
        executable?: string;
        executableArgs?: string[];
        pathToClaudeCodeExecutable?: string;
    }
    
    export function query(params: QueryParams): AsyncGenerator<SDKMessage>;
}