# Contributing to Brookside BI Innovation Nexus

**Welcome!** Thank you for contributing to Innovation Nexus - together we streamline innovation workflows and drive measurable outcomes through structured collaboration.

This guide establishes clear contribution standards to maintain code quality, documentation excellence, and Brookside BI brand consistency across all contributions.

**Best for**: Contributors seeking to enhance Innovation Nexus with new features, documentation improvements, bug fixes, or architectural patterns.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Documentation Guidelines](#documentation-guidelines)
- [Testing Requirements](#testing-requirements)

---

## Code of Conduct

All contributors must uphold professional, respectful collaboration:

- **Professional Approach**: Maintain Brookside BI's consultative, solution-focused tone
- **Constructive Feedback**: Provide actionable, specific suggestions in code reviews
- **Knowledge Sharing**: Document learnings and archive reusable patterns
- **Brand Consistency**: Apply Brookside BI brand voice to all communications

---

## Getting Started

### Prerequisites

1. **Complete Quick Start**: Follow [QUICKSTART.md](QUICKSTART.md) to establish working environment
2. **Read Documentation**: Review [CLAUDE.md](CLAUDE.md) for system architecture
3. **Install Repository Hooks**: Enable quality gates and safety controls:
   ```bash
   # Install git hooks
   git config core.hooksPath .githooks

   # Make hooks executable (macOS/Linux)
   chmod +x .githooks/*
   ```

### Fork and Clone

```bash
# Fork repository via GitHub UI
# Clone your fork
git clone https://github.com/YOUR-USERNAME/notion.git
cd notion

# Add upstream remote
git remote add upstream https://github.com/brookside-bi/notion.git

# Verify remotes
git remote -v
```

### Install Dependencies

```bash
# Python dependencies (if applicable)
poetry install

# Node.js dependencies (if applicable)
npm install

# Verify environment
.\scripts\Set-MCPEnvironment.ps1
```

---

## Development Workflow

### 1. Create Feature Branch

```bash
# Sync with upstream
git checkout main
git pull upstream main

# Create feature branch (use conventional naming)
git checkout -b feature/add-cost-optimization-agent
# OR
git checkout -b fix/notion-search-timeout
# OR
git checkout -b docs/update-api-reference
```

**Branch Naming Conventions**:
- `feature/[description]` - New features or enhancements
- `fix/[description]` - Bug fixes
- `docs/[description]` - Documentation updates
- `refactor/[description]` - Code refactoring
- `test/[description]` - Test additions or improvements
- `chore/[description]` - Build, configuration, or tooling changes

### 2. Make Changes

- Follow code standards (see below)
- Write clear, descriptive commit messages
- Test changes thoroughly
- Update documentation as needed

### 3. Commit Changes

```bash
# Stage changes
git add .

# Commit with conventional format (see below)
git commit -m "feat: Add cost optimization agent for Azure resource analysis"

# Pre-commit hooks will run automatically:
# - Code formatting (if configured)
# - Linting checks
# - Commit message validation
```

### 4. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/add-cost-optimization-agent

# Create pull request via GitHub UI
# Use PR template (see Pull Request Process section)
```

---

## Code Standards

### General Principles

1. **Explicit Over Implicit**: No ambiguity - code should be executable by AI agents
2. **Idempotent Operations**: Steps should be safely repeatable
3. **Error Handling**: Include comprehensive error handling and recovery
4. **Documentation**: Comment business value first, technical implementation second
5. **Security First**: Never hardcode credentials, always reference Key Vault

### Python Code Standards

```python
# ✓ Correct: Business value comment, explicit types, error handling
def calculate_monthly_cost(software_entries: list[dict]) -> Decimal:
    """
    Calculate total monthly software spend to drive cost optimization
    through transparent expense tracking across Innovation Nexus.

    Args:
        software_entries: List of Software Tracker database entries

    Returns:
        Total monthly cost as Decimal for financial precision

    Raises:
        ValueError: If cost data is invalid or missing
    """
    try:
        total = Decimal('0.00')
        for entry in software_entries:
            cost = Decimal(str(entry.get('cost', 0)))
            licenses = int(entry.get('license_count', 1))
            total += cost * licenses
        return total
    except (ValueError, TypeError) as e:
        raise ValueError(f"Invalid cost data: {e}")

# ✗ Incorrect: No docstring, no error handling, ambiguous types
def calc_cost(entries):
    total = 0
    for e in entries:
        total += e['cost'] * e['licenses']
    return total
```

### TypeScript/JavaScript Standards

```typescript
// ✓ Correct: Explicit interfaces, comprehensive error handling
interface BuildMetrics {
  viabilityScore: number;  // 0-100
  reusabilityRating: 'Highly Reusable' | 'Partially Reusable' | 'One-Off';
  testCoverage: number;  // Percentage
}

/**
 * Calculate build viability to assess production readiness and
 * reusability potential for knowledge sharing across teams.
 */
async function calculateBuildViability(repoUrl: string): Promise<BuildMetrics> {
  try {
    const repo = await fetchRepository(repoUrl);

    if (!repo) {
      throw new Error(`Repository not found: ${repoUrl}`);
    }

    return {
      viabilityScore: calculateScore(repo),
      reusabilityRating: assessReusability(repo),
      testCoverage: await getTestCoverage(repo)
    };
  } catch (error) {
    console.error('Build viability calculation failed:', error);
    throw error;
  }
}
```

### Markdown Documentation Standards

- Use clear, hierarchical headers (H1 → H2 → H3, no skips)
- Lead with business value before technical details
- Include "Best for:" context qualifiers
- Provide executable code examples (no placeholders)
- Add verification steps for procedures
- Follow [Markdown Expert Agent standards](.claude/agents/markdown-expert.md)

---

## Commit Message Format

### Conventional Commits

All commits must follow [Conventional Commits](https://www.conventionalcommits.org/) format aligned with Brookside BI brand guidelines:

```
<type>: <description> [optional scope]

[optional body]

[optional footer]
```

### Commit Types

- `feat:` - New feature that adds value (user-facing or internal)
- `fix:` - Bug fix that resolves an issue
- `docs:` - Documentation changes only
- `style:` - Code formatting, whitespace (no functional change)
- `refactor:` - Code restructuring (no functional change)
- `test:` - Add or update tests
- `chore:` - Build, dependencies, configuration changes

### Examples

**Feature (with Brookside BI brand voice)**:
```
feat: Establish cost optimization agent to streamline Azure spending analysis

Add @cost-optimizer agent that analyzes Azure resource utilization
and provides actionable recommendations to reduce monthly spend
by 15-20% through rightsizing and consolidation strategies.

Best for: Organizations managing multiple Azure subscriptions
requiring continuous cost optimization across distributed teams.
```

**Bug Fix**:
```
fix: Resolve Notion search timeout for large workspaces

Implement exponential backoff retry and reduce default query
scope to data source level, reducing search latency from 30s
to under 3s for 1000+ page workspaces.
```

**Documentation**:
```
docs: Add API reference for Playwright MCP server operations

Comprehensive guide covering browser automation, element
interaction, screenshot capture, and testing workflows to
support QA teams validating Example Builds.
```

### CoAuthored By Requirement

All commits must include Claude Code attribution:

```
feat: Add real-time cost dashboard with Azure integration

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

**Automated by commit-msg hook**: The hook adds this attribution automatically if missing.

---

## Pull Request Process

### PR Template

Use this template for all pull requests:

```markdown
## Summary
[1-3 bullet points describing changes and business value]

## Changes Made
- [ ] New feature: [Description]
- [ ] Bug fix: [Description]
- [ ] Documentation: [Description]
- [ ] Tests: [Description]

## Testing
- [ ] Unit tests pass: `npm test` or `pytest`
- [ ] Integration tests pass (if applicable)
- [ ] Manual testing completed
- [ ] Documentation builds without errors

## Impact
- **Databases Affected**: [List Notion databases if modified]
- **Breaking Changes**: [Yes/No - describe if yes]
- **Dependencies**: [New dependencies added]

## Screenshots
[If UI changes, include before/after screenshots]

## Checklist
- [ ] Code follows style guidelines
- [ ] Commits follow conventional format
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Reviewed own changes
- [ ] No secrets/credentials in code
- [ ] Brookside BI brand voice applied

## Related Issues
Closes #[issue-number]

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Review Process

1. **Automated Checks**: GitHub Actions run tests and linting
2. **Code Review**: At least one reviewer required
3. **Documentation Review**: Ensure documentation complete
4. **Approval**: Maintainer approval required before merge
5. **Merge**: Squash and merge preferred for clean history

### Addressing Feedback

```bash
# Make requested changes
git add .
git commit -m "refactor: Address PR feedback - improve error handling"

# Push updates
git push origin feature/branch-name

# PR updates automatically
```

---

## Documentation Guidelines

### Types of Documentation

1. **API References** (`docs/api/`) - Comprehensive operation guides
2. **Guides** (`docs/guides/`) - How-to articles and tutorials
3. **Patterns** (`.claude/docs/patterns/`) - Architectural patterns
4. **Agent Documentation** (`.claude/agents/`) - Agent specifications
5. **Command Documentation** (`.claude/commands/`) - Slash command specs

### Documentation Standards

**Structure**:
- Clear, descriptive title
- Author and date metadata
- Table of contents for long documents
- "Best for:" context qualifier
- Executable examples
- Troubleshooting section
- Related documentation links

**Content**:
- Lead with business value/outcome
- Explicit, step-by-step procedures
- No ambiguity - executable by AI agents
- Include verification steps
- Provide error handling guidance
- Use Brookside BI brand voice

**Examples Must Be**:
- Complete and runnable
- Use realistic data (no "foo"/"bar")
- Include expected output
- Show error handling
- Demonstrate best practices

---

## Testing Requirements

### Required Tests

- **Unit Tests**: For all new functions/methods
- **Integration Tests**: For MCP server interactions
- **E2E Tests**: For complete workflows (optional but recommended)

### Running Tests

```bash
# Python tests
poetry run pytest

# JavaScript/TypeScript tests
npm test

# Specific test file
pytest tests/test_cost_analyzer.py

# With coverage
pytest --cov=src --cov-report=html
```

### Test Standards

```python
# ✓ Correct: Descriptive name, clear arrange-act-assert, edge cases
def test_calculate_monthly_cost_with_multiple_licenses():
    """Verify monthly cost calculation handles license multiplier correctly."""
    # Arrange
    software_entries = [
        {"cost": Decimal("50.00"), "license_count": 5},
        {"cost": Decimal("100.00"), "license_count": 2}
    ]

    # Act
    total = calculate_monthly_cost(software_entries)

    # Assert
    assert total == Decimal("450.00")  # 50*5 + 100*2

def test_calculate_monthly_cost_handles_missing_data():
    """Verify graceful handling when cost data is invalid."""
    # Arrange
    invalid_entries = [{"cost": "invalid"}]

    # Act & Assert
    with pytest.raises(ValueError, match="Invalid cost data"):
        calculate_monthly_cost(invalid_entries)
```

---

## Security Best Practices

### Credentials Management

**✓ Correct**:
```typescript
// Retrieve from Key Vault
const apiKey = await getKeyVaultSecret('kv-brookside-secrets', 'api-key-name');

// Reference environment variable
const githubPAT = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
```

**✗ Incorrect**:
```typescript
// NEVER hardcode credentials
const apiKey = 'abc123def456';
const githubPAT = 'ghp_hardcoded_token';
```

### Pre-Commit Checks

Repository hooks scan for:
- Hardcoded API keys, tokens, passwords
- AWS access keys
- Azure connection strings
- Private keys

**If hook fails**:
1. Remove credential from code
2. Store in Azure Key Vault
3. Reference via environment variable
4. Update documentation

---

## Code Review Checklist

**For Reviewers**:

- [ ] Code follows style guidelines
- [ ] Business value clearly documented
- [ ] Error handling comprehensive
- [ ] No hardcoded credentials
- [ ] Tests included and passing
- [ ] Documentation updated
- [ ] Brookside BI brand voice consistent
- [ ] Breaking changes documented
- [ ] Performance considerations addressed
- [ ] Security implications reviewed

---

## Getting Help

**Resources**:
- [CLAUDE.md](CLAUDE.md) - Complete system documentation
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

**Specialist Agents**:
- `@markdown-expert` - Documentation review
- `@architect-supreme` - Architecture decisions
- `@compliance-orchestrator` - Security and compliance

**Contact**:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047
- **Issues**: [github.com/brookside-bi/notion/issues](https://github.com/brookside-bi/notion/issues)

---

## License

By contributing to Innovation Nexus, you agree that your contributions will be licensed under the same terms as the project.

---

**Best for**: Contributors requiring clear standards, automated quality gates, and structured workflows that maintain Brookside BI brand consistency while accelerating innovation delivery.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
