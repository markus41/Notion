# Notion Database ID Configuration Guide

## Authentication Required

The Notion MCP server requires authentication before database IDs can be queried.

### Authentication Steps

1. **Authenticate Notion MCP**:
   ```bash
   # The Notion MCP is configured in .claude.json but needs authentication
   # Follow the authentication prompts when running Notion commands
   ```

2. **Verify Authentication**:
   ```bash
   claude mcp list
   # Should show: notion: ✓ Connected
   ```

## Database Structure

The Brookside BI Innovation Nexus consists of 7 interconnected databases:

### 1. 💡 Ideas Registry
- **Purpose**: Innovation starting point
- **Key Fields**:
  - Status: Concept | Active | Not Active | Archived
  - Viability: High | Medium | Low | Needs Research
  - Champion: Team member assigned
  - Innovation Type: Category of innovation
  - Effort: XS | S | M | L | XL
  - Impact Score: 1-10 rating
- **Relations**: Research Hub, Example Builds, Software Tracker
- **Key Rollup**: Estimated Cost (from linked software)
- **Database ID**: `TBD after authentication`

### 2. 🔬 Research Hub
- **Purpose**: Feasibility investigation
- **Key Fields**:
  - Status: Concept | Active | Not Active | Completed
  - Viability Assessment: Highly Viable | Moderately Viable | Not Viable | Inconclusive
  - Next Steps: Build Example | More Research | Archive | Abandon
  - Hypothesis: Clear research question
  - Methodology: Research approach
- **Relations**: Ideas Registry, Software Tracker
- **Database ID**: `TBD after authentication`

### 3. 🛠️ Example Builds
- **Purpose**: Working prototypes/demos
- **Key Fields**:
  - Status: Concept | Active | Not Active | Completed | Archived
  - Build Type: Prototype | POC | Demo | MVP | Reference Implementation
  - Viability: Production Ready | Needs Work | Reference Only
  - Reusability: Highly Reusable | Partially Reusable | One-Off
  - Repository URL: GitHub link
  - Lead Builder: Primary developer
  - Core Team: Supporting team members
- **Relations**: Ideas Registry, Research Hub, Software Tracker, Knowledge Vault
- **Key Rollup**: Total Cost (from linked software)
- **Database ID**: `TBD after authentication`

### 4. 💰 Software & Cost Tracker
- **Purpose**: Financial hub (central cost source)
- **Key Fields**:
  - Cost: Monthly cost per license
  - License Count: Number of seats
  - Status: Active | Trial | Inactive | Cancelled
  - Category: Development | Infrastructure | Productivity | Analytics | Communication | Security | Storage | AI/ML | Design
  - Microsoft Service: Azure | M365 | Power Platform | GitHub | Dynamics | None
  - Owner: Responsible person
  - Contract End Date: Renewal tracking
  - Criticality: Critical | Important | Nice to Have
- **Formulas**:
  - Total Monthly Cost = Cost × License Count
  - Annual Cost = Cost × 12
- **Relations FROM**: All other databases (central hub)
- **Database ID**: `TBD after authentication`

### 5. 📚 Knowledge Vault
- **Purpose**: Archived learnings
- **Key Fields**:
  - Status: Draft | Published | Deprecated | Archived
  - Content Type: Tutorial | Case Study | Technical Doc | Process | Template | Post-Mortem | Reference
  - Evergreen/Dated: Longevity classification
  - Expertise Level: Beginner | Intermediate | Advanced | Expert
  - Category: Topic area
  - Tags: Keywords for discovery
  - Key Takeaways: Summary of learnings
- **Relations**: Ideas, Research, Builds, Software Tracker
- **Database ID**: `TBD after authentication`

### 6. 🔗 Integration Registry
- **Purpose**: System connections
- **Key Fields**:
  - Integration Type: API | Webhook | Database | File Sync | Automation | Embed
  - Authentication Method: Azure AD | Service Principal | API Key | OAuth
  - Security Review Status: Approved | Pending | N/A
  - Source System: System being integrated
  - Target System: Destination system
  - Status: Active | Inactive | Deprecated
- **Relations**: Software Tracker, Example Builds
- **Database ID**: `TBD after authentication`

### 7. 🎯 OKRs & Strategic Initiatives
- **Purpose**: Alignment tracker
- **Key Fields**:
  - Status: Concept | Active | Not Active | Completed
  - Progress %: 0-100
  - Quarter: Time period
  - Owner: Responsible leader
  - Key Results: Measurable outcomes
