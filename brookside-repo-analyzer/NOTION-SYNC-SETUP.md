# Notion Sync Setup Guide

**Purpose**: Enable automated repository analysis synchronization to Notion Innovation Nexus

---

## Prerequisites

✓ Azure CLI authenticated (`az login`)
✓ Access to Notion workspace (Brookside BI)
✓ Repository analyzer installed via Poetry
✓ Multi-organization scan completed (15 repositories analyzed)

---

## Step 1: Create Notion Integration

### 1.1 Navigate to Notion Integrations

1. Open browser to: https://www.notion.so/my-integrations
2. Click **"+ New integration"**
3. Configure integration:
   - **Name**: `Brookside BI Repository Analyzer`
   - **Logo**: Upload Brookside BI logo (optional)
   - **Associated workspace**: Select "Brookside BI"
   - **Type**: Internal integration
   - **Content Capabilities**:
     - ✓ Read content
     - ✓ Update content
     - ✓ Insert content
   - **Comment Capabilities**: (leave unchecked)
   - **User Capabilities**: ✓ Read user information without email addresses

4. Click **"Submit"**

### 1.2 Copy Integration Token

1. On the integration page, locate **"Internal Integration Token"**
2. Click **"Show"** then **"Copy"**
3. Store securely - this is your `notion-api-key`

**Format**: `ntn_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`

---

## Step 2: Grant Integration Access to Databases

The integration needs access to these Notion databases:

### Required Databases

1. **🛠️ Example Builds** (`a1cd1528-971d-4873-a176-5e93b93555f6`)
   - Repository entries will be created/updated here

2. **💰 Software & Cost Tracker** (`13b5e9de-2dd1-45ec-839a-4f3d50cd8d06`)
   - Dependencies and costs will be linked here

3. **📚 Knowledge Vault** (ID to be confirmed)
   - Pattern library entries will be created here

### Grant Access Procedure

For each database above:

1. Open the database in Notion
2. Click the **"..."** menu (top right)
3. Select **"Add connections"**
4. Search for **"Brookside BI Repository Analyzer"**
5. Click to grant access

**Important**: Without these connections, the sync will fail with authentication errors.

---

## Step 3: Store Notion API Key in Azure Key Vault

### 3.1 Set Secret via Azure CLI

```powershell
# Navigate to repository directory
cd C:\Users\MarkusAhling\Notion

# Set the Notion API key in Key Vault
az keyvault secret set `
  --vault-name kv-brookside-secrets `
  --name notion-api-key `
  --value "ntn_YOUR_ACTUAL_TOKEN_HERE"
```

### 3.2 Verify Secret Storage

```powershell
# Confirm secret exists
az keyvault secret show `
  --vault-name kv-brookside-secrets `
  --name notion-api-key `
  --query "value" `
  --output tsv
```

**Expected Output**: Your Notion API key (starting with `ntn_`)

---

## Step 4: Run Repository Scan with Notion Sync

### 4.1 Full Portfolio Scan (All Organizations)

```powershell
cd C:\Users\MarkusAhling\Notion\brookside-repo-analyzer

# Scan all 5 organizations with Notion sync enabled
.\run-all-orgs-scan.ps1 -Sync
```

**Expected Duration**: ~3-5 minutes (160s scan + Notion API calls)

### 4.2 Single Organization Scan

```powershell
# Scan specific organization only
.\run-scan.ps1 -Org "markus41" -Sync

# Scan with full deep analysis
.\run-scan.ps1 -Org "Advisor-OS" -Full -Sync
```

---

## Step 5: Verify Notion Synchronization

### 5.1 Check Example Builds Database

1. Open: https://www.notion.so/a1cd152897d4873a1765e93b93555f6
2. Expected: 15 repository entries (7 from markus41, 1 from Advisor-OS, etc.)
3. Verify fields populated:
   - Repository name
   - GitHub URL
   - Viability rating (💎 High / ⚡ Medium / 🔻 Low)
   - Reusability assessment (✨ / ↔️ / 🔒)
   - Claude maturity level
   - Last analyzed timestamp

### 5.2 Check Software & Cost Tracker Linkages

1. Open any repository entry in Example Builds
2. Scroll to **"Software Used"** relation
3. Expected: Dependencies detected from package.json/requirements.txt
4. Verify cost rollup formula displays total monthly cost

---

## Step 6: Clean Up Dummy/Test Data

### 6.1 Identify Dummy Entries

Search Example Builds for entries with:
- Missing GitHub URLs
- Created before repository analysis (before 2025-10-21)
- Names like "Test Build", "Example", "Placeholder"
- Status = "Concept" with no actual repository

### 6.2 Archive or Delete Dummy Entries

**Option A: Archive** (Recommended - preserves history)
```
1. Open dummy entry
2. Change Status → "Archived"
3. Add note: "Pre-analysis test data - archived [date]"
```

**Option B: Delete** (Permanent removal)
```
1. Open dummy entry
2. Click "..." menu → "Delete"
3. Confirm deletion
```

### 6.3 Clean Software Tracker Orphans

```
1. Open Software & Cost Tracker
2. Filter: Status = "Active" AND Related Builds count = 0
3. Review each entry:
   - If legitimately used: Link to correct builds
   - If test data: Archive or delete
