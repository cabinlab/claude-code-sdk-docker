# Multi-language Claude Agent SDK container
# Supports both TypeScript/JavaScript and Python
# Build Date: 2026-02-26
# Python SDK: claude-agent-sdk ~v0.1.44
# Inherits Claude Agent SDK CLI from base TypeScript image

# Stage 1: Build Python dependencies
ARG BASE_IMAGE=ghcr.io/cabinlab/claude-code-sdk:typescript
FROM ${BASE_IMAGE} AS python-builder

# Switch to root for installations
USER root

# Install Python and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    python3-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment to isolate dependencies
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python SDK in the virtual environment
RUN pip install --no-cache-dir claude-agent-sdk

# Stage 2: Runtime image
FROM ${BASE_IMAGE} AS runtime

# Switch to root for minimal Python installation
USER root

# Install only Python runtime (no dev packages or pip)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the virtual environment from builder
COPY --from=python-builder /opt/venv /opt/venv

# Create Python symlinks
RUN ln -s /usr/bin/python3 /usr/bin/python || true

# Set PATH to use virtual environment
ENV PATH="/opt/venv/bin:$PATH"
# Let Python find the right site-packages automatically
ENV VIRTUAL_ENV="/opt/venv"

# Switch back to non-root user
USER claude

# Working directory is already /app from base image
# Port 3000 is already exposed from base image

# Entrypoint is inherited from base image