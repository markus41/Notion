# Repository Scanning Guide

This guide establishes comprehensive scanning strategies for analyzing GitHub repository portfolios across multiple organizations and accounts.

**Best for**: Organizations requiring centralized visibility into repository health, viability scores, Claude Code integration maturity, and cost optimization opportunities across entire GitHub portfolios.

---

## Quick Start

### Scan Single Organization

```powershell
# Quick scan (fast, limited analysis)
.\run-scan.ps1 -Org "markus41"

# Full deep analysis
.\run-scan.ps1 -Org "markus41" -Full

# With Notion synchronization
.\run-scan.ps1 -Org "markus41" -Full -Sync
```

### Scan All Organizations

```powershell
# Quick scan of all accessible orgs
.\run-all-orgs-scan.ps1

# Full deep analysis across all orgs
.\run-all-orgs-scan.ps1 -Full

# Full analysis with Notion sync
.\run-all-orgs-scan.ps1 -Full -Sync

# Scan specific organizations only
.\run-all-orgs-scan.ps1 -OrgList "Advisor-OS,Brookside-Proving-Grounds" -Full
```

---

## Your GitHub Portfolio

**Discovered Organizations** (via `brookside-analyze organizations`):

| Organization | Type | Repositories | Description |
|--------------|------|--------------|-------------|
| **markus41** | Personal Account | 7 repos | Personal projects |
| **Advisor-OS** | Organization | TBD | Organization repos |
| **The-Chronicle-of-Realm-Works** | Organization | TBD | Organization repos |
| **Densbys-MVPs** | Organization | TBD | Organization repos |
| **Brookside-Proving-Grounds** | Organization | TBD | Organization repos |

**Total**: 5 accounts/organizations to analyze

---

## Analysis Types

### Quick Scan (Default)
- **Duration**: ~5-10 seconds per repository
- **Viability Scoring**: ✅ Full multi-dimensional scoring (0-100)
- **Reusability Assessment**: ✅ High/Partial/One-Off rating
- **Claude Detection**: ✅ CLAUDE.md, agents, commands, MCP servers
- **Cost Calculation**: ✅ Dependency cost estimation
- **Test Coverage**: ❌ Not analyzed (requires deep scan)
- **Code Quality Metrics**: ❌ Not analyzed (requires deep scan)
- **Best for**: Rapid portfolio overview, weekly monitoring

### Full Deep Analysis (`--full`)
- **Duration**: ~30-60 seconds per repository
- **All Quick Scan Features**: ✅
- **Test Coverage Analysis**: ✅ Line coverage percentage
- **Code Quality Metrics**: ✅ Complexity, maintainability
- **Dependency Audit**: ✅ Outdated packages, security vulnerabilities
- **Commit History Analysis**: ✅ Contributor patterns, velocity trends
- **Best for**: Monthly comprehensive reviews, pre-migration assessments

---

## Output Formats

### Console Summary Table

```
┏━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━━━━━━┓
┃ Repository                 ┃ Viability ┃ Reusability ┃ Cost/mo ┃ Language   ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━━━━━━┩
│ AdvisorOS                  │ ⚡ Medium │ ↔️           │  $0.00  │ TypeScript │
│ portfolio                  │ ⚡ Medium │ ↔️           │  $0.00  │ Python     │
│ Notion                     │ 🔻 Low    │ 🔒          │  $0.00  │ Python     │
└────────────────────────────┴───────────┴─────────────┴─────────┴────────────┘
```

**Legend**:
- **Viability**: 💎 High (75-100) | ⚡ Medium (50-74) | 🔻 Low (0-49)
- **Reusability**: ✨ Highly Reusable | ↔️ Partially Reusable | 🔒 One-Off

### Cost Summary

```
Total Monthly Cost: $X.XX
Total Annual Cost: $X.XX
Average per Repo: $X.XX
Repos with Costs: X/XX
```

---

## Notion Synchronization

When using `--Sync` flag, results are automatically synced to the **Brookside BI Innovation Nexus**:

### Synced Databases

1. **🛠️ Example Builds** (`a1cd1528-971d-4873-a176-5e93b93555f6`)
   - Repository URL and description
   - Viability score and rating
   - Reusability assessment
   - Claude Code maturity level
   - GitHub stats (stars, forks, issues)
   - Status (Active if pushed within 90 days)

