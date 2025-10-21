# Brookside BI Innovation Nexus - Workspace Guide

**Version**: 1.0.0
**Type**: Monorepo Workspace
**Purpose**: Centralized innovation management integrating Notion, GitHub, Azure, and Claude Code

---

## Workspace Structure

This repository is organized as a **monorepo** containing multiple projects and tools:

```
C:\Users\MarkusAhling\Notion\
├── 📁 .claude/                      Claude Code configuration
│   ├── agents/                      14 specialized sub-agents
│   ├── commands/                    5 slash command categories
│   └── settings.local.json          User-specific preferences
│
├── 📁 brookside-repo-analyzer/      Python CLI tool (independent project)
│   ├── pyproject.toml              Own dependencies & configuration
│   ├── src/                         Repository analysis engine
│   ├── tests/                       Unit & integration tests
│   └── README.md                    Project-specific docs
│
├── 📁 docs/                         Workspace documentation
│   ├── GITHUB_MCP_INTEGRATION.md   GitHub MCP setup guide
│   └── ...                          Additional documentation
│
├── 📁 scripts/                      PowerShell automation
│   ├── Get-KeyVaultSecret.ps1      Azure Key Vault access
│   ├── Set-MCPEnvironment.ps1      MCP environment setup
│   └── Test-AzureMCP.ps1           Azure MCP validation
│
├── 📄 pyproject.toml                Workspace-level config (this level)
├── 📄 CLAUDE.md                     Main project documentation
├── 📄 WORKSPACE.md                  This file
└── 📄 .gitignore                    Workspace-wide ignore rules
```

---

## Getting Started

### Prerequisites

- **Python 3.11+** installed
- **Poetry** package manager installed
- **PowerShell 7+** for scripts
- **Azure CLI** configured and logged in
- **Git** for version control

### Initial Setup

#### 1. Install Workspace Development Tools

```powershell
# From repository root
cd C:\Users\MarkusAhling\Notion
poetry install
```

This installs workspace-level tools:
- `pre-commit` - Git hook management
- `mdformat` - Markdown formatting
- `yamllint` - YAML validation

#### 2. Set Up Repository Analyzer

```powershell
# Navigate to analyzer project
cd brookside-repo-analyzer
poetry install

# Verify installation
poetry run brookside-analyze --help
```

#### 3. Configure Azure Environment

```powershell
# Set up MCP environment variables from Key Vault
cd ..
.\scripts\Set-MCPEnvironment.ps1
```

---

## Project Management

### Workspace-Level Operations

**Install/Update Development Tools:**
```powershell
cd C:\Users\MarkusAhling\Notion
poetry install
poetry update
```

**Format All Markdown Documentation:**
```powershell
poetry run mdformat *.md docs/*.md
```

**Validate YAML Files:**
```powershell
poetry run yamllint .claude/*.json
```

### Repository Analyzer Operations

**Run Full Organization Scan:**
```powershell
cd brookside-repo-analyzer
.\run-scan.ps1 -Full
```

**Analyze Single Repository:**
```powershell
poetry run brookside-analyze analyze <repo-name> --deep
```

**Extract Patterns:**
```powershell
poetry run brookside-analyze patterns
```

**Calculate Costs:**
```powershell
poetry run brookside-analyze costs
```

---

## Development Workflow

### Adding a New Python Project

1. Create project directory: `mkdir new-project`
2. Initialize with Poetry: `cd new-project && poetry init`
3. Add to workspace documentation
4. Update root `.gitignore` if needed

### Working Across Projects

**Pattern 1: Workspace Tools → Specific Project**
```powershell
# Format docs (workspace-level)
cd C:\Users\MarkusAhling\Notion
poetry run mdformat CLAUDE.md

# Run analyzer (project-level)
cd brookside-repo-analyzer
poetry run brookside-analyze scan
```

**Pattern 2: Independent Project Development**
```powershell
# Work entirely within subdirectory
cd C:\Users\MarkusAhling\Notion\brookside-repo-analyzer
poetry install
poetry run pytest
poetry run brookside-analyze --help
```

---

## Dependencies Management

### Workspace-Level Dependencies (Root `pyproject.toml`)

**Purpose**: Documentation and quality tools used across all projects

**Current Tools:**
- `pre-commit ^3.6.0` - Git hooks
- `mdformat ^0.7.17` - Markdown formatter
- `mdformat-gfm ^0.3.5` - GitHub-flavored markdown support
- `mdformat-frontmatter ^2.0.8` - YAML frontmatter support
- `yamllint ^1.33.0` - YAML linter

**Add New Workspace Tool:**
```powershell
cd C:\Users\MarkusAhling\Notion
poetry add --group dev <tool-name>
```

### Project-Level Dependencies (Subdirectory `pyproject.toml`)

Each subdirectory manages its own dependencies independently.

