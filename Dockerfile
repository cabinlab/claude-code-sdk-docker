# Multi-language Claude Code SDK container
# Supports both TypeScript/JavaScript and Python

# We need to build the typescript base first
ARG BASE_IMAGE=ghcr.io/cabinlab/claude-code-sdk:typescript
FROM ${BASE_IMAGE} AS claude-python

# Switch to root to install Python
USER root

# Install Python 3.11
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.11 \
    python3.11-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Create Python symlink (python3 already exists)
RUN ln -s /usr/bin/python3 /usr/bin/python || true

# Install Python SDK
RUN pip install --no-cache-dir --break-system-packages claude-code-sdk

# Switch back to non-root user
USER claude

# Working directory is already /app from base image
# Port 3000 is already exposed from base image

# Entrypoint is inherited from base image