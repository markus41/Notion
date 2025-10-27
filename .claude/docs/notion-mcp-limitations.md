# Notion MCP Known Limitations

**Purpose**: Document current constraints of the Notion MCP server to establish clear expectations for automated operations.

**Best for**: Agents planning Notion operations requiring relation or property batch updates.

---

## Relation Property Updates

### Limitation

The `notion-update-page` tool **does not support updating relation properties with arrays**.

**Error Pattern**:
```
Invalid arguments for tool notion-update-page: Expected string, received array
```

**Affected Operations**:
- Adding multiple items to relation properties (e.g., "Software/Tools Used")
- Bulk linking software dependencies to builds
- Batch assigning team members to ideas/research/builds

### Workaround Options

#### Option 1: Manual Linking (Recommended for <10 relations)
1. Open page in Notion UI
2. Click relation property field
3. Search and select items manually
4. Saves immediately, rollups recalculate automatically

**Use When**: Adding 2-10 relations, one-time updates, or user prefers UI control

#### Option 2: Direct Notion API Script (Recommended for >10 relations)
Create PowerShell script using Notion REST API directly:

```powershell
# Example: Update-NotionRelations.ps1
param(
    [string]$PageId,
    [string]$PropertyName,
    [string[]]$RelationIds  # Array of page IDs to link
)

# Retrieve API key from Key Vault
$apiKey = & .\.claude\utils\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key"

# Build PATCH request body (Notion API format)
$body = @{
    properties = @{
        $PropertyName = @{
            relation = $RelationIds | ForEach-Object { @{ id = $_ } }
        }
    }
} | ConvertTo-Json -Depth 10

# Execute PATCH request
$headers = @{
    "Authorization" = "Bearer $apiKey"
    "Notion-Version" = "2022-06-28"
    "Content-Type" = "application/json"
}

Invoke-RestMethod -Uri "https://api.notion.com/v1/pages/$PageId" `
    -Method PATCH `
    -Headers $headers `
    -Body $body
```

**Use When**: Bulk operations, >10 relations, repeated patterns, CI/CD integration

#### Option 3: Incremental Single Updates (Not Recommended)
Theoretically could update relations one at a time by:
1. Fetching current relations
2. Appending new relation
3. Updating entire array

**Problem**: Notion MCP `update-page` doesn't accept arrays, so this fails at step 3.

---

## Other Known Limitations

### 1. Database Schema Modifications

**Limitation**: Cannot create new relation properties programmatically via MCP.

**Workaround**:
- Create relation properties manually in Notion UI first
- Then use MCP to populate values (subject to relation update limitation above)

### 2. Multi-Select Properties

**Limitation**: Similar to relations, multi-select updates may not support array syntax.

**Status**: Needs verification - not yet tested comprehensively.

**Workaround**: Manual UI updates or direct API calls.

### 3. Formula Properties

**Limitation**: Cannot modify formula definitions via MCP.

**Workaround**:
- Define formulas in Notion UI
- MCP can read calculated values but not change formula logic

### 4. View Configuration

**Limitation**: Cannot create or modify database views (filters, sorts, groupings) via MCP.

**Workaround**:
- Configure views manually in Notion UI
- MCP queries respect existing view configurations when fetching data

---

## Impact on Brookside BI Innovation Nexus

### Affected Workflows

1. **Dependency Linking** (258 dependencies across 5 builds)
   - **Impact**: Cannot automate Software Tracker relation updates
   - **Mitigation**: Manual linking guide provided, UI-based process
   - **Status**: 62/258 completed via manual process

2. **Cost Rollup Calculations**
   - **Impact**: Rollups work correctly once relations established manually
   - **Mitigation**: Verify relations exist before expecting cost data
   - **Status**: No impact once initial linking complete

3. **Agent Activity Tracking**
   - **Impact**: Agent Activity Hub can link to Ideas/Research/Builds manually
   - **Mitigation**: Single relation updates likely supported (needs testing)
   - **Status**: Monitoring in Phase 4 rollout

### Recommended Practices

**For Schema Managers**:
- Always fetch current page state before proposing relation updates
- Document manual steps clearly when automation not possible
- Consider direct API scripts for bulk operations
- Test incremental approaches before recommending to users

**For Users**:
- Prefer manual linking for <10 relations (faster, more reliable)
- Request PowerShell script creation for >20 relations (one-time setup, reusable)
- Expect UI-based workflows for database schema modifications

---

## Future Improvements

### Potential Enhancements

1. **Custom Notion MCP Extension**
   - Extend MCP server with relation update support
   - Requires TypeScript development and MCP SDK knowledge
   - **Effort**: Medium (2-4 days)

2. **Hybrid Approach Tool**
   - PowerShell function that wraps Notion API for relation updates
   - Integrates with existing MCP commands
   - **Effort**: Low (4-8 hours)

3. **Notion Formula-Based Workarounds**
   - Explore if certain operations can be formula-driven
   - Example: Auto-calculate rollups instead of manual relations
   - **Effort**: Low (case-by-case basis)

### Feature Requests

**To Submit to Notion MCP Maintainers**:
- Support array values for relation property updates
- Support multi-select property array updates
- Add `append_relations` command to avoid overwriting existing links

**Tracking**: Consider opening GitHub issue on Notion MCP repository.

---

## Validation Checklist

**Before proposing automated Notion relation updates**:
- ✅ Confirmed operation is NOT relation property update with multiple values
- ✅ Verified alternative approach exists (manual UI or direct API)
- ✅ Documented workaround clearly if automation not possible
- ✅ Set user expectations about manual steps required

**When manual process required**:
- ✅ Provided step-by-step instructions with exact property names
- ✅ Included verification steps to confirm success
- ✅ Noted automatic rollup recalculation behavior
- ✅ Estimated time for manual completion

---

**Last Updated**: 2025-10-26

**Related Documentation**:
- [Notion Schema](./notion-schema.md)
- [Manual Dependency Linking Guide](./manual-dependency-linking-guide.md)
- [Azure Infrastructure](./azure-infrastructure.md) (Key Vault for API key retrieval)
