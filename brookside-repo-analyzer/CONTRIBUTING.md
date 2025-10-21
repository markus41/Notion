# Contributing to Brookside BI Repository Analyzer

Welcome! This guide establishes sustainable contribution practices that support scalable development while maintaining code quality and organizational alignment.

**Best for**: Teams requiring structured collaboration frameworks that drive measurable outcomes through consistent development practices.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Documentation Guidelines](#documentation-guidelines)
- [Pull Request Process](#pull-request-process)
- [Notion Integration](#notion-integration)
- [Security Best Practices](#security-best-practices)
- [Cost Considerations](#cost-considerations)

## Getting Started

### Prerequisites

**Required Software:**
- Python 3.11 or higher
- Poetry 1.7.0 or higher
- Azure CLI 2.50.0 or higher
- Git
- PowerShell 7.0+ (Windows) or Bash (Linux/macOS)

**Azure Access:**
- Access to Azure subscription `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`
- Key Vault access to `kv-brookside-secrets`
- Appropriate Azure RBAC roles

### Initial Setup

1. **Fork and Clone Repository:**
```bash
git clone https://github.com/brookside-bi/brookside-repo-analyzer.git
cd brookside-repo-analyzer
```

2. **Configure Azure Authentication:**
```powershell
# Login to Azure
az login

# Set active subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
```

3. **Configure Environment:**
```powershell
# Retrieve secrets and configure environment
.\scripts\Set-MCPEnvironment.ps1

# OR set up persistent environment variables
.\scripts\Set-MCPEnvironment.ps1 -Persistent
```

4. **Install Dependencies:**
```bash
# Install Poetry if not already installed
curl -sSL https://install.python-poetry.org | python3 -

# Install project dependencies
poetry install

# Install pre-commit hooks
poetry run pre-commit install
```

5. **Verify Installation:**
```bash
# Run tests
poetry run pytest tests/

# Check code quality
poetry run pre-commit run --all-files

# Test CLI
poetry run brookside-analyze --help
```

## Development Workflow

### Branch Strategy

**Main Branches:**
- `main` - Production-ready code, protected branch
- `develop` - Integration branch (if using GitFlow)

**Feature Branches:**
```bash
# Create feature branch
git checkout -b feature/add-viability-scoring

# Create bug fix branch
git checkout -b fix/auth-timeout-issue

# Create documentation branch
git checkout -b docs/update-architecture-guide
```

**Branch Naming Conventions:**
- `feature/[description]` - New features
- `fix/[description]` - Bug fixes
- `docs/[description]` - Documentation updates
- `refactor/[description]` - Code refactoring
- `test/[description]` - Test improvements

### Development Cycle

1. **Create Branch:**
```bash
git checkout -b feature/your-feature-name
```

2. **Make Changes:**
- Write code following [Coding Standards](#coding-standards)
- Add/update tests
- Update documentation
- Run pre-commit hooks: `pre-commit run --all-files`

3. **Test Changes:**
```bash
# Run unit tests
poetry run pytest tests/unit/ -v

# Run all tests with coverage
poetry run pytest --cov=src --cov-report=term-missing

# Type checking
poetry run mypy src/

# Linting
poetry run ruff check .

# Formatting
poetry run black .
```

4. **Commit Changes:**
```bash
# Use conventional commit format
git commit -m "feat: Add viability scoring algorithm for repository assessment

Implement multi-dimensional scoring system to evaluate repository health
based on test coverage, activity, documentation, and dependency management.

Best for: Organizations requiring objective metrics to prioritize maintenance efforts.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

5. **Push and Create PR:**
```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub following the [Pull Request Process](#pull-request-process).

## Coding Standards

### Brookside BI Brand Guidelines

All code and documentation must reflect Brookside BI's brand identity:

**Core Language Patterns:**
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Streamline workflows and improve visibility"
- "Drive measurable outcomes through structured approaches"

**Code Comments:**
```python
# ❌ Bad
# Initialize database connection
conn = Database()

# ✅ Good
# Establish scalable data access layer to support multi-team repository analysis
# Best for: Concurrent analysis workflows requiring connection pooling
conn = Database(pool_size=10, max_overflow=20)
```

**Function Docstrings:**
```python
def calculate_viability_score(repo: Repository) -> ViabilityScore:
    """
    Calculate repository viability score to drive maintenance prioritization.

    Establishes multi-dimensional assessment framework evaluating test coverage,
    activity patterns, documentation quality, and dependency health. This solution
    is designed for organizations scaling repository portfolios across teams.

    Args:
        repo: Repository object with metadata and statistics

    Returns:
        ViabilityScore with breakdown and overall rating

    Best for: Organizations requiring objective metrics to allocate engineering resources.

    Example:
        >>> score = calculate_viability_score(repo)
        >>> print(f"Viability: {score.rating.value}")
        HIGH
    """
```

### Python Style

**Follow PEP 8 with Brookside BI extensions:**
- Line length: 100 characters (Black default)
- Use type hints for all function signatures
- Docstrings required for all public functions/classes
- Prefer explicit over implicit
- Use Pydantic models for data validation

**Type Hints:**
```python
from typing import List, Dict, Optional
from pydantic import HttpUrl

def analyze_repository(
    repo_url: HttpUrl,
    deep_analysis: bool = True,
    excluded_paths: Optional[List[str]] = None,
) -> RepoAnalysis:
    """Analyze repository with comprehensive metrics."""
    pass
```

### Code Organization

**File Structure:**
```
src/
├── __init__.py
├── models.py          # Pydantic data models
├── config.py          # Configuration management
├── auth.py            # Azure Key Vault authentication
├── cli.py             # CLI interface
├── github_mcp_client.py  # GitHub operations
├── notion_client.py   # Notion operations
└── analyzers/
    ├── repo_analyzer.py
    ├── claude_detector.py
    ├── pattern_miner.py
    └── cost_calculator.py
```

**Import Order:**
1. Standard library
2. Third-party packages
3. Local application imports

```python
import os
from pathlib import Path
from typing import List, Optional

import httpx
from pydantic import BaseModel, HttpUrl
from azure.identity import DefaultAzureCredential

from src.config import get_settings
from src.models import Repository, RepoAnalysis
```

## Testing Requirements

### Test Coverage Standards

- **Minimum coverage**: 80% overall
- **Critical paths**: 100% coverage (auth, analysis algorithms, cost calculations)
- **New features**: Must include comprehensive tests

### Test Types

**Unit Tests** (`tests/unit/`)
- Test individual components in isolation
- Mock all external dependencies
- Fast execution (< 1 second per test)

```python
import pytest
from unittest.mock import patch, Mock
from src.auth import CredentialManager

def test_get_github_token_success(mock_settings, mock_azure_keyvault_secret):
    """Test successful GitHub token retrieval from Key Vault"""
    with patch("src.auth.SecretClient") as mock_client:
        mock_client.return_value.get_secret.return_value = mock_azure_keyvault_secret

        cred_manager = CredentialManager(mock_settings)
        token = cred_manager.get_github_token()

        assert token == "secret_value_12345"
```

**Integration Tests** (`tests/integration/`)
- Test component interactions
- Use real Azure/GitHub connections
- Run on main branch only

**E2E Tests** (`tests/e2e/`)
- Test complete user workflows
- Test CLI commands end-to-end
- Validate Notion synchronization

### Running Tests

```bash
# Run all tests
poetry run pytest

# Run specific test category
poetry run pytest tests/unit/
poetry run pytest tests/integration/

# Run with coverage
poetry run pytest --cov=src --cov-report=html

# Run tests matching pattern
poetry run pytest -k "test_viability"

# Run with verbose output
poetry run pytest -v

# Run specific test file
poetry run pytest tests/unit/test_models.py
```

## Documentation Guidelines

### Required Documentation

**Code-Level:**
- Docstrings for all public functions/classes
- Type hints for all function signatures
- Inline comments for complex logic

**File-Level:**
- README.md for project overview
- ARCHITECTURE.md for system design
- API.md for API documentation (if applicable)

**Change-Level:**
- CHANGELOG.md entries for all releases
- Migration guides for breaking changes

### Documentation Standards

**README Structure:**
```markdown
# Component Name

One-paragraph summary with business value.

**Best for**: Organizations [use case]

## Features

- Feature 1 with outcome
- Feature 2 with outcome

## Installation

[Step-by-step setup]

## Usage

[Common workflows with examples]

## Configuration

[Environment variables and settings]
```

**API Documentation:**
```python
class RepositoryAnalyzer:
    """
    Multi-dimensional repository analysis engine.

    Establishes comprehensive assessment framework to drive informed
    decisions about maintenance, investment, and knowledge extraction.

    Best for: Organizations managing large repository portfolios requiring
    systematic evaluation and prioritization strategies.

    Attributes:
        github_client: GitHub MCP client for data retrieval

    Example:
        >>> async with GitHubMCPClient(settings, creds) as client:
        ...     analyzer = RepositoryAnalyzer(client)
        ...     analysis = await analyzer.analyze_repository(repo)
        ...     print(f"Viability: {analysis.viability.rating.value}")
    """
```

## Pull Request Process

### Before Creating PR

1. ✅ All tests pass locally
2. ✅ Code coverage meets requirements
3. ✅ Pre-commit hooks pass
4. ✅ Documentation updated
5. ✅ CHANGELOG.md entry added (if applicable)
6. ✅ Self-review completed

### PR Requirements

**Title Format:**
```
<type>: <description>

Types: feat, fix, docs, refactor, test, chore
```

**Description Must Include:**
- Clear summary of changes
- Related issue number
- Type of change (bug fix, feature, etc.)
- Test strategy and results
- Code quality checklist completion
- Security review checklist
- Cost impact analysis

**Review Process:**
1. Automated checks run (GitHub Actions)
2. Code review by team member
3. Security scan passes
4. Documentation review
5. Approval required before merge

### Merging

- Squash and merge to main
- Delete branch after merge
- Ensure commit message follows Brookside BI brand guidelines

## Notion Integration

### When to Create Notion Entries

**Ideas Registry:**
- New feature proposals
- Enhancement suggestions
- Innovation concepts

**Research Hub:**
- Feasibility investigations
- Technical spikes
- Proof-of-concept validations

**Example Builds:**
- All new features (once implemented)
- Significant refactorings
- Reusable components

**Software & Cost Tracker:**
- New dependencies added
- Azure services utilized
- Third-party tools integrated

### Notion Entry Requirements

**All entries must include:**
- Champion/Owner assignment
- Viability assessment
- Cost estimation
- Relations to relevant databases
- Status tracking

**Example:**
```bash
# After implementing a feature, create Notion build entry
/innovation:create-build "Repository Viability Scoring" reference-implementation

# Link to Software Tracker
Link Azure Key Vault, GitHub MCP, Notion MCP

# Update cost estimate
Total monthly cost: $15 (Azure Functions + GitHub Actions)
```

## Security Best Practices

### Credential Management

**✅ DO:**
- Store all secrets in Azure Key Vault
- Use Managed Identity for Azure resources
- Reference secrets via environment variables
- Use `scripts/Get-KeyVaultSecret.ps1` for local development

**❌ DON'T:**
- Hardcode credentials in code
- Commit .env files with secrets
- Log sensitive data
- Share credentials in plain text

### Code Security

```bash
# Run security scans before commit
poetry run bandit -r src/
poetry run detect-secrets scan

# Pre-commit hooks will catch common issues
pre-commit run --all-files
```

### Azure Security

- Use Managed Identity whenever possible
- Rotate secrets regularly
- Follow least-privilege access principles
- Enable Application Insights for monitoring

## Cost Considerations

### Before Adding Dependencies

1. Check if Microsoft-first alternative exists
2. Estimate monthly cost impact
3. Document in Software & Cost Tracker
4. Update build cost estimates

### Azure Resource Usage

**Track costs for:**
- Azure Functions (Consumption Plan)
- Application Insights
- Storage Accounts
- Key Vault operations
- GitHub Actions minutes

**Optimize for cost:**
- Use appropriate service tiers
- Monitor usage patterns
- Implement caching where applicable
- Scale based on actual demand

### Cost Transparency

All new features must include:
- Estimated monthly cost
- Cost breakdown by service
- Link to Software & Cost Tracker entry
- Cost optimization opportunities

## Questions and Support

**Technical Questions:**
- Open an issue with `question` label
- Check existing documentation
- Review ARCHITECTURE.md

**Security Concerns:**
- Email: security@brooksidebi.com
- Create private security advisory on GitHub

**General Inquiries:**
- Consultations@BrooksideBI.com
- +1 209 487 2047

---

**Thank you for contributing to Brookside BI Repository Analyzer!**

This solution is designed to streamline innovation management workflows and drive measurable outcomes through sustainable development practices.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
