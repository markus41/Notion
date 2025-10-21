---
description: Scan all GitHub organization repositories with comprehensive analysis and Notion synchronization
allowed-tools: Task(@repo-analyzer:*)
argument-hint: [--sync] [--deep] [--exclude repo1,repo2]
model: claude-sonnet-4-5-20250929
---

## Context

Establish comprehensive visibility into the GitHub organization repository portfolio through automated analysis, viability scoring, Claude integration detection, pattern mining, and seamless Notion synchronization.

## Workflow

Invoke `@repo-analyzer` agent to execute this workflow:

### 1. Initialize Analysis Environment

```bash
# Navigate to repo-analyzer directory
cd brookside-repo-analyzer/

# Verify Azure authentication
az account show

# Load environment configuration
# Credentials retrieved from Azure Key Vault:
#   - github-personal-access-token
#   - notion-api-key
```

### 2. Repository Discovery

- Query GitHub organization: `brookside-bi`
- Filter out archived repositories (unless specified)
- Exclude repositories from `$ARGUMENTS --exclude` flag
- Display total repository count

### 3. Concurrent Analysis (Max 10 Parallel)

For each repository:
- **Metadata**: Fetch languages, dependencies, commit history
- **Viability Score**: Calculate 0-100 score with breakdown
- **Reusability**: Assess HIGHLY_REUSABLE | PARTIALLY_REUSABLE | ONE_OFF
- **Claude Integration**: Detect agents, commands, MCP servers, maturity level
- **Cost Calculation**: Sum dependency monthly costs from Software Tracker
- **Microsoft Services**: Identify Azure/M365 integrations

### 4. Pattern Extraction

- Group repositories by technology stack
- Identify shared dependencies (3+ repositories)
- Detect architectural patterns (Serverless, RESTful, Microservices)
- Calculate pattern reusability scores
- Generate usage statistics

### 5. Notion Synchronization (if `--sync` flag)

**Example Builds Database:**
- Search for existing build by repository name
- Create or update entry with:
  - Repository metadata (name, URL, description)
  - Viability score and rating
  - Reusability assessment
  - Claude maturity level
  - GitHub statistics (stars, forks, issues)
  - Primary language
  - Status (Active if pushed within 90 days)

**Software & Cost Tracker:**
- For each repository dependency:
  - Search Software Tracker for existing entry
  - Create new entry if not found (with cost from database)
  - Link Software → Build relation
  - Verify cost rollup calculation

**Knowledge Vault** (for patterns):
- Create pattern library entries
- Document reusability scores
- Link to example repositories

### 6. Generate Summary Report

Display:
- Total repositories analyzed
- Viability distribution (High/Medium/Low percentages)
- Reusability distribution
- Total monthly cost and average per repo
- Claude maturity distribution
- Pattern count and top patterns
- Notion sync status (entries created/updated)
- Execution time

## Parameters

- `--sync`: Enable Notion synchronization (default: false)
- `--deep`: Enable deep code analysis (slower, more thorough)
- `--exclude`: Comma-separated list of repository names to exclude
- `--include-archived`: Include archived repositories in scan
- `--no-cache`: Force fresh analysis, ignore cached results

## Examples

```bash
# Quick scan without Notion sync
/repo:scan-org

# Full analysis with Notion sync
/repo:scan-org --sync --deep

# Scan with exclusions
/repo:scan-org --sync --exclude test-repo,old-prototype,archived-project

# Include archived repositories
/repo:scan-org --sync --include-archived
```

## Expected Output

```
🔍 Scanning organization: brookside-bi
   Found 47 repositories (3 archived, excluded)

�� Analyzing repositories (max 10 concurrent)...
   [████████████████████████████████] 100% (47/47)

📈 Analysis Summary:
   Total Repositories: 47
   High Viability: 12 (25.5%)
   Medium Viability: 28 (59.6%)
   Low Viability: 7 (14.9%)

   Highly Reusable: 15 (31.9%)
   Partially Reusable: 22 (46.8%)
   One-Off: 10 (21.3%)

   Total Monthly Cost: $1,247.00
   Average Cost per Repo: $26.53

🤖 Claude Integration Maturity:
   Expert (80-100): 3 repos
   Advanced (60-79): 8 repos
   Intermediate (30-59): 12 repos
   Basic/None (0-29): 24 repos

💾 Syncing to Notion...
   ✓ Created/updated 47 Example Build entries
   ✓ Linked 183 software dependencies
   ✓ Cost rollups verified

✅ Scan complete in 4m 32s
```

## Related Commands

- `/repo:analyze <repo-name>` - Analyze single repository in detail
- `/repo:extract-patterns` - Extract patterns from existing analyses
- `/repo:calculate-costs` - Calculate portfolio costs

## Verification Steps

```bash
# Verify Example Builds were created/updated in Notion
# Check Software Tracker dependencies linked
# Verify cost rollups display correctly
```
