# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project structure and scaffolding
- .NET Agent Framework samples with AIAgent and Workflow implementations
- Python Agent Framework samples with async/await support
- React webapp with TypeScript and Tailwind CSS
- Agent configuration files (JSON/YAML)
- Workflow configuration files (JSON/YAML)
- Tool stubs:
  - MCP server implementation
  - OpenAPI tool example
  - Code execution sandbox interface
  - Web search tool stub
  - File I/O tool with security guards
- Comprehensive test suites:
  - xUnit tests for .NET
  - pytest tests for Python
  - Vitest setup for webapp
- Documentation:
  - Getting Started guide
  - Threat Model
  - Onboarding Checklist
- Webapp features:
  - React Flow canvas for workflow design
  - Trace visualization page (VisX/D3 ready)
  - Agent management page with Monaco editor drawer
  - Asset management page
  - Settings page with configuration options
  - Command Palette (Cmd+K)
  - Tailwind CSS styling
- Workflow patterns:
  - Sequential workflow
  - Concurrent workflow
  - Group chat workflow
  - Handoff workflow
  - Superstep checkpointing
  - Type-safe message passing

### Changed
- N/A (initial release)

### Deprecated
- N/A (initial release)

### Removed
- N/A (initial release)

### Fixed
- N/A (initial release)

### Security
- Implemented path traversal protection in File I/O tool
- Added security guards for code execution
- Configured input validation for dangerous operations
- Added threat model documentation

## [0.1.0] - 2024-01-15

### Added
- Project initialization
- Repository structure
- Basic documentation
- License (MIT)

---

## Guidelines

### Types of Changes
- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

### Version Format
- **Major**: Incompatible API changes
- **Minor**: Backwards-compatible functionality
- **Patch**: Backwards-compatible bug fixes

### Links
- [0.1.0]: https://github.com/Brookside-Proving-Grounds/Project-Ascension/releases/tag/v0.1.0
