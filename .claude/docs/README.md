# Technical Documentation Hub

**Brookside BI Innovation Nexus** - Comprehensive technical documentation for agents, developers, and system operators.

**Last Updated**: 2025-10-26 | **Status**: Active

---

## Quick Navigation

### 🚀 Getting Started
- **[Configuration & Environment](configuration.md)** - Setup, environment variables, repository hooks
- **[MCP Configuration](mcp-configuration.md)** - MCP server authentication and troubleshooting
- **[Azure Infrastructure](azure-infrastructure.md)** - Subscription, Key Vault, daily workflow

### 📊 Core Workflows
- **[Innovation Workflow](innovation-workflow.md)** ⭐ - Complete lifecycle (Idea → Research → Build → Knowledge)
- **[Common Workflows](common-workflows.md)** - Step-by-step procedures for frequent operations
- **[Notion Schema](notion-schema.md)** - Database architecture, relations, rollups

### 👥 Team & Operations
- **[Team Structure](team-structure.md)** - Member specializations, assignment routing
- **[Agent Activity Center](agent-activity-center.md)** - 3-tier tracking, hook architecture
- **[Agent Guidelines](agent-guidelines.md)** - Core principles, security, brand voice

### 🏢 Microsoft Ecosystem
- **[Microsoft Ecosystem](microsoft-ecosystem.md)** - Service priority, decision framework, cost optimization
- **[Azure OpenAI Integration](azure-openai-integration-architecture.md)** - AI service integration patterns

### 🔗 Integrations & Architecture
- **[Webhook Architecture](webhook-architecture.md)** - Real-time agent activity tracking
- **[Azure APIM MCP Configuration](azure-apim-mcp-configuration.md)** - API Management integration
- **[Architecture Diagrams](architecture-diagrams.md)** - Visual system documentation

### 📈 Measurement & Quality
- **[Success Metrics](success-metrics.md)** - KPIs, measurement framework, quarterly reviews

---

## Documentation Structure

### Active Documentation (This Directory)

**Core Guides** (11 files):
```
.claude/docs/
├── innovation-workflow.md          # Complete innovation lifecycle
├── common-workflows.md             # Step-by-step procedures
├── notion-schema.md                # Database architecture
├── azure-infrastructure.md         # Cloud configuration
├── mcp-configuration.md            # MCP server setup
├── team-structure.md               # Team coordination
├── agent-activity-center.md        # Activity tracking
├── configuration.md                # Environment setup
├── microsoft-ecosystem.md          # Service priority
├── agent-guidelines.md             # Agent operations
└── success-metrics.md              # Measurement framework
```

**Integration & Architecture**:
- webhook-architecture.md
- webhook-troubleshooting.md
- azure-apim-mcp-configuration.md
- azure-openai-integration-architecture.md
- architecture-diagrams.md

**Notion Specific**:
- notion-connection-overhaul-findings.md
- notion-mcp-improvement-analysis.md
- notion-mcp-limitations.md
- NOTION_MCP_MULTI_REPO_GUIDE.md

**Repository Intelligence**:
- repository-analyzer-dependency-linking.md

### Agent Specifications

**Location**: [.claude/agents/](./../agents/)

38+ specialized agents organized by function:
- **Innovation Agents**: ideas-capture, research-coordinator, build-architect, archive-manager
- **Analysis Agents**: cost-analyst, viability-assessor, workflow-router
- **Technical Agents**: integration-specialist, schema-manager, notion-mcp-specialist, repo-analyzer
- **Documentation Agents**: knowledge-curator, markdown-expert, mermaid-diagram-expert
- **Research Swarm**: market-researcher, technical-analyst, risk-assessor, cost-feasibility-analyst
- **Phase 3 Build**: build-architect, code-generator, deployment-orchestrator
- **Autonomous**: notion-orchestrator, integration-monitor, documentation-sync, github-notion-sync

**→ Full Directory**: [Agent Registry](./../agents/)

### Command Reference

**Location**: [.claude/commands/](./../commands/)

All slash commands with usage examples:
- `/innovation:*` - Innovation lifecycle commands
- `/cost:*` - Cost analysis and optimization
- `/repo:*` - Repository intelligence
- `/docs:*` - Documentation management
- `/team:*` - Team coordination
- `/agent:*` - Agent operations
- `/style:*` - Output style testing and analytics
- `/autonomous:*` - Autonomous pipeline operations

**→ Full Directory**: [Commands](./../commands/)

### Output Styles

**Location**: [.claude/styles/](./../styles/)

Style definitions for agent outputs:
- business-executive.md - High-level summaries for leadership
- technical-deep-dive.md - Comprehensive technical detail
- concise-actionable.md - Brief, action-oriented
- visual-diagram-rich.md - Heavy use of diagrams and visuals
- conversational-friendly.md - Approachable, explanatory tone

**→ Full Directory**: [Styles](./../styles/)

### Architectural Patterns

