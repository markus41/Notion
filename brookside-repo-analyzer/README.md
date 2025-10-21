# 🚀 Brookside BI Innovation Nexus Repository Analyzer

Analyzes all repositories in the brookside-bi GitHub organization and creates a comprehensive knowledge base in Notion. This solution is designed to streamline portfolio management and drive measurable outcomes through automated pattern extraction and cost tracking.

**Best for:** Organizations managing multiple repositories requiring automated analysis, cost visibility, and knowledge base generation to support sustainable growth.

## 📋 Overview

This Python-based CLI tool leverages existing GitHub MCP and Notion MCP integrations to:

- 📊 **Scan organization repositories** - Automated discovery and metadata extraction
- 🔍 **Analyze code quality** - Viability scoring based on tests, activity, documentation, dependencies
- 🎯 **Extract patterns** - Identify reusable components and architectural patterns
- 💰 **Calculate costs** - Map dependencies to monthly costs via Software Tracker
- 📝 **Sync to Notion** - Automated Example Build and Knowledge Vault entries
- 🤖 **Detect Claude configs** - Parse .claude/ directories for agent/command capabilities

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│         Deployment Options (3 modes)           │
├──────────────┬─────────────┬───────────────────┤
│ Local CLI    │ Azure Func  │ GitHub Actions    │
│ (on-demand)  │ (weekly)    │ (event-triggered) │
└──────┬───────┴──────┬──────┴────────┬──────────┘
       │              │               │
       └──────────────┼───────────────┘
                      │
          ┌───────────▼────────────┐
          │  Core Analysis Engine  │
          └───────────┬────────────┘
                      │
        ┌─────────────┼──────────────┐
        │             │              │
  ┌─────▼──────┐ ┌───▼────┐  ┌─────▼──────┐
  │ GitHub MCP │ │ Pattern│  │ Cost       │
  │ Client     │ │ Miner  │  │ Calculator │
  └─────┬──────┘ └───┬────┘  └─────┬──────┘
        │            │              │
        └────────────┼──────────────┘
                     │
              ┌──────▼───────┐
              │ Notion MCP   │
              │ Sync Engine  │
              └──────┬───────┘
                     │
     ┌───────────────┼──────────────┐
     │               │              │
┌────▼───┐    ┌─────▼─────┐  ┌────▼────┐
│ Example│    │ Knowledge │  │Software │
│ Builds │    │  Vault    │  │ Tracker │
└────────┘    └───────────┘  └─────────┘
```

## 🚀 Quick Start

### Prerequisites

```bash
# Required
python >= 3.11
poetry >= 1.7.0
azure-cli >= 2.77.0

# Verify installations
python --version
poetry --version
az --version
```

### Installation

```bash
# Clone repository
cd C:\Users\MarkusAhling\Notion\brookside-repo-analyzer

# Install dependencies
poetry install

# Configure environment
cp .env.example .env

# Authenticate with Azure (for Key Vault access)
az login
az account set --subscription "Azure subscription 1"
```

### Configuration

Secrets are automatically retrieved from Azure Key Vault (`kv-brookside-secrets`):

- `github-personal-access-token` → GitHub API authentication
- `notion-api-key` → Notion API authentication (if stored)

Environment variables (`.env`):

```bash
# Azure Configuration
AZURE_KEYVAULT_NAME=kv-brookside-secrets
AZURE_TENANT_ID=2930489e-9d8a-456b-9de9-e4787faeab9c

# GitHub Configuration
GITHUB_ORG=brookside-bi

# Notion Configuration
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e

# Analysis Configuration
ANALYSIS_CACHE_TTL_HOURS=168
MAX_CONCURRENT_ANALYSES=10
DEEP_ANALYSIS_ENABLED=true
DETECT_CLAUDE_CONFIGS=true
CALCULATE_COSTS=true
```

### Usage

```bash
# Scan entire organization (full analysis)
poetry run brookside-analyze scan --full

# Scan with Notion sync
poetry run brookside-analyze scan --full --sync

# Analyze single repository
poetry run brookside-analyze analyze my-repo --deep

# Extract patterns
poetry run brookside-analyze patterns