2. **💰 Software & Cost Tracker** (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`)
   - Dependencies extracted from package manifests
   - Cost estimates from database
   - Relations: Software → Build
   - Cost rollups calculated automatically

3. **📚 Knowledge Vault**
   - Reusable architectural patterns
   - Usage statistics
   - Cross-repository pattern library

### Prerequisites for Notion Sync

```powershell
# Add Notion API key to Azure Key Vault
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name notion-api-key `
  --value "ntn_XXXXXXXXXXXXXXXXXXXX"

# Verify secret stored
az keyvault secret show `
  --vault-name kv-brookside-secrets `
  --name notion-api-key `
  --query value -o tsv
```

---

## Viability Scoring Algorithm

```
Total Score (0-100) = Test Coverage + Activity + Documentation + Dependencies

Test Coverage (0-30 points):
  - 70%+ coverage: 30 points
  - Tests exist: 10+ points scaled by coverage
  - No tests: 0 points

Activity (0-20 points):
  - Commits last 30 days: 20 points
  - Commits last 90 days: 10 points
  - No recent commits: 0 points

Documentation (0-25 points):
  - README + docs + active: 25 points
  - README exists: 15 points
  - No README: 0 points

Dependency Health (0-25 points):
  - 0-10 dependencies: 25 points
  - 11-30 dependencies: 15 points
  - 31+ dependencies: 5 points

Ratings:
  - 💎 HIGH (75-100): Production-ready, well-maintained
  - ⚡ MEDIUM (50-74): Functional but needs work
  - 🔻 LOW (0-49): Reference only or abandoned
```

---

## Reusability Assessment

```
✨ Highly Reusable:
  ✓ Viability ≥ 75
  ✓ Has tests
  ✓ Has documentation
  ✓ Not a fork
  ✓ Active (pushed within 90 days)

↔️ Partially Reusable:
  ✓ Viability ≥ 50
  ✓ Has tests OR documentation

🔒 One-Off:
  All other cases
```

---

## Claude Code Integration Maturity

**Detection Levels**:
- **🌟 EXPERT (80-100)**: Comprehensive agents, commands, MCP servers, project memory
- **⭐ ADVANCED (60-79)**: Multiple agents/commands, some MCP servers
- **✦ INTERMEDIATE (30-59)**: Basic agents or commands
- **○ BASIC (10-29)**: Minimal .claude/ directory
- **∅ NONE (0-9)**: No meaningful integration

**Scoring Formula**:
```
Score = (agents × 10) + (commands × 5) + (mcp_servers × 10) + (has_claude_md × 15)
```

**Detected Files**:
- `.claude.json` - MCP configuration
- `CLAUDE.md` - Project instructions
- `.claude/agents/*.md` - Sub-agent definitions
- `.claude/commands/*.md` - Slash command workflows

---

## Automation Workflows

### Weekly Portfolio Monitoring

```powershell
# Add to Windows Task Scheduler (Sunday midnight)
$action = New-ScheduledTaskAction `
  -Execute 'PowerShell.exe' `
  -Argument '-ExecutionPolicy Bypass -File "C:\Users\MarkusAhling\Notion\brookside-repo-analyzer\run-all-orgs-scan.ps1" -Sync'

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 12:00AM

Register-ScheduledTask `
  -TaskName "Brookside Portfolio Analyzer" `
  -Action $action `
  -Trigger $trigger `
  -Description "Weekly GitHub repository portfolio analysis with Notion sync"
```

### Azure Function Deployment (Future)

**Scheduled Trigger**: Weekly Sunday midnight UTC
**Runtime**: Python 3.11
**Authentication**: Managed Identity
**Duration**: ~5-10 minutes for full portfolio
**Cost**: ~$5-7/month (Azure Functions Consumption)

---

## Troubleshooting

### Issue: "Organization not found"

**Cause**: PAT token lacks `read:org` scope or organization name misspelled

**Solution**:
```powershell
# List accessible organizations
poetry run brookside-analyze organizations

# Verify token scopes
gh auth status
```

### Issue: "Rate limit exceeded"

**Cause**: GitHub API rate limit (5,000 requests/hour with authentication)

**Solution**:
- Use `--quick` instead of `--full` for faster scanning
- Scan organizations sequentially with delays
- Wait 1 hour and retry

### Issue: "Notion sync failed"

**Cause**: Missing `notion-api-key` in Azure Key Vault

**Solution**:
```powershell
# Add Notion API key
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name notion-api-key `
  --value "ntn_your_key_here"
```

### Issue: "Azure authentication failed"

**Cause**: Not logged in to Azure CLI

**Solution**:
```powershell
# Login to Azure
az login

# Verify authentication
az account show
```

---

## Command Reference

### CLI Commands

```bash
# List all organizations
poetry run brookside-analyze organizations

# Scan single organization
poetry run brookside-analyze scan --org markus41 --full

# Scan all organizations (programmatic)
poetry run brookside-analyze scan --all-orgs --full --sync

# Analyze specific repository
poetry run brookside-analyze analyze repo-name --deep

# Extract cross-repo patterns
poetry run brookside-analyze patterns

# Calculate portfolio costs
poetry run brookside-analyze costs --detailed
```

### PowerShell Scripts

```powershell
# Single organization scan
.\run-scan.ps1 -Org "markus41" -Full -Sync

# All organizations scan
.\run-all-orgs-scan.ps1 -Full -Sync

# Specific organizations only
.\run-all-orgs-scan.ps1 -OrgList "Advisor-OS,Brookside-Proving-Grounds" -Full
```

---

## Best Practices

1. **Weekly Monitoring**: Run `.\run-all-orgs-scan.ps1` every Sunday to track portfolio evolution
2. **Full Analysis Monthly**: Use `-Full` flag once per month for comprehensive audit
3. **Notion Sync Always**: Enable `-Sync` to maintain centralized knowledge base
4. **Review Viability Trends**: Track repos moving between High/Medium/Low over time
5. **Optimize Costs**: Act on unused dependencies and consolidation opportunities
6. **Promote Claude Adoption**: Encourage teams to reach Expert maturity level
7. **Archive Low-Viability Repos**: Consider archiving repos with <25 viability score after 6 months of inactivity

---

**Brookside BI Innovation Nexus - Where Repositories Become Insights, and Insights Drive Measurable Outcomes**
