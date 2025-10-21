# Meta-Agent Platform Documentation

[![Docs Lint](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-lint.yml/badge.svg)](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-lint.yml)
[![Docs Build](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-build.yml/badge.svg)](https://github.com/Brookside-Proving-Grounds/Project-Ascension/actions/workflows/docs-build.yml)

Welcome to the comprehensive documentation for the Meta-Agent Platform (Agent Studio). This documentation covers architecture, APIs, development guides, deployment procedures, and operational runbooks.

## Documentation Quality System

This documentation is maintained with automated quality checks to ensure accuracy, consistency, and maintainability:

- **Frontmatter Validation** - Every document has required metadata
- **Link Checking** - All internal and external links are verified
- **Spell Checking** - Comprehensive dictionary of technical terms
- **Duplicate Detection** - Identifies redundant content
- **Build Validation** - VitePress builds successfully for all changes

**For Contributors**: See [CI/CD Quick Start Guide](guides/developer/ci-cd-quickstart.md) to run quality checks locally before committing.

## Documentation Structure

```
docs/
├── meta-agents/        # Architecture and system design
├── api/                # API reference documentation
├── guides/             # User guides and tutorials
├── development/        # Developer documentation
├── adrs/               # Architecture Decision Records
└── runbooks/           # Operational runbooks
```

## Quick Links

### Getting Started
- [Quick Start Guide](guides/QUICK_START.md) - Get up and running in 5 minutes
- [Development Setup](development/SETUP.md) - Complete development environment setup
- [Deployment Guide](meta-agents/DEPLOYMENT.md) - Deploy to Azure

### Architecture
- [System Architecture](meta-agents/ARCHITECTURE.md) - Complete system architecture overview
- [Integration Guide](meta-agents/INTEGRATION.md) - How .NET, Python, and React integrate
- [Data Flow](meta-agents/DATA_FLOW.md) - Data flow between components
- [Architecture Decision Records](adrs/) - Key architectural decisions

### API Documentation
- [REST API Reference](api/META_AGENTS_API.md) - Complete REST API documentation
- [SignalR Hubs](api/SIGNALR_HUBS.md) - Real-time communication API
- [Python Agents API](api/PYTHON_AGENTS_API.md) - Python service API reference
- [API Examples](api/EXAMPLES.md) - Request/response examples

### Development
- [Development Setup](development/SETUP.md) - IDE configuration and local development
- [.NET Development](development/DOTNET_DEVELOPMENT.md) - .NET development guide
- [Python Development](development/PYTHON_DEVELOPMENT.md) - Python development guide
- [React Development](development/REACT_DEVELOPMENT.md) - Frontend development guide
- [Testing Guide](development/TESTING.md) - Testing strategies and best practices
- [Contributing Guide](development/CONTRIBUTING.md) - How to contribute

## Documentation by Role

### For Developers

**First Time Setup**:
1. [Quick Start](guides/QUICK_START.md)
2. [Development Setup](development/SETUP.md)
3. [Your First Agent](guides/META_AGENT_GUIDE.md)

**Contributing to Documentation**:
1. [CI/CD Quick Start](guides/developer/ci-cd-quickstart.md) - Run quality checks locally
2. [Documentation Quality Guide](../.github/DOCS-QUALITY-GUIDE.md) - Standards and best practices
3. [CI/CD Troubleshooting](guides/developer/ci-cd-troubleshooting.md) - Fix common issues

**Building Features**:
- [.NET Development Guide](development/DOTNET_DEVELOPMENT.md)
- [Python Development Guide](development/PYTHON_DEVELOPMENT.md)
- [React Development Guide](development/REACT_DEVELOPMENT.md)
- [Testing Guide](development/TESTING.md)

**API Integration**:
- [REST API Reference](api/META_AGENTS_API.md)
- [SignalR Documentation](api/SIGNALR_HUBS.md)
- [API Examples](api/EXAMPLES.md)

### For DevOps / SRE

**Deployment**:
- [Deployment Guide](meta-agents/DEPLOYMENT.md)
- [Infrastructure as Code](../infra/README.md)
- [CI/CD Workflows](../.github/README.md)

**Operations**:
- [Monitoring Guide](runbooks/MONITORING.md)
- [Incident Response](runbooks/INCIDENT_RESPONSE.md)
- [Scaling Guide](runbooks/SCALING_GUIDE.md)
- [Backup & Restore](runbooks/BACKUP_RESTORE.md)

**Troubleshooting**:
- [Troubleshooting Guide](guides/TROUBLESHOOTING.md)
- [Common Issues](guides/TROUBLESHOOTING.md#common-issues)

### For Users

**Getting Started**:
- [Quick Start](guides/QUICK_START.md)
- [Understanding Meta-Agents](guides/META_AGENT_GUIDE.md)
- [Workflow Design](guides/WORKFLOW_DESIGN.md)

**Using the Platform**:
- [Creating Agents](guides/META_AGENT_GUIDE.md#creating-agents)
- [Designing Workflows](guides/WORKFLOW_DESIGN.md)
- [Monitoring Executions](guides/META_AGENT_GUIDE.md#monitoring)

### For Architects

**System Design**:
- [Architecture Overview](meta-agents/ARCHITECTURE.md)
- [Integration Patterns](meta-agents/INTEGRATION.md)
- [Data Flow](meta-agents/DATA_FLOW.md)
- [Security Architecture](meta-agents/ARCHITECTURE.md#security-architecture)

**Decisions**:
- [ADR 002: Meta-Agent Architecture](adrs/002-meta-agent-architecture.md)
- [ADR 003: Vector Database Choice](adrs/003-vector-database-choice.md)
- [ADR 004: .NET-Python Integration](adrs/004-dotnet-python-integration.md)
- [ADR 005: UI Framework Selection](adrs/005-ui-framework-selection.md)

## Key Concepts

### Meta-Agents

AI agents that coordinate and orchestrate multiple specialized agents to accomplish complex tasks. Read more: [Meta-Agent Guide](guides/META_AGENT_GUIDE.md)

### Workflows

Structured execution patterns for multi-agent coordination:
- **Sequential**: Agents execute one after another
- **Concurrent**: Multiple agents execute in parallel
- **Group Chat**: Agents communicate via shared context

Read more: [Workflow Design Guide](guides/WORKFLOW_DESIGN.md)

### Checkpointing

State snapshots that enable workflow recovery and resumption after failures. Read more: [Data Flow](meta-agents/DATA_FLOW.md#state-management-flow)

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| Frontend | React 18 + TypeScript | User interface |
| Backend API | .NET 8 (ASP.NET Core) | Workflow orchestration |
| Agent Service | Python 3.12 (FastAPI) | Agent execution |
| Real-time | SignalR | Live updates |
| Database | Azure Cosmos DB | State and metadata |
| Cache | Azure Redis | Distributed cache |
| Storage | Azure Blob Storage | Artifacts |
| Search | Azure Cognitive Search | Vector database |
| Monitoring | Application Insights | Observability |

## Architecture Diagrams

### High-Level Architecture

```
┌──────────────┐
│   Frontend   │  React + TypeScript
│   (Port      │  Vite, Tailwind CSS
│    5173)     │
└──────┬───────┘
       │ REST + SignalR
       ▼
┌──────────────┐
│  .NET API    │  ASP.NET Core 8.0
│  (Port 5000) │  Workflow Orchestration
└──────┬───────┘
       │ HTTP
       ▼
┌──────────────┐
│  Python Svc  │  FastAPI
│  (Port 8000) │  Agent Execution
└──────┬───────┘
       │
       ▼
┌──────────────────────────────┐
│      Data & Platform         │
│  ┌────────┐  ┌────────┐     │
│  │Cosmos  │  │ Redis  │     │
│  │  DB    │  │ Cache  │     │
│  └────────┘  └────────┘     │
│  ┌────────┐  ┌────────┐     │
│  │ Blob   │  │  Key   │     │
│  │Storage │  │ Vault  │     │
│  └────────┘  └────────┘     │
└──────────────────────────────┘
```

See [Architecture Documentation](meta-agents/ARCHITECTURE.md) for detailed diagrams.

## Common Workflows

### Creating and Running an Agent

```bash
# 1. Create agent
POST /api/v1/agents
{
  "name": "Code Review Agent",
  "type": "code_review",
  "configuration": { "model": "gpt-4" }
}

# 2. Execute agent
POST /api/v1/agents/{agentId}/execute
{
  "parameters": {
    "repository": "org/repo",
    "pull_request": 123
  }
}

# 3. Monitor via SignalR
connection.on('AgentMessage', (msg) => console.log(msg));
```

### Creating and Executing a Workflow

```bash
# 1. Create workflow
POST /api/v1/workflows
{
  "name": "PR Review Pipeline",
  "type": "sequential",
  "steps": [
    { "agent_id": "agent-analyzer", "order": 1 },
    { "agent_id": "agent-security", "order": 2 }
  ]
}

# 2. Execute workflow
POST /api/v1/workflows/{workflowId}/execute
{
  "parameters": { "data": {...} }
}

# 3. Monitor execution
GET /api/v1/executions/{executionId}/status
```

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| 503 Service Unavailable | Check health endpoints, verify services are running |
| Authentication Failed | Verify Azure AD configuration, check token expiration |
| Workflow Execution Stuck | Check execution logs, verify Python service is responsive |
| SignalR Connection Failed | Verify CORS settings, check authentication |

See [Troubleshooting Guide](guides/TROUBLESHOOTING.md) for detailed solutions.

## Support

- **Documentation Issues**: [Submit an issue](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues)
- **Questions**: [GitHub Discussions](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions)
- **Security Issues**: See [Security Policy](../SECURITY.md)
- **Email**: support@brookside-proving-grounds.com

## Contributing

We welcome contributions! Please see:
- [Contributing Guide](development/CONTRIBUTING.md)
- [Code of Conduct](../CODE_OF_CONDUCT.md)
- [Development Setup](development/SETUP.md)

## License

This project is licensed under the MIT License - see [LICENSE](../LICENSE) file.

## Acknowledgments

- Built with [Microsoft's Agentic Framework](https://github.com/microsoft/autogen)
- Powered by [Azure](https://azure.microsoft.com)
- UI components inspired by [Tailwind UI](https://tailwindui.com)

---

**Documentation Version**: 1.0.0
**Last Updated**: 2025-10-07
**Maintained By**: Agent Studio Team

For questions or suggestions about this documentation, please [open an issue](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues).