**Example - Adding to Analyzer:**
```powershell
cd brookside-repo-analyzer
poetry add <package-name>
poetry add --group dev <dev-package>
```

---

## Git Workflow

### Branching Strategy

- `main` - Production-ready code
- `feature/<description>` - New features
- `fix/<description>` - Bug fixes
- `docs/<description>` - Documentation updates

### Commit Guidelines

**Use Conventional Commits with Brookside BI branding:**

```bash
git commit -m "feat: Establish automated cost tracking across repositories

Streamline innovation portfolio management by integrating cost analysis
into repository scanning workflow. This solution is designed to drive
measurable outcomes through transparent spend visibility.

Best for: Organizations requiring financial visibility across development portfolios

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

**Commit Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `refactor:` Code refactoring
- `test:` Test additions
- `chore:` Maintenance

---

## Common Tasks

### Running the Repository Analyzer

**Quick Scan (Current User Repos):**
```powershell
cd brookside-repo-analyzer
.\run-scan.ps1
```

**Full Scan with Notion Sync:**
```powershell
.\run-scan.ps1 -Org "markus41" -Full -Sync
```

**Cost Analysis:**
```powershell
poetry run brookside-analyze costs
```

### Updating Documentation

**Format Markdown:**
```powershell
cd C:\Users\MarkusAhling\Notion
poetry run mdformat CLAUDE.md WORKSPACE.md
```

**Validate Changes:**
```powershell
poetry run yamllint .claude/settings.local.json
```

### Managing Secrets

**Retrieve from Key Vault:**
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"
```

**Set All MCP Environment Variables:**
```powershell
.\scripts\Set-MCPEnvironment.ps1
```

**Test Azure MCP Connection:**
```powershell
.\scripts\Test-AzureMCP.ps1
```

---

## Troubleshooting

### Poetry Issues

**Problem**: `poetry: command not found`
```powershell
# Install Poetry
(Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | python -

# Add to PATH
$env:PATH += ";C:\Users\MarkusAhling\AppData\Roaming\Python\Scripts"
```

**Problem**: Virtual environment conflicts
```powershell
# Clear Poetry cache
poetry cache clear pypi --all

# Remove existing venv
poetry env remove python
poetry install
```

### Azure Key Vault Issues

**Problem**: Authentication failures
```powershell
# Re-authenticate to Azure
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"
```

**Problem**: Secret not found
```powershell
# List available secrets
az keyvault secret list --vault-name kv-brookside-secrets
```

### Analyzer Issues

**Problem**: Unicode encoding errors on Windows
```powershell
# Use the wrapper script (sets UTF-8)
.\run-scan.ps1
```

**Problem**: GitHub API rate limiting
```powershell
# Check rate limit status
poetry run python -c "import httpx; resp = httpx.get('https://api.github.com/rate_limit', headers={'Authorization': 'token YOUR_TOKEN'}); print(resp.json())"
```

---

## Best Practices

### For This Workspace

1. **Always run workspace commands from root** (`C:\Users\MarkusAhling\Notion`)
2. **Run project commands from project directories** (`brookside-repo-analyzer/`)
3. **Use Poetry for all Python dependencies** (no pip install)
4. **Format markdown before committing** (workspace tool)
5. **Keep secrets in Azure Key Vault** (never commit)
6. **Follow Brookside BI brand voice** in all documentation
7. **Update CLAUDE.md when adding features**

### Development Guidelines

- **Test changes locally** before committing
- **Run analyzer on sample repos** before production use
- **Document new slash commands** in `.claude/commands/`
- **Add new agents** to `.claude/agents/` with proper documentation
- **Track costs transparently** in Notion Software Tracker
- **Preserve learnings** in Knowledge Vault after completion

---

## Related Documentation

- **[CLAUDE.md](./CLAUDE.md)** - Main project documentation and standards
- **[brookside-repo-analyzer/README.md](./brookside-repo-analyzer/README.md)** - Analyzer tool documentation
- **[docs/GITHUB_MCP_INTEGRATION.md](./docs/GITHUB_MCP_INTEGRATION.md)** - GitHub MCP setup
- **[SLASH_COMMANDS_SUMMARY.md](./SLASH_COMMANDS_SUMMARY.md)** - Available slash commands

---

## Support

**Team Contacts:**
- **Markus Ahling** - Engineering, Operations, AI, Infrastructure
- **Alec Fielding** - DevOps, Engineering, Security, Integrations
- **Brad Wright** - Sales, Business, Finance, Marketing
- **Stephan Densby** - Operations, Continuous Improvement, Research
- **Mitch Bisbee** - DevOps, Engineering, ML, Master Data

**General Inquiries**: Consultations@BrooksideBI.com
**Phone**: +1 209 487 2047

---

**Best for**: Organizations managing multiple innovation workflows requiring centralized governance while maintaining project independence through scalable monorepo architecture.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