# Calculate costs
poetry run brookside-analyze costs
```

## 📊 Features

### Repository Analysis

**Viability Scoring (0-100):**
- Test Coverage: 30 points (70%+ coverage = 30 pts)
- Recent Activity: 20 points (commits in last 30 days)
- Documentation: 25 points (README + additional docs)
- Dependency Health: 25 points (0-10 deps = 25 pts)

**Ratings:**
- 💎 High (75-100): Production-ready, well-maintained
- ⚡ Medium (50-74): Needs work, functional
- 🔻 Low (0-49): Reference only or abandoned

**Reusability Assessment:**
- 🔄 Highly Reusable: Viable, tested, documented, active
- ↔️ Partially Reusable: Some quality indicators
- 🔒 One-Off: Project-specific, low reuse potential

### Claude Code Detection

Analyzes `.claude/` directory to extract:
- Agent definitions (`.claude/agents/*.md`)
- Slash commands (`.claude/commands/*.md`)
- MCP server configurations (`.claude.json`)
- Project memory (`CLAUDE.md`)

**Maturity Levels:**
- Expert (80-100): Comprehensive integration
- Advanced (60-79): Well-integrated
- Intermediate (30-59): Basic integration
- Basic (10-29): Minimal integration
- None (0-9): No integration

### Pattern Mining

**Identified Patterns:**
- Architectural: Serverless, RESTful API, Microservices
- Integration: Microsoft services, shared dependencies
- Design: Common frameworks and libraries

**Output:**
- Pattern library in Knowledge Vault
- Usage statistics across repositories
- Reusability scores

### Cost Calculation

**Features:**
- Dependency cost mapping
- Monthly/annual cost projections
- Cost optimization opportunities
- Microsoft alternative suggestions

**Known Costs:**
- Azure Functions: $5/month
- Azure Storage: $2/month
- Azure Key Vault: $0.03/secret/month
- Third-party services: Stripe, SendGrid, Auth0, etc.

## 🔧 Development

### Project Structure

```
brookside-repo-analyzer/
├── src/
│   ├── __init__.py              # Package initialization
│   ├── config.py                # Pydantic settings
│   ├── exceptions.py            # Error hierarchy
│   ├── auth.py                  # Azure Key Vault integration
│   ├── models.py                # Data models
│   ├── github_mcp_client.py     # GitHub API wrapper
│   ├── notion_client.py         # Notion API wrapper
│   ├── cli.py                   # Click CLI interface
│   └── analyzers/
│       ├── repo_analyzer.py     # Viability scoring
│       ├── claude_detector.py   # .claude/ parsing
│       ├── pattern_miner.py     # Pattern extraction
│       └── cost_calculator.py   # Cost analysis
├── tests/
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── e2e/                     # End-to-end tests
├── deployment/
│   ├── azure_function/          # Azure Function config
│   └── github_actions/          # GitHub Actions workflow
├── pyproject.toml               # Poetry configuration
├── .env.example                 # Environment template
└── README.md                    # This file
```

### Running Tests

```bash
# Unit tests
poetry run pytest tests/unit -v

# Integration tests (requires Azure authentication)
poetry run pytest tests/integration -v

# Full test suite with coverage
poetry run pytest --cov=src --cov-report=html
```

### Code Quality

```bash
# Format code
poetry run black src/

# Lint code
poetry run ruff src/

# Type checking
poetry run mypy src/
```

## 🚢 Deployment

### Local CLI (Current)

Already configured for local execution via Poetry:

```bash
poetry run brookside-analyze scan --full
```

### Azure Function (Scheduled)

**Setup:**

```bash
# Create Function App
az functionapp create \
  --resource-group rg-brookside-prod \
  --name func-repo-analyzer \
  --storage-account stbrooksideanalyzer \
  --runtime python \
  --runtime-version 3.11 \
  --functions-version 4

# Configure managed identity
az functionapp identity assign --name func-repo-analyzer
PRINCIPAL_ID=$(az functionapp identity show --name func-repo-analyzer --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy \
  --name kv-brookside-secrets \
  --object-id $PRINCIPAL_ID \
  --secret-permissions get list

# Deploy
func azure functionapp publish func-repo-analyzer
```

**Schedule:** Weekly Sunday at midnight UTC

### GitHub Actions (Event-Triggered)

Workflow in `.github/workflows/repository-analysis.yml`

**Triggers:**
- Weekly schedule (Sunday 00:00 UTC)
- Manual dispatch

## 💰 Costs

**Azure Infrastructure:**
- Azure Functions (Consumption): $5/month
- Azure Storage: $2/month
- **Total:** $7/month

**Existing Services (no additional cost):**
- Azure Key Vault (existing)
- GitHub Enterprise (existing)
- Notion API (existing)

## 📚 Related Resources

- **Origin Idea:** [Notion Entry](https://www.notion.so/29386779099a816f8653e30ecb72abdd)
- **Example Build:** [Notion Entry](https://www.notion.so/29386779099a815f8b3bdc5c5cfb6f68)
- **GitHub:** github.com/brookside-bi/repo-analyzer (to be created)
- **Azure Function:** func-repo-analyzer.azurewebsites.net (to be deployed)

## 🤝 Contributing

This is an internal Brookside BI tool. For questions or enhancements:

- **Lead:** Alec Fielding (alec@brooksidebi.com)
- **Infrastructure Support:** Markus Ahling (markus@brooksidebi.com)

## 📄 License

Internal Brookside BI tool - Proprietary

## 🎯 Roadmap

- [ ] Complete Notion MCP integration for automated syncing
- [ ] Azure Function deployment for weekly automated scans
- [ ] GitHub Actions workflow for event-triggered analysis
- [ ] Enhanced dependency cost database
- [ ] Machine learning for pattern detection
- [ ] Integration with Azure DevOps for CI/CD metrics
- [ ] Real-time cost alerts and budget tracking

---

**Brookside BI Innovation Nexus** - Establish comprehensive repository visibility to streamline portfolio management and drive measurable outcomes through structured analysis approaches.
