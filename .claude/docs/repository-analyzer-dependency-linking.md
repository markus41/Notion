# Repository Analyzer - Dependency Linking Instructions

**Purpose**: Complete software dependency linking for Repository Analyzer build to enable accurate cost rollup calculations.

**Status**: 17/24 dependencies linked (7 remaining)

---

## Overview

The Repository Analyzer build currently has 17 software dependencies linked. We need to add 7 additional Azure services and core tools to complete the software tracking and enable full cost transparency.

**Build URL**: https://www.notion.so/29886779099a81758e1cf09c7ad4788b

---

## Option 1: Manual Linking (Recommended - 5 minutes)

### Step-by-Step Process

1. **Open Repository Analyzer Build**
   - Navigate to: https://www.notion.so/29886779099a81758e1cf09c7ad4788b
   - Scroll to properties section

2. **Locate "Software/Tools Used" Property**
   - Find the relation property field (currently shows 17 items)
   - Click to open the relation selector modal

3. **Add These 7 Dependencies** (search by exact name):
   - **GitHub Enterprise** (ID: 29586779-099a-818b-a39c-f2a010682014)
   - **Azure Cosmos DB** (ID: 29586779-099a-81c2-b981-eb92a51a5898)
   - **Azure Storage** (ID: 29586779-099a-81fc-9ebe-e0a9783c05c0)
   - **Azure Kubernetes Service** (ID: 29586779-099a-8182-bceb-cc496164dd0b)
   - **Azure Container Registry** (ID: 29586779-099a-813c-bb51-e55680e330db)
   - **Azure DevOps** (ID: 29586779-099a-81ee-b23d-cfd46d4ca1fc)
   - **Notion API** (ID: 29386779-099a-811e-a792-c672b702fe57)

4. **Verification Steps**
   - Confirm all 24 software items now appear in the relation field
   - Check "Total Cost" rollup property updates automatically
   - All 17 existing relations remain intact (no data loss)

5. **Expected Result**
   - Property shows: "24" items selected
   - Total Cost rollup recalculates with new Azure service costs
   - Build now has complete software dependency visibility

---

## Option 2: Automated Script (Alternative - 2 minutes)

### Prerequisites
- Azure CLI authenticated (`az login`)
- Notion API key in Azure Key Vault (`kv-brookside-secrets`)
- PowerShell 7+ installed

### Execution

```powershell
# Navigate to repository root
cd C:\Users\MarkusAhling\Notion

# Run bulk update script
.\scripts\Update-NotionRelations.ps1 `
    -PageId "29886779-099a-8175-8e1c-f09c7ad4788b" `
    -PropertyName "Software/Tools Used" `
    -RelationIds @(
        "29586779-099a-818b-a39c-f2a010682014",  # GitHub Enterprise
        "29586779-099a-81c2-b981-eb92a51a5898",  # Azure Cosmos DB
        "29586779-099a-81fc-9ebe-e0a9783c05c0",  # Azure Storage
        "29586779-099a-8182-bceb-cc496164dd0b",  # Azure Kubernetes Service
        "29586779-099a-813c-bb51-e55680e330db",  # Azure Container Registry
        "29586779-099a-81ee-b23d-cfd46d4ca1fc",  # Azure DevOps
        "29386779-099a-811e-a792-c672b702fe57"   # Notion API
    )
