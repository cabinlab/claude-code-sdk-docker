# Multi-language Claude Code SDK container
# Supports both TypeScript/JavaScript and Python

# Since Python-specific base image may not be available, we'll use the TypeScript base
# and add Python support on top
FROM ghcr.io/cabinlab/claude-code-sdk:typescript AS runtime

# Switch to root for any additional setup
USER root

# Install any additional runtime dependencies if needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    nano \
    && rm -rf /var/lib/apt/lists/*

# The base image already includes:
# - Claude Code CLI
# - tsx for TypeScript execution
# - Python 3 runtime with claude-code-sdk
# - Node.js runtime
# - git and ca-certificates
# - A non-root user (claude)
# - OAuth token handling

# Set up .claude configuration scaffolding
RUN mkdir -p /home/claude/.claude/commands /home/claude/.claude/hooks && \
    chown -R claude:claude /home/claude/.claude

# Copy Claude configuration scaffolding
COPY --chown=claude:claude .claude/ /home/claude/.claude/

# Copy examples and scripts
COPY --chown=claude:claude examples/ /app/examples/
COPY --chown=claude:claude scripts/ /app/scripts/

# Copy entrypoint script (as root)
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Set working directory
WORKDIR /app
RUN chown claude:claude /app

# Switch back to non-root user
USER claude

# Expose port (configurable via PORT env var, default 3000)
ARG PORT=3000
ENV PORT=${PORT}
EXPOSE ${PORT}

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

# Default command
CMD ["sleep", "infinity"]