---
layout: home

hero:
  name: "Agent Studio"
  text: "AI Agent Orchestration Platform"
  tagline: Build, deploy, and manage intelligent AI agents with enterprise-grade observability and scalability
  image:
    src: /logo.svg
    alt: Agent Studio
  actions:
    - theme: brand
      text: Quick Start
      link: /getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/Brookside-Proving-Grounds/Project-Ascension

features:
  - icon: 🤖
    title: AI Agent Management
    details: Create, configure, and deploy intelligent agents with seamless integration to Azure OpenAI and LLM services
  - icon: 🔄
    title: Workflow Orchestration
    details: Build complex workflows with sequential, parallel, and dynamic agent coordination patterns
  - icon: ☁️
    title: Azure Native
    details: Fully integrated with Azure services - App Service, Cosmos DB, Key Vault, Application Insights
  - icon: 📊
    title: Real-time Observability
    details: OpenTelemetry distributed tracing, SignalR live updates, and comprehensive monitoring
  - icon: 🔐
    title: Enterprise Security
    details: Azure AD integration, RBAC, Key Vault secrets management, and SOC 2 compliance
  - icon: 🚀
    title: DevOps Ready
    details: GitHub Actions CI/CD, automated testing, infrastructure as code with Azure Bicep
---

<style>
.VPButton {
  margin: 8px;
}
</style>

## Choose Your Path

<div class="vp-doc" style="margin-top: 48px;">

### 👨‍💻 I'm a Developer

Get started building AI agents and workflows with Agent Studio.

- [**Quick Start** →](/getting-started) - Set up your environment in 5 minutes
- [**Your First Agent** →](/getting-started/first-agent) - Create your first AI agent
- [**Developer Guides** →](/guides/) - In-depth development documentation
- [**API Reference** →](/api/) - Complete API documentation

### 🚀 I'm a DevOps Engineer

Deploy and operate Agent Studio in production.

- [**Deployment Guide** →](/guides/operator/deployment-azure) - Deploy to Azure
- [**Monitoring** →](/guides/operator/monitoring) - Set up observability
- [**Runbooks** →](/runbooks/) - Operational procedures
- [**Troubleshooting** →](/troubleshooting/) - Common issues and solutions

### 🏛️ I'm an Architect

Understand the system design and make architectural decisions.

- [**Architecture Overview** →](/architecture) - High-level system design
- [**Design Decisions** →](/adrs/) - Architecture Decision Records (ADRs)
- [**Integration Patterns** →](/meta-agents/INTEGRATION) - Service integration strategies
- [**Security Model** →](/architecture/security-model) - Security architecture

### 🆘 I Need Help

Find answers to common questions and get support.

- [**Troubleshooting** →](/troubleshooting/) - Diagnostic guides
- [**FAQ** →](/troubleshooting/faq) - Frequently asked questions
- [**Community Support** →](https://github.com/Brookside-Proving-Grounds/Project-Ascension/discussions) - GitHub Discussions
- [**Report an Issue** →](https://github.com/Brookside-Proving-Grounds/Project-Ascension/issues) - Bug reports

</div>

## Technology Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | React 19 + TypeScript | User interface |
| **Backend API** | .NET 8 (ASP.NET Core) | Workflow orchestration |
| **Agent Service** | Python 3.12 (FastAPI) | Agent execution |
| **Real-time** | SignalR | Live updates |
| **Database** | Azure Cosmos DB | State and metadata |
| **Cache** | Azure Redis | Distributed cache |
| **Storage** | Azure Blob Storage | Artifacts |
| **Monitoring** | Application Insights | Observability |

## Key Features

### Multi-Agent Coordination

Orchestrate multiple AI agents working together to accomplish complex tasks:

- **Sequential Workflows**: Agents execute one after another in a defined order
- **Parallel Workflows**: Multiple agents execute concurrently for maximum throughput
- **Group Chat Patterns**: Agents collaborate through shared context and communication
- **Dynamic Routing**: Intelligent handoffs between specialized agents

### Checkpointing & Recovery

Robust state management ensures workflows can recover from failures:

- **Automatic Checkpoints**: State snapshots at configurable intervals
- **Failure Recovery**: Resume workflows from last successful checkpoint
- **Replay Capability**: Re-execute workflows with historical context
- **State Versioning**: Track and audit workflow state changes

### Enterprise-Grade Security

Built with security and compliance at the core:

- **Azure AD Integration**: Single sign-on with multi-factor authentication
- **RBAC**: Role-based access control with fine-grained permissions
- **Secrets Management**: Azure Key Vault integration for credential storage
- **Audit Logging**: Comprehensive audit trail for compliance
- **Data Encryption**: At-rest and in-transit encryption

## Quick Links

- [Installation Guide](/getting-started/installation)
- [REST API Reference](/api/rest-api)
- [SignalR Hub Contract](/api/signalr-hub)
- [Python Client Library](/api/python-client)
- [Deployment to Azure](/guides/operator/deployment-azure)
- [Architecture Overview](/architecture)
- [Contributing Guide](https://github.com/Brookside-Proving-Grounds/Project-Ascension/blob/main/CONTRIBUTING.md)

## Latest Updates

::: tip Changelog
See the [Changelog](/CHANGELOG.md) for recent updates and release notes.
:::

---

<div style="text-align: center; margin-top: 48px; color: var(--vp-c-text-2);">
  <p><strong>Documentation Version:</strong> 2.0.0</p>
  <p><strong>Last Updated:</strong> 2025-10-08</p>
  <p><strong>Maintained By:</strong> Agent Studio Platform Team</p>
</div>
