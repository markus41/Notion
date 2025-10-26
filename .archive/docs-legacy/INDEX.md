# Documentation Hub - Brookside BI Innovation Nexus

**Welcome to the Innovation Nexus documentation.** This platform establishes structured approaches for tracking ideas from concept through research, building, and knowledge archival using Notion as the central hub with Microsoft ecosystem integrations.

**Best for**: Organizations scaling innovation workflows across teams who require enterprise-grade reliability, cost transparency, and sustainable knowledge management practices.

---

## Quick Navigation

### I'm New Here - Quick Start

- **[Getting Started Guide](getting-started/README.md)** - Installation, authentication, and first steps
- **[First Steps Tutorial](getting-started/first-steps.md)** - Create your first idea in 30 minutes
- **[Common Workflows](getting-started/common-workflows.md)** - Top 5 workflows for new users
- **[Troubleshooting](guides/troubleshooting.md)** - Common issues and solutions

### Find Documentation by Your Role

**New User** (First time with Innovation Nexus)
- [Installation & Setup](getting-started/installation.md)
- [Authentication Guide](getting-started/authentication.md) - Azure, GitHub, Notion
- [Common Workflows](getting-started/common-workflows.md)
- [Troubleshooting](guides/troubleshooting.md)

**Business User** (Tracking ideas and costs)
- [Innovation Lifecycle Guide](guides/innovation-lifecycle.md) - Idea → Research → Build → Archive
- [Cost Management](guides/cost-management.md) - Track software spend and optimize
- [Knowledge Archival](guides/knowledge-archival.md) - Preserve learnings
- [Team Collaboration](guides/team-collaboration.md) - Multi-user workflows

**Developer** (Building integrations and features)
- [Technical Overview](technical/README.md)
- [Local Development Setup](technical/development/local-setup.md)
- [Integration Guides](technical/integrations/README.md) - Azure, GitHub, Notion MCPs
- [API Reference](technical/api-reference/README.md)
- [Coding Standards](technical/development/coding-standards.md) - Brookside BI guidelines

**Architect** (System design and patterns)
- [System Architecture](technical/architecture/README.md)
- [Architectural Patterns](patterns/README.md) - Circuit-breaker, Saga, Event Sourcing
- [Pattern Selection Guide](patterns/pattern-selection-guide.md) - When to use which pattern
- [Azure Webhook Architecture](technical/architecture/azure-webhook-architecture.md)
- [Notion Schema Design](technical/architecture/notion-schema.md)

**DevOps / IT Operations** (Deployment and monitoring)
- [Operations Guide](operations/README.md)
- [Azure Deployment](operations/deployment/azure-deployment.md)
- [Monitoring Setup](operations/monitoring/README.md) - Application Insights, cost tracking
- [Maintenance Procedures](operations/maintenance/README.md)
- [Disaster Recovery](operations/maintenance/disaster-recovery.md)

**Project Manager** (Planning and tracking)
- [Strategic Initiatives](project-management/strategic-initiatives.md) - OKRs and roadmap
- [Release History](project-management/release-history.md) - Version history
- [Roadmap](project-management/roadmap.md) - Feature pipeline
- [Brainstorming Archive](project-management/brainstorming/) - Historical planning docs

---

## Find Documentation by Task

### Creating Innovation

