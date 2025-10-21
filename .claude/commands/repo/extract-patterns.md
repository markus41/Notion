---
description: Extract cross-repository architectural patterns and assess reusability
allowed-tools: Task(@repo-analyzer:*)
argument-hint: [--min-usage 3] [--sync]
model: claude-sonnet-4-5-20250929
---

## Context

Analyze all organization repositories to identify common architectural patterns, shared dependencies, and reusable components. This solution is designed to drive knowledge sharing and prevent duplicate work through systematic pattern recognition.

## Workflow

Invoke `@repo-analyzer` agent to execute pattern mining:

### 1. Load Repository Analyses

- Use cached analyses if available (within 7 days)
- If cache expired: Run full organization scan
- Load all repository metadata and dependency lists

### 2. Pattern Detection

**Architectural Patterns:**
- Serverless Functions (Azure Functions, AWS Lambda)
- RESTful API Design (FastAPI, Flask, Express)
- Microservices Architecture
- Event-Driven Architecture (Azure Event Grid, webhooks)
- Batch Processing (Azure Functions timer triggers)

**Integration Patterns:**
- Azure Key Vault (credential management)
- Notion MCP (knowledge management)
- GitHub MCP (version control operations)
- Azure MCP (cloud operations)
- Microsoft 365 integrations

**Design Patterns:**
- FastAPI/Flask/Express web frameworks
- Pydantic/TypeScript type validation
- pytest/jest testing frameworks
- Poetry/npm dependency management
- Black/Prettier code formatting

### 3. Usage Analysis

For each pattern:
- Count repositories using pattern
- Calculate percentage of portfolio
- Identify example repositories
- Assess pattern quality (tests, docs, maintenance)
- Calculate reusability score (0-100)

**Reusability Scoring:**
```
Score = (adoption_rate * 40) + (avg_viability * 30) + (documentation * 20) + (consistency * 10)

Where:
  adoption_rate = (repos_using_pattern / total_repos) * 100
  avg_viability = Average viability score of repos using pattern
  documentation = Existence of pattern documentation
  consistency = Implementation similarity across repos
```

### 4. Filter by Minimum Usage

- Apply `--min-usage` threshold (default: 3 repositories)
- Sort patterns by reusability score (descending)
- Group by category (Architectural, Integration, Design)

### 5. Notion Sync (if `--sync` flag)

**Knowledge Vault Entries:**

For each pattern:
```
Title: "Pattern: [Pattern Name]"
Content Type: Reference
Status: Published
Tags: Pattern, Architecture, [Technology]

Content:
  - Pattern description
  - Usage statistics (X repos, Y%)
  - Reusability score
  - Example repositories (top 3)
  - Implementation guidelines
  - Benefits and trade-offs

Relations:
  - Link to Example Builds using pattern
  - Link to Software Tracker (related tools)
```

### 6. Generate Pattern Report

Display:
- Total unique patterns identified
- Patterns by category
- Top 10 patterns by adoption
- Reusability scores
- Example repositories for each pattern
- Recommendations for standardization

## Parameters

- `--min-usage <N>`: Minimum repositories using pattern (default: 3)
- `--sync`: Create Knowledge Vault entries for patterns
- `--category <type>`: Filter by category (architectural, integration, design)
- `--output <file>`: Save JSON results to file

## Examples

```bash
# Extract all patterns used in 3+ repos
/repo:extract-patterns

# Only show patterns used in 5+ repos
/repo:extract-patterns --min-usage 5

# Sync patterns to Knowledge Vault
/repo:extract-patterns --sync

# Only architectural patterns
/repo:extract-patterns --category architectural --sync
```

## Expected Output

```
🔍 Extracting cross-repository patterns...
   Analyzing 47 repositories

📊 Pattern Analysis Results:

🏗️  Architectural Patterns (5 found):

   1. Azure Functions (Serverless)
      Usage: 12 repositories (25.5%)
      Reusability Score: 90/100
      Examples: repo-analyzer, cost-tracker, email-automation

   2. RESTful API Design
      Usage: 18 repositories (38.3%)
      Reusability Score: 85/100
      Examples: api-gateway, customer-portal, data-service

   3. Event-Driven Architecture
      Usage: 7 repositories (14.9%)
      Reusability Score: 75/100
      Examples: notification-hub, workflow-engine

🔗 Integration Patterns (6 found):

   1. Azure Key Vault (Credential Management)
      Usage: 15 repositories (31.9%)
      Reusability Score: 95/100
      Examples: repo-analyzer, secure-app, api-service

   2. Notion MCP Integration
      Usage: 8 repositories (17.0%)
      Reusability Score: 80/100
      Examples: repo-analyzer, idea-tracker, docs-sync

   3. GitHub MCP Integration
      Usage: 6 repositories (12.8%)
      Reusability Score: 82/100
      Examples: repo-analyzer, pr-automation

🎨 Design Patterns (8 found):

   1. FastAPI Framework
      Usage: 14 repositories (29.8%)
      Reusability Score: 88/100
      Examples: api-gateway, data-service, ml-inference

   2. Pydantic Data Validation
      Usage: 19 repositories (40.4%)
      Reusability Score: 92/100
      Examples: repo-analyzer, cost-tracker, validation-lib

   3. pytest Testing Framework
      Usage: 16 repositories (34.0%)
      Reusability Score: 87/100
      Examples: repo-analyzer, api-gateway, utils-lib

📈 Summary:
   Total Patterns Identified: 19
   High Reusability (80-100): 12 patterns
   Medium Reusability (60-79): 5 patterns
   Low Reusability (0-59): 2 patterns

💡 Recommendations:
   ✓ Standardize on FastAPI for new API projects (14 existing examples)
   ✓ Adopt Pydantic validation across all Python projects (92/100 score)
   ✓ Increase Azure Key Vault adoption (highest security, 95/100 score)
   ⚠ Consider consolidating event architectures (7 different implementations)

💾 Syncing to Notion Knowledge Vault...
   ✓ Created 19 pattern documentation entries
   ✓ Linked to 47 Example Build entries
   ✓ Tagged with technology and architecture labels

✅ Pattern extraction complete
```

## Related Commands

- `/repo:scan-org` - Full organization scan (generates pattern data)
- `/repo:analyze <repo>` - Check patterns in specific repository
- `/knowledge:archive` - Archive pattern to Knowledge Vault manually

## Verification Steps

```bash
# If --sync enabled:
# 1. Open Notion Knowledge Vault
# 2. Filter by Content Type = "Reference"
# 3. Search for "Pattern:" entries
# 4. Verify pattern descriptions complete
# 5. Check Example Build relations linked
```

## Use Cases

**1. Architecture Standardization:**
```
/repo:extract-patterns --min-usage 5 --sync
# Identify widely-adopted patterns to standardize on
```

**2. Knowledge Sharing:**
```
/repo:extract-patterns --sync
# Document reusable patterns for team reference
```

**3. Technology Selection:**
```
/repo:extract-patterns --category design
# See which frameworks/libraries are popular
```

**4. Consolidation Opportunities:**
```
/repo:extract-patterns --min-usage 2
# Find patterns with low adoption to consolidate
```

## Pattern Categories Explained

**Architectural Patterns:**
- High-level system design decisions
- Example: Serverless vs. Microservices vs. Monolith

**Integration Patterns:**
- How services connect and authenticate
- Example: MCP servers, Azure services, third-party APIs

**Design Patterns:**
- Code-level implementation choices
- Example: Frameworks, libraries, testing approaches

---

**This command establishes pattern intelligence to drive reuse, standardization, and knowledge sharing across the Brookside BI repository portfolio.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
