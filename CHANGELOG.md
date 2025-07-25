# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-07-18

### Added
- **Alpine Linux variants** for minimal container deployments
  - Alpine TypeScript image (383MB) - 47% smaller than Debian
  - Alpine Python image (474MB) - 32% smaller than Debian
- Intelligent conditional builds using paths-filter to optimize CI usage
- Multi-stage Docker builds for all variants

### Changed
- **Significant size reductions** across all container variants:
  - Debian TypeScript: 727MB → 607MB (16% reduction)
  - Debian Python: 813MB → 693MB (15% reduction)
- Binary cleanup optimization removes unused platform-specific files
- Improved GitHub Actions workflow with selective builds based on file changes

### Fixed
- Alpine container permissions issue with entrypoint script
- Path-based filtering logic for conditional CI builds
- Proper authentication handling in Alpine environments

## [0.1.0] - 2025-07-17

### Added
- Initial release of Claude Code SDK Docker containers
- TypeScript base image (727MB) with Claude Code CLI and SDK
- Python extension image (813MB) with claude-code-sdk-python
- Long-lived OAuth token authentication support
- Multi-stage Docker builds for optimized image sizes
- Example code for JavaScript, TypeScript, and Python
- Docker Compose configurations for easy local development
- GitHub Actions workflow for automated builds and publishing
- Non-root user security implementation
- Claude CLI configuration scaffolding (.claude directory)

### Security
- Containers run as non-root user `claude`
- Proper file permissions for authentication files
- No secrets embedded in images

### Documentation
- Comprehensive README with quick start guide
- Authentication guide for different auth methods
- Examples directory with working code samples

### Known Limitations
- API key authentication not fully tested