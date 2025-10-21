---
description: Analyze a single GitHub repository with comprehensive viability assessment and optional Notion sync
allowed-tools: Task(@repo-analyzer:*)
argument-hint: <repo-name> [--sync] [--deep]
model: claude-sonnet-4-5-20250929
---

## Context

Perform deep analysis on a specific repository to assess viability, detect Claude Code integration, calculate costs, and optionally create/update Notion Example Build entry.

## Workflow

Invoke `@repo-analyzer` agent with repository name from `$ARGUMENTS`:

### 1. Repository Validation

- Extract repository name from `$ARGUMENTS`
- Verify repository exists in `brookside-bi` organization
- Check access permissions

### 2. Deep Analysis

**Metadata Collection:**
- Primary language and language distribution
- Dependency extraction (package.json, pyproject.toml, requirements.txt, etc.)
- Commit history (last 90 days)
- GitHub statistics (stars, forks, open issues)
- Repository size and activity

**Viability Scoring:**
```
Test Coverage (0-30):
  - Detect test directories (tests/, test/, __tests__/)
  - Estimate coverage from test file count
  - Award points based on coverage level

Activity (0-20):
  - Count commits in last 30 days (20 pts)
  - Count commits in last 90 days (10 pts)
  - No recent activity (0 pts)

Documentation (0-25):
  - README.md exists (15 pts)
  - Additional docs + active repo (25 pts)
  - No README (0 pts)

Dependency Health (0-25):
  - 0-10 dependencies: 25 pts
  - 11-30 dependencies: 15 pts
  - 31+ dependencies: 5 pts

Total: 0-100 points
Rating: HIGH (75-100) | MEDIUM (50-74) | LOW (0-49)
```

**Reusability Assessment:**
- Highly Reusable: Viability ≥75, has tests, has docs, active, not fork
- Partially Reusable: Viability ≥50, has tests OR docs
- One-Off: All other cases

**Claude Code Detection:**
- Check `.claude/` directory existence
- Count agents in `.claude/agents/`
- Count commands in `.claude/commands/`
- Parse `.claude.json` for MCP servers
- Check for `CLAUDE.md` project memory
- Calculate maturity score and level

**Cost Calculation:**
- Extract dependencies from manifest files
- Query Software & Cost Tracker for each dependency
- Sum monthly costs
- Identify Microsoft vs. third-party services

### 3. Notion Synchronization (if `--sync` flag)

**Search Existing Entry:**
- Query Example Builds database for repository name
- If found: Update existing entry
- If not found: Create new entry

**Example Build Properties:**
```
Name: Repository name
URL: GitHub repository URL
Description: Repository description
Viability: HIGH | MEDIUM | LOW
Reusability: HIGHLY_REUSABLE | PARTIALLY_REUSABLE | ONE_OFF
Claude Maturity: EXPERT | ADVANCED | INTERMEDIATE | BASIC | NONE
Status: Active (if pushed within 90 days) | Not Active
Build Type: Reference Implementation
Primary Language: Top language
Monthly Cost: (rollup from Software Tracker)
Stars: GitHub star count
Forks: GitHub fork count
Open Issues: Count
Last Updated: ISO date
```

**Software Tracker Linking:**
- For each dependency:
  - Search Software Tracker by name
  - Create new entry if not found
  - Link Software → Build relation
- Verify cost rollup calculation

### 4. Display Comprehensive Report

Show:
- Repository overview
- Viability score breakdown
- Reusability assessment
- Claude integration maturity
- Cost breakdown by category
- GitHub statistics
- Notion sync status (if enabled)

## Parameters

- `<repo-name>`: Repository name (without org prefix)
- `--sync`: Sync results to Notion Example Builds
- `--deep`: Enable deep code analysis (slower but comprehensive)
- `--output <file>`: Save JSON results to file

## Examples

```bash
# Basic analysis
/repo:analyze brookside-cost-tracker

# Deep analysis with Notion sync
/repo:analyze repo-analyzer --deep --sync

# Save results to file
/repo:analyze power-bi-governance --output analysis.json
```

## Expected Output