**I want to capture a new idea**
- Guide: [Creating Ideas](guides/innovation-lifecycle.md#creating-ideas)
- Slash Command: `/innovation:new-idea [description]`
- Agent: [@ideas-capture](../.claude/agents/ideas-capture.md)

**I want to start research on an idea**
- Guide: [Research Workflows](guides/innovation-lifecycle.md#research-phase)
- Slash Command: `/innovation:start-research [topic] [idea-name]`
- Agent: [@research-coordinator](../.claude/agents/research-coordinator.md)

**I want to build a prototype**
- Guide: [Build Creation](guides/innovation-lifecycle.md#build-phase)
- Technical: [Build Architecture](technical/architecture/README.md)
- Agent: [@build-architect](../.claude/agents/build-architect.md)

**I want to archive completed work**
- Guide: [Knowledge Archival](guides/knowledge-archival.md)
- Slash Command: `/knowledge:archive [item-name] [database]`
- Agent: [@archive-manager](../.claude/agents/archive-manager.md)

### Managing Costs

**I want to see total software spending**
- Guide: [Cost Management](guides/cost-management.md)
- Slash Command: `/cost:monthly-spend` or `/cost:analyze all`
- Agent: [@cost-analyst](../.claude/agents/cost-analyst.md)

**I want to find unused software**
- Guide: [Cost Optimization](guides/cost-management.md#optimization-strategies)
- Slash Command: `/cost:unused-software`

**I want Microsoft alternatives to current tools**
- Guide: [Microsoft-First Strategy](guides/cost-management.md#microsoft-alternatives)
- Slash Command: `/cost:microsoft-alternatives [tool-name]`

**I want to check expiring contracts**
- Slash Command: `/cost:expiring-contracts`

### Technical Operations

**I want to deploy to Azure**
- Guide: [Azure Deployment](operations/deployment/azure-deployment.md)
- Technical: [Azure Webhook Architecture](technical/architecture/azure-webhook-architecture.md)
- Integration: [Azure MCP Setup](technical/integrations/azure-mcp.md)

**I want to set up GitHub integration**
- Guide: [GitHub MCP Integration](technical/integrations/github-mcp.md)
- Technical: [Repository Automation](technical/automation/repository-hooks.md)

**I want to configure Notion workspace**
- Guide: [Notion Population](guides/notion-population.md)
- Technical: [Notion Schema](technical/architecture/notion-schema.md)
- Integration: [Notion MCP](technical/integrations/notion-mcp.md)

**I want to set up secret management**
- Guide: [Azure Key Vault Setup](technical/integrations/key-vault.md)
- Security: [Secret Management Best Practices](operations/security.md)

### Agent & Automation

**I want to create a custom agent**
- Guide: [Creating Agents](agents/creating-agents.md)
- Reference: [Agent Registry](agents/agent-registry.md) - All 28+ available agents
- Best Practices: [Agent Design Patterns](agents/agent-best-practices.md)

**I want to use slash commands**
- Reference: [Command Catalog](commands/command-reference.md)
- Guide: [Creating Commands](commands/creating-commands.md)
- Examples: [Command Usage Patterns](commands/README.md)

**I want to set up autonomous workflows**
- Technical: [Autonomous Pipelines](technical/automation/autonomous-pipelines.md)
- Integration: [GitHub Actions](technical/automation/github-actions.md)
- Patterns: [Event Sourcing](patterns/event-sourcing.md)

### Troubleshooting

**Something isn't working**
- [Troubleshooting Guide](guides/troubleshooting.md) - Common issues
- [MCP Connection Issues](technical/integrations/README.md#troubleshooting)
- [Azure Authentication Problems](getting-started/authentication.md#troubleshooting)
- [Notion API Errors](technical/integrations/notion-mcp.md#common-errors)

---

## Complete Documentation Inventory

### Getting Started

**Directory**: [`getting-started/`](getting-started/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](getting-started/README.md) | Quick start overview | All new users |
| [Installation](getting-started/installation.md) | Setup instructions for Innovation Nexus | Developers, IT |
| [Authentication](getting-started/authentication.md) | Azure, GitHub, Notion authentication | All users |
| [First Steps](getting-started/first-steps.md) | 30-minute tutorial - Create first idea | New users |
| [Common Workflows](getting-started/common-workflows.md) | Top 5 workflows for daily use | All users |

### User Guides

**Directory**: [`guides/`](guides/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](guides/README.md) | Guide index | All users |
| [Innovation Lifecycle](guides/innovation-lifecycle.md) | Idea → Research → Build → Archive | All users |
| [Notion Population](guides/notion-population.md) | Complete database population guide | Admins, PMs |
| [Cost Management](guides/cost-management.md) | Software cost tracking and optimization | Business users, Finance |
| [Knowledge Archival](guides/knowledge-archival.md) | Preserve learnings in Knowledge Vault | All users |
| [Team Collaboration](guides/team-collaboration.md) | Multi-user workflows | All users |
| [Troubleshooting](guides/troubleshooting.md) | Common issues and solutions | All users |

### Technical Documentation

**Directory**: [`technical/`](technical/)

#### Architecture

**Subdirectory**: [`technical/architecture/`](technical/architecture/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](technical/architecture/README.md) | Architecture overview | Architects, Developers |
| [System Overview](technical/architecture/system-overview.md) | High-level system design | All technical |
| [Azure Webhook Architecture](technical/architecture/azure-webhook-architecture.md) | Event-driven integration design | Architects, DevOps |
| [Notion Schema](technical/architecture/notion-schema.md) | Database structure and relations | Architects, Developers |
| [Integration Patterns](technical/architecture/integration-patterns.md) | Cross-system integration approaches | Architects |
| [Data Flow](technical/architecture/data-flow.md) | Data movement and transformations | Architects, Developers |

#### Development

**Subdirectory**: [`technical/development/`](technical/development/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](technical/development/README.md) | Developer guide index | Developers |
| [Local Setup](technical/development/local-setup.md) | Development environment configuration | Developers |
| [Coding Standards](technical/development/coding-standards.md) | Brookside BI code guidelines | Developers |
| [Testing Strategy](technical/development/testing-strategy.md) | Test approach and frameworks | Developers |
| [Git Workflow](technical/development/git-workflow.md) | Branching, PRs, commits | Developers |
| [Debugging](technical/development/debugging.md) | Troubleshooting techniques | Developers |

#### Integrations

**Subdirectory**: [`technical/integrations/`](technical/integrations/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](technical/integrations/README.md) | Integration overview | All technical |
| [Azure MCP](technical/integrations/azure-mcp.md) | Azure MCP server setup | Developers, DevOps |
| [Azure Quick Start](technical/integrations/azure-quick-start.md) | Rapid Azure integration | Developers |
| [GitHub MCP](technical/integrations/github-mcp.md) | GitHub MCP server configuration | Developers |
| [Notion MCP](technical/integrations/notion-mcp.md) | Notion integration details | Developers |
| [Playwright MCP](technical/integrations/playwright-mcp.md) | Browser automation setup | Developers |
| [Key Vault](technical/integrations/key-vault.md) | Secret management with Azure Key Vault | Developers, DevOps |

#### Automation

**Subdirectory**: [`technical/automation/`](technical/automation/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](technical/automation/README.md) | Automation overview | Developers, DevOps |
| [Repository Hooks](technical/automation/repository-hooks.md) | Git automation and pre-commit hooks | Developers |
| [GitHub Actions](technical/automation/github-actions.md) | CI/CD workflows | DevOps |
| [Azure Functions](technical/automation/azure-functions.md) | Serverless automation | Developers, DevOps |
| [Autonomous Pipelines](technical/automation/autonomous-pipelines.md) | Self-managing workflows | Architects, DevOps |

#### API Reference

**Subdirectory**: [`technical/api-reference/`](technical/api-reference/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](technical/api-reference/README.md) | API overview | Developers |
| [Notion API](technical/api-reference/notion-api.md) | Notion API usage patterns | Developers |
| [MCP Servers](technical/api-reference/mcp-servers.md) | MCP server specifications | Developers |
| [CLI Commands](technical/api-reference/cli-commands.md) | Command-line interface reference | All technical |

### Agent System

**Directory**: [`agents/`](agents/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](agents/README.md) | Agent system overview | All users |
| [Agent Registry](agents/agent-registry.md) | Complete catalog of 28+ agents | All users |
| [Creating Agents](agents/creating-agents.md) | How to build custom agents | Developers |
| [Agent Delegation](agents/agent-delegation.md) | Routing and orchestration patterns | Architects, Developers |
| [Agent Best Practices](agents/agent-best-practices.md) | Design patterns for agents | Developers |

**Note**: Individual agent definitions are in [`.claude/agents/`](../.claude/agents/) directory.

### Slash Commands

**Directory**: [`commands/`](commands/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](commands/README.md) | Slash command overview | All users |
| [Command Reference](commands/command-reference.md) | Complete command catalog | All users |
| [Creating Commands](commands/creating-commands.md) | How to build new commands | Developers |

**Note**: Individual command definitions are in [`.claude/commands/`](../.claude/commands/) directory.

### Architectural Patterns

**Directory**: [`patterns/`](patterns/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](patterns/README.md) | Pattern library overview | Architects, Senior Devs |
| [Circuit-Breaker](patterns/circuit-breaker.md) | Resilience pattern for cloud integrations | Architects |
| [Retry with Exponential Backoff](patterns/retry-exponential-backoff.md) | Transient failure handling | Developers |
| [Saga Pattern](patterns/saga-distributed-transactions.md) | Distributed transaction consistency | Architects |
| [Event Sourcing](patterns/event-sourcing.md) | Complete audit trails | Architects, Compliance |
| [Pattern Selection Guide](patterns/pattern-selection-guide.md) | When to use which pattern | Architects |

**Note**: Pattern definitions are symlinked from [`.claude/docs/patterns/`](../.claude/docs/patterns/).

### Operations

**Directory**: [`operations/`](operations/)

#### Deployment

**Subdirectory**: [`operations/deployment/`](operations/deployment/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](operations/deployment/README.md) | Deployment guide index | DevOps |
| [Azure Deployment](operations/deployment/azure-deployment.md) | Azure resource provisioning | DevOps |
| [GitHub Deployment](operations/deployment/github-deployment.md) | Repository setup automation | DevOps |
| [Notion Workspace Setup](operations/deployment/notion-workspace-setup.md) | Notion configuration | Admins, DevOps |

#### Monitoring

**Subdirectory**: [`operations/monitoring/`](operations/monitoring/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](operations/monitoring/README.md) | Monitoring overview | DevOps, IT Ops |
| [Application Insights](operations/monitoring/application-insights.md) | Azure monitoring setup | DevOps |
| [Cost Tracking](operations/monitoring/cost-tracking.md) | Spend monitoring dashboards | DevOps, Finance |
| [Health Checks](operations/monitoring/health-checks.md) | System health validation | DevOps |

#### Maintenance

**Subdirectory**: [`operations/maintenance/`](operations/maintenance/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](operations/maintenance/README.md) | Maintenance guide | DevOps, IT Ops |
| [Backup & Restore](operations/maintenance/backup-restore.md) | Data protection procedures | DevOps |
| [Updates](operations/maintenance/updates.md) | Version upgrade process | DevOps |
| [Disaster Recovery](operations/maintenance/disaster-recovery.md) | Incident response runbook | DevOps |

### Project Management

**Directory**: [`project-management/`](project-management/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](project-management/README.md) | PM docs overview | PMs, Leadership |
| [Strategic Initiatives](project-management/strategic-initiatives.md) | OKRs and strategic goals | Leadership, PMs |
| [Roadmap](project-management/roadmap.md) | Feature pipeline and timeline | All stakeholders |
| [Release History](project-management/release-history.md) | Version history and changes | All stakeholders |
| [Brainstorming Archive](project-management/brainstorming/) | Historical planning documents | PMs, Leadership |

### Archive

**Directory**: [`archive/`](archive/)

Historical documentation from completed project phases. These documents are preserved for institutional memory and compliance but are not part of active operational documentation.

| Directory | Description | Content |
|-----------|-------------|---------|
| [phase-3/](archive/phase-3/) | Phase 3 implementation records | Implementation summaries, test reports, completion docs |
| [autonomous-platform/](archive/autonomous-platform/) | Autonomous platform implementation | Schema updates, implementation records |
| [batch-operations/](archive/batch-operations/) | Batch population specifications | Agent/command specs, Knowledge Vault specs |

### Templates

**Directory**: [`templates/`](templates/)

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](templates/README.md) | Template catalog | All users |
| [ADR Template](templates/adr-template.md) | Architecture Decision Record template | Architects |
| [Runbook Template](templates/runbook-template.md) | Operational procedure template | DevOps |
| [Research Template](templates/research-template.md) | Research Hub entry template | Researchers |

**Note**: Templates are symlinked from [`.claude/templates/`](../.claude/templates/).

---

## Search Tips

### Finding Documentation Quickly

**By Keyword**:
- Use your IDE's full-text search (Ctrl+Shift+F in VS Code)
- Search within `docs/` directory for active documentation
- Include `.claude/` if searching for agent or command definitions

**By File Name**:
- Use fuzzy file finder (Ctrl+P in VS Code)
- Common patterns: `*deployment*.md`, `*cost*.md`, `*notion*.md`

**By Topic**:
- Start with this INDEX.md for topic-to-file mapping
- Use subdirectory README.md files for category-specific navigation
- Check "Related Documentation" sections in individual files

### Common Search Scenarios

| I'm Looking For... | Start Here |
|-------------------|------------|
| How to install/setup | [Getting Started](getting-started/README.md) |
| Cost tracking | [Cost Management](guides/cost-management.md) |
| Azure deployment | [Operations - Deployment](operations/deployment/README.md) |
| Agent documentation | [Agent Registry](agents/agent-registry.md) |
| Slash commands | [Command Reference](commands/command-reference.md) |
| Architecture patterns | [Patterns Library](patterns/README.md) |
| API reference | [Technical - API Reference](technical/api-reference/README.md) |
| Troubleshooting | [Troubleshooting Guide](guides/troubleshooting.md) |

---

## Related Resources

### External Documentation

- **Notion API**: [developers.notion.com](https://developers.notion.com/)
- **Azure Documentation**: [docs.microsoft.com/azure](https://docs.microsoft.com/azure)
- **GitHub API**: [docs.github.com/rest](https://docs.github.com/rest)
- **Model Context Protocol**: [modelcontextprotocol.io](https://modelcontextprotocol.io/)

### Repository-Specific

- **Main Configuration**: [CLAUDE.md](../CLAUDE.md) - Primary AI agent configuration
- **Workspace Configuration**: [WORKSPACE.md](../WORKSPACE.md) - Notion workspace details
- **Agent Definitions**: [.claude/agents/](../.claude/agents/) - 28+ specialized agents
- **Slash Commands**: [.claude/commands/](../.claude/commands/) - Executable workflows
- **Repository Analyzer**: [brookside-repo-analyzer/](../brookside-repo-analyzer/) - GitHub analysis tool

### Support

- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047
- **GitHub Issues**: [Report documentation issues](https://github.com/brookside-bi/[repo]/issues)

---

## Documentation Maintenance

### Contributing to Documentation

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Writing documentation that aligns with Brookside BI brand
- Creating clear, AI-agent-executable technical content
- Submitting documentation improvements via Pull Request
- Documentation review process

### Documentation Standards

- **Brand Voice**: Professional, consultative, solution-focused (see [Brand Guidelines](../CLAUDE.md#brookside-bi-brand-guidelines))
- **Format**: Markdown with consistent heading hierarchy
- **Structure**: Lead with benefit/outcome, include "Best for:" sections
- **Technical Docs**: AI-agent executable with explicit versions and verification steps
- **Code Examples**: Commented with business value first

### Reporting Issues

Found a broken link, outdated information, or missing documentation?

1. **Check Recent Updates**: Documentation may have moved (see [STRUCTURE_PROPOSAL.md](STRUCTURE_PROPOSAL.md))
2. **Search for Redirects**: Look for breadcrumb notes in old locations
3. **Report Issue**: Create GitHub issue with `documentation` label
4. **Quick Fix**: Submit PR with correction (preferred for simple fixes)

---

## Recent Changes

### October 2025 - Documentation Reorganization

**Major Update**: Complete documentation restructure to improve discoverability and scalability.

**What Changed**:
- Established `docs/` directory with audience-based organization
- Migrated 18 root-level files to appropriate subdirectories
- Created Archive directory for historical implementation docs
- Added comprehensive navigation via this INDEX.md
- Enhanced agent and command documentation

**Migration Guide**:
- See [STRUCTURE_PROPOSAL.md](STRUCTURE_PROPOSAL.md) for complete details
- Old file locations → new locations mapping available
- Breadcrumb notes in moved files during transition period

**Impact**:
- 70% reduction in root directory clutter
- Improved search and navigation for all user types
- Scalable structure supporting future documentation growth

---

## Frequently Asked Questions

### Where do I find...?

**Q: Where is the main project README?**
A: [Getting Started](getting-started/README.md) serves as the functional README. Root README.md links here.

**Q: Where are agent definitions?**
A: Individual agents are in [`.claude/agents/`](../.claude/agents/). Overview and registry are in [docs/agents/](agents/).

**Q: Where are slash command definitions?**
A: Individual commands are in [`.claude/commands/`](../.claude/commands/). Reference guide is in [docs/commands/](commands/).

**Q: Where are architectural patterns?**
A: Patterns are in [`.claude/docs/patterns/`](../.claude/docs/patterns/) with symlinks in [docs/patterns/](patterns/).

**Q: Where did MASTER_NOTION_POPULATION_GUIDE.md go?**
A: Moved to [docs/guides/notion-population.md](guides/notion-population.md). See [STRUCTURE_PROPOSAL.md](STRUCTURE_PROPOSAL.md) for all migrations.

### Using the Documentation

**Q: I'm new - where do I start?**
A: [Getting Started Guide](getting-started/README.md) → [First Steps Tutorial](getting-started/first-steps.md)

**Q: How do I contribute to docs?**
A: See [CONTRIBUTING.md](../CONTRIBUTING.md) for documentation contribution guidelines.

**Q: Can I use this documentation for my own project?**
A: Contact Consultations@BrooksideBI.com for licensing and reuse guidelines.

**Q: How often is documentation updated?**
A: Documentation is updated continuously. Last major restructure: October 2025.

---

**Last Updated**: 2025-10-21
**Documentation Version**: 2.0 (Post-October 2025 reorganization)
**Maintained By**: Brookside BI Innovation Nexus Team

---

**Best for**: Organizations establishing sustainable innovation management practices through comprehensive, discoverable documentation that supports growth and drives measurable outcomes with structured approaches.
