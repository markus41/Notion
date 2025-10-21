---
description: Calculate portfolio-wide software costs with optimization recommendations
allowed-tools: Task(@repo-analyzer:*)
argument-hint: [--detailed] [--category <name>]
model: claude-sonnet-4-5-20250929
---

## Context

Aggregate software and dependency costs across all organization repositories to establish comprehensive cost visibility and identify optimization opportunities aligned with Brookside BI's Microsoft-first approach.

## Workflow

Invoke `@repo-analyzer` agent to perform cost analysis:

### 1. Load Repository Analyses

- Use cached repository analyses (within 7 days)
- Extract all dependencies from each repository
- Load cost database (src/data/cost_database.json)

### 2. Cost Aggregation

For each unique dependency across all repositories:
- Query Software & Cost Tracker for existing entry
- If not found: Look up in cost database
- Calculate monthly cost × usage count
- Categorize by type (Infrastructure, AI/ML, Development, etc.)
- Tag Microsoft vs. third-party services

### 3. Portfolio Calculations

**Total Costs:**
- Monthly: Sum all dependency costs
- Annual: Monthly × 12
- Average per repository
- Average per category

**Category Breakdown:**
```
Infrastructure: Azure Functions, Storage, SQL
AI/ML: Azure OpenAI, ML services
Development: GitHub Actions, IDEs, CI/CD
Communication: SendGrid, Twilio, Teams
Security: Auth0, Azure AD, Key Vault
```

**Microsoft vs. Third-Party:**
- Microsoft Services: Azure, M365, GitHub, Power Platform
- Third-Party: All other services
- Calculate percentages of total spend

### 4. Optimization Analysis

**Detect Unused Tools:**
- Software with 0 repository dependencies
- Tools in Software Tracker not linked to any builds
- Potential savings if cancelled

**Find Duplicates:**
- Multiple tools serving same purpose
- Example: 3 different project management tools
- Consolidation opportunity cost savings

**Microsoft Alternatives:**
- For each third-party service:
  - Check if Microsoft equivalent exists
  - Calculate cost difference
  - Show potential savings

**Expiring Contracts:**
- Query Software Tracker for contracts ending within 60 days
- Flag for renewal review
- Opportunity to renegotiate or cancel

### 5. Generate Cost Report

Display:
- Total monthly and annual costs
- Category breakdown with percentages
- Microsoft vs. third-party split
- Top 10 most expensive dependencies
- Optimization opportunities with potential savings
- Detailed per-repository costs (if `--detailed` flag)

## Parameters

- `--detailed`: Show per-repository cost breakdown
- `--category <name>`: Filter by specific category
- `--microsoft-only`: Only show Microsoft services
- `--third-party-only`: Only show non-Microsoft services
- `--output <file>`: Save JSON results to file

## Examples

```bash
# Summary costs
/repo:calculate-costs

# Detailed per-repository breakdown
/repo:calculate-costs --detailed

# Only infrastructure costs
/repo:calculate-costs --category Infrastructure

# Microsoft services only
/repo:calculate-costs --microsoft-only

# Save to file
/repo:calculate-costs --output costs.json
```

## Expected Output

