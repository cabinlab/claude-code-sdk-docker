# Claude Hooks

Hooks allow you to intercept and modify Claude's behavior at specific points during execution.

## Available Hooks

- **pre-tool-use**: Runs before any tool is executed
- **post-tool-use**: Runs after a tool completes
- **stop**: Runs when Claude stops or completes a task

## Setting Up Hooks

1. Copy an example file (remove `.example` extension)
2. Make the file executable: `chmod +x hook-name`
3. Modify the script to suit your needs

## Example Usage

To enable the pre-tool-use example:
```bash
cp pre-tool-use.example pre-tool-use
chmod +x pre-tool-use
```

## Hook Environment Variables

Hooks receive information through environment variables:
- `TOOL_NAME`: The name of the tool being used
- `TOOL_PARAMS`: JSON string of tool parameters
- `CLAUDE_SESSION_ID`: Current session identifier

## Best Practices

- Keep hooks lightweight and fast
- Exit with status 0 to allow continuation
- Exit with non-zero status to block the action
- Log to stderr for debugging: `echo "Debug info" >&2`

## Mounting Custom Hooks

Override default hooks by mounting your own:
```bash
docker run -v ~/my-hooks:/home/claude/.claude/hooks ...
```

## Security Note

Hooks run with the same permissions as Claude. Be cautious about:
- External command execution
- File system modifications
- Network requests