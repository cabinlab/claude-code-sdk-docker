# Claude Custom Commands

This directory is for custom slash commands that extend Claude's functionality.

## Creating a Custom Command

1. Create a markdown file in this directory (e.g., `mycommand.md`)
2. The filename becomes the command name (e.g., `/mycommand`)
3. The content should be a prompt that Claude will execute

## Example Command

Create a file named `todo.md`:

```markdown
List all TODO comments in the current project, organized by file.
Search for comments containing TODO, FIXME, or HACK.
Present them in a clear, actionable format.
```

Then use it with: `/todo`

## Best Practices

- Keep commands focused on a single task
- Use clear, specific language in your prompts
- Test commands thoroughly before relying on them
- Document what your command does at the top of the file

## Available in This Container

Custom commands placed here will be available when running Claude Code
inside this container. Mount your own commands directory to override these defaults:

```bash
docker run -v ~/my-commands:/home/claude/.claude/commands ...
```