**Location**: [.claude/docs/patterns/](./../docs/patterns/)

Enterprise patterns for scalable operations:
- Circuit Breaker
- Retry with Exponential Backoff
- Saga Pattern
- Event Sourcing
- CQRS (Command Query Responsibility Segregation)

**→ Full Directory**: [Patterns](patterns/)

### Templates

**Location**: [.claude/templates/](./../templates/)

Reusable documentation templates:
- ADR (Architecture Decision Record)
- Research Entry
- Runbook
- Incident Report

**→ Full Directory**: [Templates](./../templates/)

---

## Historical Archive

**Location**: [.archive/](./../../.archive/)

23 archived documents organized by category:
- **Phases**: Phase 1-3 completion reports
- **Implementations**: Implementation summaries and quickstarts
- **Assessments**: Analysis and compatibility reports
- **Sessions**: Historical session summaries
- **Projects**: Archived project files
- **Docs Legacy**: Superseded documentation

**→ Full Index**: [.archive/README.md](./../../.archive/README.md)

**Preservation Policy**: All historical documentation is permanently retained for reference. Archive files are never deleted, only relocated for organizational clarity.

---

## Documentation Standards

### Brookside BI Brand Voice

**All documentation MUST follow these guidelines:**

**Voice & Tone**:
- Professional but approachable
- Solution-focused (emphasize outcomes)
- Consultative & strategic (long-term sustainability)

**Core Language Patterns**:
- "Establish structure and rules for..."
- "Streamline workflows and improve visibility"
- "Drive measurable outcomes through..."
- "Best for: [clear use case context]"

**Structure**:
- Lead with benefit/outcome before technical details
- Include "Best for:" context qualifiers
- Use clear visual hierarchy
- Structure for AI-agent execution (explicit, idempotent)

**→ Full Guidelines**: See [CLAUDE.md](./../../CLAUDE.md) Brookside BI Brand Guidelines section

### Documentation Lifecycle

**Active Documentation** (.claude/docs/):
- Updated regularly
- Reviewed quarterly
- Referenced in CLAUDE.md
- Maintained by core team

**Deprecated Documentation**:
1. Mark as deprecated with warning banner
2. Update references to point to replacement
3. After 30 days, move to .archive/docs-legacy/
4. Preserve permanently for reference

**Archive Documentation** (.archive/):
- Retained permanently
- Organized by category
- Indexed in .archive/README.md
- Read-only (historical reference)

---

## Contributing to Documentation

### Quick Updates

**Minor fixes** (typos, broken links, clarifications):
```powershell
git checkout -b docs/fix-typo-in-notion-schema
# Make changes
git add .
git commit -m "docs(notion-schema): Fix typo in relation rules section"
git push -u origin docs/fix-typo-in-notion-schema
# Create PR
```

### Major Updates

**Significant changes** (new sections, restructuring):
1. Use `/docs:update-complex` slash command for multi-file updates
2. Review [Common Workflows](common-workflows.md) for documentation procedures
3. Follow [Contributing Guidelines](./../../CONTRIBUTING.md)

### Documentation Review Checklist

Before submitting documentation changes:
- [ ] Brookside BI brand voice applied
- [ ] Links tested (no broken references)
- [ ] Code examples tested (if applicable)
- [ ] "Best for:" context included
- [ ] Outcome-focused language used
- [ ] Visual hierarchy clear (headers, bullets, emphasis)
- [ ] AI-agent executable (explicit, no ambiguity)
- [ ] Cross-references updated
- [ ] CLAUDE.md updated (if adding new core doc)
- [ ] README.md updated (if changing structure)

---

## Documentation Metrics

**Current Statistics** (2025-10-26):
- **Core Guides**: 11 files, ~83,000 words
- **Integration Docs**: 7 files, ~31,000 words
- **Agent Specs**: 38 files, ~140,000 words
- **Commands**: 39 files, ~22,000 words
- **Styles**: 5 files, ~8,500 words
- **Patterns**: 5 files, ~12,000 words
- **Templates**: 4 files, ~6,000 words
- **Archived**: 23 files, ~210,000 words

**Total**: 132 documentation files, ~512,500 words

**Reduction**: Root level reduced from 42 files (2025-10-22) to 7 essential guides (2025-10-26)

---

## Support

**Documentation Issues**:
- Check [Troubleshooting Guide](./../../TROUBLESHOOTING.md) for common issues
- Review [Agent Activity Center](agent-activity-center.md) for logging questions
- See [Configuration](configuration.md) for setup problems

**Technical Questions**:
- Review [Innovation Workflow](innovation-workflow.md) for process questions
- Check [Notion Schema](notion-schema.md) for database operations
- See [Azure Infrastructure](azure-infrastructure.md) for cloud configuration

**Contact**: Consultations@BrooksideBI.com | +1 209 487 2047

---

**Brookside BI Innovation Nexus** - Where comprehensive documentation drives sustainable operations and enables autonomous workflows.