```
📦 Repository: brookside-bi/repo-analyzer
🔗 URL: https://github.com/brookside-bi/repo-analyzer

📊 Viability Analysis:
   Total Score: 85/100 (HIGH)
   ├─ Test Coverage: 28/30 (93% estimated)
   ├─ Activity: 20/20 (15 commits in last 30 days)
   ├─ Documentation: 25/25 (Comprehensive README + docs)
   └─ Dependencies: 12/25 (42 dependencies)

🔄 Reusability: HIGHLY_REUSABLE
   ✓ High viability score
   ✓ Has comprehensive tests
   ✓ Well documented
   ✓ Active development
   ✓ Not a fork

🤖 Claude Code Integration:
   Maturity Level: EXPERT (95/100)
   ├─ Agents: 4 (repo-analyzer, notion-sync, pattern-mining, cost-optimization)
   ├─ Commands: 10 (/repo:*, /notion:*)
   ├─ MCP Servers: 3 (github, notion, azure)
   └─ Project Memory: Yes (CLAUDE.md)

💰 Cost Analysis:
   Total Monthly Cost: $67.00

   Breakdown by Category:
   ├─ Infrastructure: $5.00 (Azure Functions)
   ├─ AI/ML: $50.00 (Azure OpenAI)
   └─ Development: $12.00 (GitHub Actions)

   Microsoft Services: $67.00 (100%)
   Third-Party Services: $0.00 (0%)

📈 GitHub Statistics:
   ⭐ Stars: 24
   🔱 Forks: 5
   📝 Open Issues: 3
   📅 Last Updated: 2 days ago
   📊 Primary Language: Python (78%)

   Language Distribution:
   ├─ Python: 78%
   ├─ Markdown: 15%
   └─ YAML: 7%

💾 Notion Sync:
   ✓ Updated Example Build entry
   ✓ Linked 42 dependencies to Software Tracker
   ✓ Cost rollup verified: $67.00/month

   Entry URL: https://www.notion.so/[build-id]

✅ Analysis complete
```

## Related Commands

- `/repo:scan-org` - Scan all organization repositories
- `/repo:detect-claude` - Focus on Claude integration maturity
- `/repo:calculate-costs` - Cost analysis across portfolio
- `/repo:extract-patterns` - Find reusable patterns

## Verification Steps

After execution:

```bash
# If --sync enabled:
# 1. Open Notion Example Builds database
# 2. Search for repository name
# 3. Verify all properties populated correctly
# 4. Check Software Tracker relations exist
# 5. Verify cost rollup displays

# If --output enabled:
# 1. Check file exists at specified path
# 2. Verify JSON structure is valid
# 3. Confirm all metrics included
```

## Troubleshooting

**Repository Not Found:**
```
Error: Repository "repo-name" not found in organization "brookside-bi"
Solution: Verify repository name and organization access
```

**Missing Dependencies:**
```
Warning: No package manifest files found
Action: Repository will show 0 dependencies, cost = $0
```

**Notion Sync Failure:**
```
Error: Failed to create Example Build entry
Solution: Check database ID in configuration, verify API permissions
```

## Use Cases

**1. Pre-Integration Assessment:**
```
/repo:analyze third-party-library
# Evaluate before integrating into projects
```

**2. Maintenance Prioritization:**
```
/repo:analyze legacy-system --deep
# Assess viability to decide: maintain, refactor, or sunset
```

**3. Knowledge Documentation:**
```
/repo:analyze successful-prototype --sync
# Archive working example to Example Builds
```

**4. Cost Tracking:**
```
/repo:analyze expensive-project --sync
# Track dependencies and link costs
```

## Best Practices

1. **Use --sync**: Always sync valuable repositories to Notion for tracking
2. **Review Costs**: Check dependency costs, suggest Microsoft alternatives
3. **Assess Reusability**: Promote highly reusable patterns across team
4. **Track Claude Maturity**: Encourage Agent/MCP adoption in new projects
5. **Monitor Viability**: Schedule quarterly re-analysis for active repos

---

**This command establishes detailed repository intelligence to drive informed decisions about maintenance, reuse, and investment priorities aligned with Brookside BI innovation goals.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