```

---

## Step 7: Automated Sync Schedule (Future Enhancement)

### Planned Deployment: Azure Function

**Schedule**: Weekly (Sunday 00:00 UTC)

**Configuration**:
```json
{
  "schedule": "0 0 * * 0",
  "command": "poetry run brookside-analyze scan --all-orgs --sync",
  "runtime": "python3.11",
  "timeout": "10 minutes",
  "secrets": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "@Microsoft.KeyVault(SecretUri=https://kv-brookside-secrets.vault.azure.net/secrets/github-personal-access-token/)",
    "NOTION_API_KEY": "@Microsoft.KeyVault(SecretUri=https://kv-brookside-secrets.vault.azure.net/secrets/notion-api-key/)"
  }
}
```

**See**: `deployment/azure_function/README.md` for setup instructions

---

## Troubleshooting

### Issue: "Notion credentials not found"

**Symptom**: Scanner shows `WARN Notion credentials not found (--sync disabled)`

**Solution**:
1. Verify secret exists: `az keyvault secret show --vault-name kv-brookside-secrets --name notion-api-key`
2. Check secret name spelling (must be exactly `notion-api-key`)
3. Restart PowerShell session to clear credential cache

### Issue: "401 Unauthorized" from Notion API

**Symptom**: HTTP errors during sync

**Solutions**:
1. **Token expired**: Regenerate integration token in Notion settings
2. **Database access missing**: Grant integration access to databases (Step 2)
3. **Wrong workspace**: Verify integration is in "Brookside BI" workspace

### Issue: Duplicate repository entries created

**Symptom**: Multiple entries for same repository

**Solutions**:
1. **Search logic failure**: Check repository URL matching in `src/notion_client.py`
2. **Manual fix**: Merge duplicates manually in Notion
3. **Prevention**: Run with `--no-sync` first to test, then enable sync

### Issue: Dependencies not detected

**Symptom**: Software Tracker relations empty

**Solutions**:
1. **No package manifest**: Repository has no package.json or requirements.txt
2. **Cost database missing**: Ensure `src/data/cost_database.json` exists
3. **API rate limit**: Wait and re-run scan

---

## Portfolio Scan Results Summary

**Organizations Scanned**: 5
**Total Repositories**: 15

| Organization | Repos | Avg Viability | Notion Sync |
|--------------|-------|---------------|-------------|
| markus41 | 7 | Medium | ✓ Pending |
| Advisor-OS | 1 | Medium | ✓ Pending |
| The-Chronicle-of-Realm-Works | 3 | Medium | ✓ Pending |
| Densbys-MVPs | 2 | Medium | ✓ Pending |
| Brookside-Proving-Grounds | 2 | Medium | ✓ Pending |

**Status**: Analysis complete, Notion sync awaiting API key configuration

---

## Next Steps

1. ✅ **Complete Step 1-2**: Create Notion integration and grant database access
2. ✅ **Complete Step 3**: Store API key in Azure Key Vault
3. ⏳ **Execute Step 4**: Run full portfolio scan with `--sync` enabled
4. ⏳ **Verify Step 5**: Confirm 15 repositories in Example Builds database
5. ⏳ **Clean Step 6**: Remove dummy/test data from Notion
6. 📅 **Future**: Deploy Azure Function for automated weekly scans

---

**Designed for**: Organizations requiring automated repository portfolio management with centralized knowledge tracking and cost visibility through sustainable Notion integration.

**Best for**: Teams managing 10+ repositories across multiple GitHub organizations seeking to streamline visibility into code health, reusability, and Claude Code maturity.

---

**Support**: Consultations@BrooksideBI.com | +1 209 487 2047