```

### Expected Output

```
[2025-10-26 10:00:00] [Info] === Notion Relation Update ===
[2025-10-26 10:00:00] [Info] Page ID: 29886779-099a-8175-8e1c-f09c7ad4788b
[2025-10-26 10:00:00] [Info] Property: Software/Tools Used
[2025-10-26 10:00:00] [Info] New Relations: 7
[2025-10-26 10:00:00] [Info] Mode: APPEND
[2025-10-26 10:00:01] [Info] Retrieving Notion API key from Azure Key Vault...
[2025-10-26 10:00:02] [Success] API key retrieved successfully
[2025-10-26 10:00:02] [Info] Fetching current page state to preserve existing relations...
[2025-10-26 10:00:03] [Info] Found 17 existing relations
[2025-10-26 10:00:03] [Info] Combining 17 existing + 7 new = 24 total
[2025-10-26 10:00:03] [Info] Updating page with 24 total relations...
[2025-10-26 10:00:04] [Success] Successfully updated relations
[2025-10-26 10:00:04] [Success] === Update Complete ===
[2025-10-26 10:00:04] [Info] Page URL: https://www.notion.so/29886779099a81758e1cf09c7ad4788b
[2025-10-26 10:00:04] [Success] Total relations now: 24
```

### Verification

```powershell
# Validate update succeeded
# (Navigate to build URL and confirm 24 items linked)
```

---

## Why These 7 Dependencies?

These tools represent the Azure services and integrations that the Repository Analyzer uses for:

1. **GitHub Enterprise** - Source repository access for org-wide scanning
2. **Azure Cosmos DB** - NoSQL database for repository metadata storage
3. **Azure Storage** - Blob storage for viability reports and analysis artifacts
4. **Azure Kubernetes Service** - Container orchestration for scalable analysis workloads
5. **Azure Container Registry** - Docker image hosting for analyzer components
6. **Azure DevOps** - CI/CD pipeline integration and work item tracking
7. **Notion API** - Database synchronization and cross-repository pattern tracking

**Cost Impact**: Adding these dependencies provides transparency into the full Azure infrastructure costs (~$250-$500/month depending on usage).

---

## Troubleshooting

### Issue: "Property 'Software/Tools Used' not found"
**Cause**: Property name mismatch or database schema changed
**Solution**:
1. Open build page in Notion UI
2. Verify exact property name (case-sensitive)
3. Update script `-PropertyName` parameter if different

### Issue: "Relation ID not found"
**Cause**: Software Tracker entry doesn't exist or ID is incorrect
**Solution**:
1. Search Software & Cost Tracker database for the tool
2. Verify the page ID (last 32 characters of URL without hyphens)
3. Update script `-RelationIds` array with correct ID

### Issue: Script fails with "API key retrieval error"
**Cause**: Azure CLI not authenticated or Key Vault access denied
**Solution**:
```powershell
# Re-authenticate to Azure
az login

# Verify Key Vault access
az keyvault secret show --vault-name kv-brookside-secrets --name notion-api-key

# Or provide API key directly
.\scripts\Update-NotionRelations.ps1 `
    -PageId "..." `
    -PropertyName "..." `
    -RelationIds @(...) `
    -NotionApiKey "secret_abc123..."
```

### Issue: "429 Rate Limit Exceeded"
**Cause**: Too many Notion API requests in short timeframe
**Solution**:
- Wait 60 seconds and retry
- Notion API limit: 3 requests/second average
- Script includes automatic retry logic (not yet implemented - future enhancement)

---

## Next Steps After Linking

1. **Verify Cost Rollup**
   - Navigate to Repository Analyzer build
   - Confirm "Total Cost" property shows updated sum
   - Compare against Software Tracker to validate accuracy

2. **Update Dependency Mapping JSON**
   ```powershell
   # Mark these 7 dependencies as "linked" in tracking file
   # File: .claude/data/dependency-mapping.json
   # Update "linkedToBuilds" array for each dependency
   ```

3. **Continue Dependency Linking**
   - **Progress**: 62/258 total dependencies linked across all builds
   - **Remaining**: ~196 dependencies for other 4 builds
   - **Next Target**: Brookside Website (largest dependency set)

4. **Generate Cost Analysis Report**
   ```bash
   # Once all dependencies linked, run comprehensive cost analysis
   /cost:analyze all
   ```

---

## Related Documentation

- [Notion MCP Limitations](./../.claude/docs/notion-mcp-limitations.md) - Why automation is complex
- [Manual Dependency Linking Guide](./../.claude/docs/manual-dependency-linking-guide.md) - Other builds
- [Dependency Mapping Status](./../.claude/docs/dependency-linking-status.md) - Overall progress
- [Software & Cost Tracker Schema](./../.claude/docs/notion-schema.md#software--cost-tracker) - Database structure

---

**Last Updated**: 2025-10-26
**Estimated Time**: Manual (5 min) | Automated (2 min)
**Status**: Ready for execution