```
💰 Portfolio Cost Analysis

📊 Total Costs:
   Monthly: $1,247.00
   Annual: $14,964.00
   Average per Repository: $26.53

📈 Cost Breakdown by Category:
   ├─ Infrastructure: $487.00 (39.1%)
   ├─ AI/ML: $425.00 (34.1%)
   ├─ Development: $198.00 (15.9%)
   ├─ Communication: $87.00 (7.0%)
   └─ Security: $50.00 (4.0%)

🏢 Microsoft vs. Third-Party:
   Microsoft Services: $892.00 (71.5%)
   ├─ Azure Functions: $247.00
   ├─ Azure OpenAI: $475.00
   ├─ Azure Key Vault: $12.00
   ├─ Azure SQL: $108.00
   └─ Microsoft 365: $50.00

   Third-Party Services: $355.00 (28.5%)
   ├─ SendGrid: $67.00
   ├─ Stripe: $125.00
   ├─ Auth0: $98.00
   └─ Datadog: $65.00

💎 Top 10 Most Expensive Dependencies:
   1. Azure OpenAI: $475.00/month (12 repos)
   2. Azure Functions: $247.00/month (18 repos)
   3. Stripe: $125.00/month (3 repos)
   4. Azure SQL: $108.00/month (5 repos)
   5. Auth0: $98.00/month (7 repos)
   6. SendGrid: $67.00/month (9 repos)
   7. Datadog: $65.00/month (4 repos)
   8. Microsoft 365: $50.00/month (all repos)
   9. Azure Key Vault: $12.00/month (15 repos)
  10. GitHub Actions: $8.00/month (22 repos)

💡 Optimization Opportunities:

   🔧 Unused Tools (3 found):
   ├─ Legacy Monitoring Tool: $45/month (0 repos using)
   ├─ Old Email Service: $30/month (0 repos using)
   └─ Deprecated Analytics: $25/month (0 repos using)
   Potential Savings: $100/month ($1,200/year)

   🔄 Consolidation Opportunities (2 found):
   ├─ Multiple project management tools:
   │  Current: Trello ($15) + Asana ($25) + Monday ($38)
   │  Consolidate to: Microsoft Planner (included in M365)
   │  Savings: $78/month ($936/year)
   └─ Email services:
      Current: SendGrid ($67) + Mailgun ($32)
      Consolidate to: One provider
      Savings: $32/month ($384/year)

   🏢 Microsoft Alternatives Available (4 found):
   ├─ Auth0 ($98) → Azure AD B2C ($20)
   │  Savings: $78/month
   ├─ Datadog ($65) → Azure Monitor ($25)
   │  Savings: $40/month
   ├─ SendGrid ($67) → Azure Communication Services ($30)
   │  Savings: $37/month
   └─ Slack ($15) → Microsoft Teams (included)
      Savings: $15/month

   Total Microsoft Alternative Savings: $170/month ($2,040/year)

📋 Contracts Expiring Soon (2):
   ⚠ Stripe (30 days): Review pricing tier
   ⚠ Auth0 (45 days): Consider Azure AD migration

💾 Total Potential Savings:
   Unused Tools: $100/month
   Consolidation: $110/month
   Microsoft Alternatives: $170/month
   ────────────────────────
   Total: $380/month ($4,560/year)

   New Portfolio Cost (if optimized): $867/month ($10,404/year)
   Savings: 30.5%

✅ Cost analysis complete
```

## Detailed Output (with `--detailed` flag)

```
📊 Per-Repository Cost Breakdown:

   1. repo-analyzer: $67.00/month
      ├─ Azure Functions: $5.00
      ├─ Azure OpenAI: $50.00
      └─ GitHub Actions: $12.00

   2. cost-tracker: $92.00/month
      ├─ Azure Functions: $5.00
      ├─ Azure SQL: $75.00
      └─ Azure Key Vault: $12.00

   [... continues for all 47 repositories ...]
```

## Related Commands

- `/repo:scan-org --sync` - Update dependency links to Software Tracker
- `/cost:analyze` - Parent Notion workspace cost analysis
- `/cost:unused-software` - Find unused tools specifically

## Verification Steps

```bash
# Cross-check with Software Tracker:
# 1. Open Notion Software & Cost Tracker
# 2. Filter Status = Active
# 3. Sum "Total Monthly Cost" column
# 4. Compare to this command's output

# Verify dependency links:
# 1. Open Example Builds database
# 2. Select a repository entry
# 3. Check "Software Used" relation count matches analysis
```

## Use Cases

**1. Budget Planning:**
```
/repo:calculate-costs --output budget-q4.json
# Generate quarterly budget forecast
```

**2. Cost Optimization:**
```
/repo:calculate-costs --detailed
# Identify high-cost repositories for review
```

**3. Microsoft Migration:**
```
/repo:calculate-costs --third-party-only
# Find third-party tools to replace with Microsoft
```

**4. Category Analysis:**
```
/repo:calculate-costs --category AI/ML
# Assess AI service spending
```

## Integration with Software Tracker

This command **reads from** Software & Cost Tracker but **does not modify** it. To update the tracker:

1. Run `/repo:scan-org --sync` to link new dependencies
2. Manually add costs to new Software Tracker entries
3. Re-run this command to see updated totals

## Best Practices

1. **Run Monthly**: Track cost trends over time
2. **Act on Recommendations**: Review optimization opportunities
3. **Contract Review**: Check expiring contracts quarterly
4. **Microsoft-First**: Prioritize Microsoft alternatives when viable
5. **Consolidate**: Reduce tool sprawl through standardization

---

**This command establishes complete cost visibility to drive informed decisions about software spending optimization aligned with Brookside BI's Microsoft-first strategy.**

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