- **Relations**: Ideas Registry, Example Builds
- **Database ID**: `TBD after authentication`

## After Authentication - Database ID Discovery

Once Notion MCP is authenticated, run these commands to discover database IDs:

```bash
# Search for each database by name
# Ideas Registry
notion-search "Ideas Registry" --database

# Research Hub
notion-search "Research Hub" --database

# Example Builds
notion-search "Example Builds" --database

# Software & Cost Tracker
notion-search "Software Tracker" --database

# Knowledge Vault
notion-search "Knowledge Vault" --database

# Integration Registry
notion-search "Integration Registry" --database

# OKRs & Strategic Initiatives
notion-search "OKRs" --database
```

## Updating Commands with Database IDs

Once database IDs are discovered, update all slash commands in `.claude/commands/` that reference Notion databases:

### Example Update Pattern

**Before:**
```markdown
Query Notion Ideas Registry database
```

**After:**
```markdown
Query Notion database: ${NOTION_DATABASE_ID_IDEAS}
# Or hardcode the UUID if environment variables aren't supported:
# Database ID: 123e4567-e89b-12d3-a456-426614174000
```

### Commands Requiring Database ID Updates

**Cost Commands (12 files):**
- monthly-spend.md → Software Tracker
- annual-projection.md → Software Tracker
- cost-by-category.md → Software Tracker
- unused-software.md → Software Tracker + Ideas/Research/Builds (for relation counting)
- consolidation-opportunities.md → Software Tracker
- expiring-contracts.md → Software Tracker
- build-costs.md → Example Builds + Software Tracker
- research-costs.md → Research Hub + Software Tracker
- what-if-analysis.md → Software Tracker + Ideas/Research/Builds
- cost-impact.md → Software Tracker
- microsoft-alternatives.md → Software Tracker

**Innovation Commands (5 files):**
- innovation/new-idea.md → Ideas Registry + Software Tracker
- innovation/start-research.md → Research Hub + Ideas Registry + Software Tracker
- cost/analyze.md → Software Tracker
- knowledge/archive.md → All databases (for archival workflow)
- team/assign.md → Ideas/Research/Builds (for assignment)

## Configuration File Update

Update the CLAUDE.md environment section:

```bash
# Database IDs (populate after authentication)
NOTION_DATABASE_ID_IDEAS=<UUID from discovery>
NOTION_DATABASE_ID_RESEARCH=<UUID from discovery>
NOTION_DATABASE_ID_BUILDS=<UUID from discovery>
NOTION_DATABASE_ID_SOFTWARE=<UUID from discovery>
NOTION_DATABASE_ID_KNOWLEDGE=<UUID from discovery>
NOTION_DATABASE_ID_INTEGRATIONS=<UUID from discovery>
NOTION_DATABASE_ID_OKRS=<UUID from discovery>
```

## Verification Checklist

After populating database IDs:

- [ ] All 17 existing commands reference correct database IDs
- [ ] Test query against Ideas Registry returns results
- [ ] Test query against Software Tracker returns cost data
- [ ] Test relation counting between databases works
- [ ] Verify rollup calculations (Estimated Cost, Total Cost) function properly
- [ ] Confirm all 7 databases are accessible via Notion MCP
- [ ] Update .claude/.env (if exists) with database ID environment variables

## Best Practices

1. **Use Descriptive Comments**: When hardcoding UUIDs, add comments explaining which database
   ```markdown
   # Database ID: 123e4567... (💡 Ideas Registry)
   ```

2. **Centralize Configuration**: Consider creating a shared configuration file
   ```markdown
   # .claude/notion-config.md
   - IDEAS_DB: 123e4567...
   - RESEARCH_DB: 234e5678...
   [etc.]
   ```

3. **Test Before Deployment**: Always test database queries in isolation before integrating into commands

4. **Document Relations**: Keep this file updated as database structure evolves

---

**Next Steps**:
1. Authenticate Notion MCP
2. Discover database IDs using search commands
3. Update this document with actual UUIDs
4. Update all slash commands with database IDs
5. Test each command with real Notion data
6. Mark authentication task as complete

**Brookside BI Innovation Nexus** - Establishing scalable infrastructure for innovation management through structured database architecture designed to streamline key workflows and drive measurable outcomes.
