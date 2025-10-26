# Troubleshooting & FAQ

**Brookside BI Innovation Nexus Problem Resolution** - Establish rapid diagnosis and resolution pathways for common issues across Azure infrastructure, MCP server connectivity, Notion operations, agent delegation, cost tracking, and repository operations.

**Best for**: New and experienced team members seeking quick, actionable solutions to technical challenges that streamline troubleshooting and minimize downtime across Innovation Nexus workflows.

---

## Overview

This guide provides comprehensive troubleshooting for Innovation Nexus operations, organized by:

- **Authentication Issues**: Azure CLI, MCP servers, Key Vault, Notion OAuth
- **Notion Operations**: Duplicate detection, relation linking, cost rollups, database schema
- **Agent Delegation**: Handoff failures, resource conflicts, completion tracking
- **Cost Tracking**: Missing software entries, incorrect rollups, consolidation analysis
- **Repository Operations**: GitHub API limits, clone failures, sync errors, PR creation
- **Performance Optimization**: Rate limiting, caching, batch operations, timeout handling
- **Emergency Contacts**: Escalation paths for critical issues

**Problem-Solving Approach**:
1. Identify symptoms and error messages
2. Diagnose root cause with verification commands
3. Apply resolution steps with expected outcomes
4. Verify fix and implement prevention strategies

---

## Authentication Issues

### Issue 1: "Access Denied" When Retrieving Key Vault Secret

**Symptoms**:
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"

# Error:
# The user, group or application 'appid=xxx' does not have secrets get permission
# on key vault 'kv-brookside-secrets'
```

**Diagnosis**:
```bash
# Step 1: Verify you're authenticated to correct tenant
az account show

# Step 2: Check your role assignments on Key Vault
az role assignment list \
  --assignee your-email@brooksidebi.com \
  --scope /subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-shared/providers/Microsoft.KeyVault/vaults/kv-brookside-secrets \
  --output table

# Expected: Should show "Key Vault Secrets User" or "Key Vault Secrets Officer"
# If blank: No permissions assigned
```

**Root Causes**:
- RBAC permissions not assigned to your user account
- Authenticated to wrong Azure AD tenant
- Key Vault access policies (legacy) blocking RBAC

**Resolution**:
```bash
# Option 1: Request RBAC permission from Alec Fielding or Markus Ahling
# Email template:
Subject: Key Vault Access Request - [Your Name]

I need "Key Vault Secrets User" role on kv-brookside-secrets to retrieve MCP credentials.

Subscription: cfacbbe8-a2a3-445f-a188-68b3b35f0c84
Key Vault: kv-brookside-secrets
Justification: Daily MCP environment configuration for Innovation Nexus work
Duration: Permanent (daily workflow requirement)

# Option 2: If you have Owner/Contributor on subscription, self-assign:
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee your-email@brooksidebi.com \
  --scope /subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-shared/providers/Microsoft.KeyVault/vaults/kv-brookside-secrets

# Wait 1-2 minutes for permission propagation

# Verify access granted
az keyvault secret list --vault-name kv-brookside-secrets --output table
# Expected: Lists secrets (values masked)
```

**Prevention**:
- All new team members should request Key Vault access during onboarding
- Document RBAC assignments in team wiki
- Set calendar reminder to review Key Vault permissions quarterly

---

### Issue 2: Azure CLI Token Expired

**Symptoms**:
```bash
az resource list
# Error: AADSTS700082: The refresh token has expired or is invalid
# Please run 'az login' to setup account
```

**Diagnosis**:
```bash
# Check token expiration
az account get-access-token --query expiresOn --output tsv
# If shows past date or error: Token expired
```

**Root Causes**:
- Azure CLI access token expires after 1 hour (by default)
- Last `az login` was >24 hours ago (refresh token expired)
- Azure AD conditional access policy changed

**Resolution**:
```bash
# Step 1: Re-authenticate
az login

# Step 2: Verify authentication successful
az account show
# Expected output:
# {
#   "id": "cfacbbe8-a2a3-445f-a188-68b3b35f0c84",
#   "name": "Brookside BI Production",
#   "state": "Enabled",
#   "isDefault": true
# }

# Step 3: Reconfigure MCP environment (credentials may have refreshed)
.\scripts\Set-MCPEnvironment.ps1

# Step 4: Verify Azure MCP connectivity
# In Claude Code session:
claude mcp list
# Expected: ✓ azure (Connected via Azure CLI)
```

**Prevention**:
```bash
# Option 1: Enable persistent refresh tokens (extends from 1 hour to 90 days)
az config set core.enable_broker_on_windows=true  # Windows only
# Requires Microsoft Authentication Broker app

# Option 2: Run az login at start of each work day (recommended)
# Add to morning routine checklist

# Option 3: Set up automatic token refresh script (advanced)
# Schedule task to run `az account get-access-token` every 50 minutes
```

**Typical Turnaround**: 2-3 minutes to re-authenticate

---

### Issue 3: Notion MCP Server Disconnected

**Symptoms**:
```bash
claude mcp list
# Output: ✗ notion (Disconnected)

# OR during task execution:
Task "Search Notion for 'Cost Optimization' idea"
# Error: MCP server 'notion' is not connected
```

**Diagnosis**:
```bash
# Step 1: Check if OAuth token exists
ls C:/Users/MarkusAhling/.claude/cache/notion-oauth
# If file missing or empty: OAuth token not configured

# Step 2: Check Notion integration status
# Visit: https://www.notion.so/my-integrations
# Find: "Innovation Nexus Claude Integration"
# Expected Status: Active
# If status is "Revoked" or not found: Integration access removed

# Step 3: Check MCP configuration
cat C:/Users/MarkusAhling/.claude/mcp.json | grep -A 10 "notion"
# Verify "notion" server defined with correct parameters
```

**Root Causes**:
- Notion OAuth token expired or manually deleted
- Notion workspace administrator revoked integration access
- MCP configuration file corrupted or missing "notion" entry
- Notion integration permissions changed (lost access to databases)

**Resolution**:
```bash
# Step 1: Close Claude Code (if running)
# Ctrl+C in terminal or close window

# Step 2: Delete cached OAuth token
rm -rf C:/Users/MarkusAhling/.claude/cache/notion-oauth

# Step 3: Relaunch Claude Code (will prompt for Notion re-authentication)
claude

# Step 4: Follow OAuth flow in browser
# - Click "Select pages" button
# - Grant access to ALL required databases:
#   ✓ Ideas Registry
#   ✓ Research Hub
#   ✓ Example Builds
#   ✓ Software & Cost Tracker
#   ✓ Knowledge Vault
#   ✓ Agent Registry
#   ✓ Agent Activity Hub
#   ✓ Output Styles Registry
#   ✓ Agent Style Tests
# - Click "Allow access"

# Step 5: Verify reconnection
claude mcp list
# Expected: ✓ notion (Connected via OAuth)

# Step 6: Test connection
Task "List pages in Ideas Registry database"
# Expected: Returns list of idea pages
```

**If Re-Authentication Fails**:
```bash
# Workspace administrator may need to re-enable integration
# Contact: Brad Wright or Markus Ahling

# Request steps:
# 1. Navigate to Notion Settings > Integrations
# 2. Find "Innovation Nexus Claude Integration"
# 3. If status is "Revoked": Click "Restore Access"
# 4. If not found: Create new integration:
#    - Name: Innovation Nexus Claude Integration
#    - Associated workspace: Brookside BI Innovation Nexus
#    - Capabilities: Read content, Update content, Insert content
#    - User capabilities: No user information
# 5. Share integration with all core databases (repeat OAuth flow)
```

**Prevention**:
- Do not manually delete `.claude/cache/notion-oauth` unless troubleshooting
- Communicate with team before revoking Notion integrations
- Set quarterly review of active integrations (ensure still needed)

---

### Issue 4: GitHub PAT Insufficient Permissions

**Symptoms**:
```bash
Task "Create pull request in brookside-bi/innovation-nexus"
# Error: Resource not accessible by integration (403 Forbidden)
# OR: Requires write access to repository
```

**Diagnosis**:
```bash
# Step 1: Check current PAT scopes
# Visit: https://github.com/settings/tokens
# Find token: "Claude Code MCP Integration"
# Check scopes granted:

Required Scopes (minimum):
  ✓ repo (full control of private repositories)
  ✓ workflow (update GitHub Actions workflows)

Recommended Additional Scopes:
  ✓ admin:org (read organization data)
  ✓ write:packages (publish to GitHub Packages)

# Step 2: Test GitHub API with current token
$env:GITHUB_PERSONAL_ACCESS_TOKEN = (.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token")

curl -H "Authorization: Bearer $env:GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/user
# If returns 401: Token invalid or expired
# If returns user data: Token valid, but may lack specific scopes
```

**Root Causes**:
- PAT created with insufficient scopes (only read access)
- PAT expired (GitHub default: 90 days)
- Repository-specific permissions changed (removed write access)
- Organization SAML authentication required but not completed

**Resolution**:
```bash
# Step 1: Generate new PAT with correct scopes
# Navigate to: https://github.com/settings/tokens/new

# Configure PAT:
Name: Claude Code MCP Integration (Refreshed Oct 2025)
Expiration: 90 days
Scopes:
  ✓ repo (all sub-scopes)
  ✓ workflow
  ✓ admin:org (read:org)
  ✓ write:packages

# Click "Generate token"
# COPY TOKEN IMMEDIATELY (shown once)

# Step 2: Update Key Vault secret
az keyvault secret set \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --value "ghp_NEW_TOKEN_HERE"

# Step 3: Update tags (for tracking)
az keyvault secret set-attributes \
  --vault-name kv-brookside-secrets \
  --name github-personal-access-token \
  --tags LastRotated=$(date +%Y-%m-%d) CreatedBy=YourName RotationSchedule=90d

# Step 4: Reconfigure MCP environment
.\scripts\Set-MCPEnvironment.ps1

# Step 5: Restart Claude Code
# Close current session, relaunch:
claude

# Step 6: Verify GitHub MCP connectivity
claude mcp list
# Expected: ✓ github (Connected via PAT)

# Step 7: Test previously failing operation
Task "Create pull request in brookside-bi/innovation-nexus"
# Expected: Success
```

**If Organization Requires SAML SSO**:
```bash
# After generating PAT, authorize for SSO:
# 1. Visit: https://github.com/settings/tokens
# 2. Find new token: "Claude Code MCP Integration (Refreshed Oct 2025)"
# 3. Click "Configure SSO" next to brookside-bi organization
# 4. Click "Authorize"
# 5. Repeat steps 2-7 from resolution above
```

**Prevention**:
- Use fine-grained PAT (more secure, granular permissions per repository)
- Set PAT expiration to 90 days with calendar reminder to rotate
- Document required scopes in Key Vault secret tags
- Test PAT immediately after creation (before storing in Key Vault)

---

### Issue 5: Playwright Browser Launch Failure

**Symptoms**:
```bash
Task "Navigate to https://example.com and capture screenshot"
# Error: Browser launch failed: Executable not found at C:/Users/.../ms-playwright/chromium-*/chrome.exe
```

**Diagnosis**:
```bash
# Step 1: Check if Playwright installed
npx playwright --version
# If error "npx: command not found": Node.js/npm not installed
# If returns version: Playwright package installed

# Step 2: Check if Chromium browser installed
ls C:/Users/MarkusAhling/AppData/Local/ms-playwright/chromium-*/chrome.exe
# If no results: Chromium not installed

# Step 3: Check for antivirus quarantine
# Navigate to antivirus quarantine folder (varies by AV software)
# Search for "chrome.exe" or "chromium"
# If found: Antivirus blocked browser installation
```

**Root Causes**:
- Playwright package updated but browsers not reinstalled
- Antivirus quarantined Chromium executable (false positive)
- Insufficient disk space (Chromium requires ~300 MB)
- User profile folder permissions preventing installation

**Resolution**:
```bash
# Step 1: Install Playwright browsers
npx playwright install chromium

# Expected output:
# Downloading Chromium 119.0.6045.9
# [==========================================>] 100% 0.0s
# Chromium 119.0.6045.9 downloaded to C:/Users/.../ms-playwright/chromium-1097

# If download fails with permission error:
# Run PowerShell as Administrator:
npx playwright install chromium --force

# Step 2: Verify installation
npx playwright --version
# Expected: Version 1.40.0 or later

# Step 3: Test browser launch manually
npx playwright open https://example.com
# Expected: Chromium browser window opens, navigates to example.com

# Step 4: If browser still fails to launch, check antivirus
# Add exclusion for: C:/Users/[Username]/AppData/Local/ms-playwright/
# Consult antivirus documentation for exclusion setup

# Step 5: Restart Claude Code
claude

# Step 6: Test Playwright MCP
Task "Navigate to https://github.com/brookside-bi and capture screenshot"
# Expected: Success, returns screenshot file path
```

**If Installation Fails Due to Disk Space**:
```bash
# Check available disk space
df -h C:
# If <1 GB free: Insufficient space

# Option 1: Free up disk space (temporary files, old downloads)
# Option 2: Change Playwright cache location (advanced)
$env:PLAYWRIGHT_BROWSERS_PATH = "D:/playwright-browsers"  # Use different drive
npx playwright install chromium
```

**Prevention**:
- Add Playwright browser directory to antivirus exclusions during onboarding
- Monitor disk space (alert if <5 GB free)
- Test Playwright after any npm package updates
- Document browser installation in onboarding checklist

---

## Notion Operations

### Issue 6: Duplicate Notion Entries Created

**Symptoms**:
```bash
/innovation:new-idea "AI cost optimization platform"
# Creates new entry

# Later that day:
/innovation:new-idea "AI-powered cost optimization"
# Creates ANOTHER entry (duplicate)

# Result: Ideas Registry has 2 very similar ideas
```

**Diagnosis**:
```bash
# Search for existing ideas with similar keywords
Task "Search Notion Ideas Registry for 'AI cost optimization'"

# Expected: Should find existing entry before creating new one
# If search missed existing entry: Search query too specific or database index stale
```

**Root Causes**:
- Agent not searching before creating (violates protocol)
- Search query too narrow (exact match only, misses synonyms)
- Database indexing delay (newly created entry not yet searchable)
- User creating entry manually AND via command (coordination gap)

**Resolution**:
```bash
# Step 1: Identify duplicate entries
Task "Search Notion Ideas Registry for all entries containing 'cost optimization'"

# Expected output: Lists all matching ideas with URLs

# Step 2: Review duplicates, determine which to keep
# Keep entry with:
#   - Most complete information (description, assessment, relations)
#   - Links to Research/Builds (preserve history)
#   - Earliest created date (if otherwise identical)

# Step 3: Merge information from duplicate into primary entry
Task "Update Notion idea '[Primary Entry Title]' with information from '[Duplicate Entry Title]': [details to merge]"

# Step 4: Archive or delete duplicate
Task "Update Notion idea '[Duplicate Entry Title]' status to 'Archived' and add note 'Duplicate of [Primary Entry URL]'"

# OR delete entirely:
Task "Delete Notion page '[Duplicate Entry URL]'"
```

**Prevention Protocol** (ALWAYS follow):
```bash
# Mandated Workflow:
1. SEARCH for existing content (every time, no exceptions)
   Task "Search Notion [Database] for '[keywords]'"

2. REVIEW search results
   - If found: Update existing entry instead of creating new
   - If not found: Proceed to creation

3. PROPOSE action to user
   "Found existing entry: [URL]. Should I update this or create new?"
   - Wait for user confirmation

4. EXECUTE based on user decision

# Example (correct approach):
/innovation:new-idea "AI cost optimization platform"

# Behind the scenes:
# 1. Agent searches: "Search Notion Ideas Registry for 'AI cost optimization platform'"
# 2. Agent finds: "💡 AI-Powered Cost Analyzer" (70% match)
# 3. Agent asks user: "Found similar idea 'AI-Powered Cost Analyzer'. Update this or create new entry?"
# 4. User responds: "Update existing"
# 5. Agent updates existing entry instead of creating duplicate
```

**Improved Search Strategy**:
```bash
# Instead of exact match search:
Task "Search Notion for 'AI cost optimization platform'"

# Use multiple keyword variations:
Task "Search Notion for pages containing ANY of: 'AI cost', 'cost optimization', 'AI spending', 'cost analyzer'"

# Benefits:
# - Catches synonyms and variations
# - Reduces false negatives (missed duplicates)
# - More robust to phrasing differences
```

**Automated Duplicate Detection** (Future Enhancement):
```bash
# Planned: Weekly duplicate detection report
# Scans all databases for:
#   - Similar titles (>80% text similarity)
#   - Same tags + category
#   - Created within 7 days of each other
#   - No cross-references between entries

# Output: Suggested merges for human review
```

---

### Issue 7: Notion Relation Not Linking Correctly

**Symptoms**:
```bash
/autonomous:enable-idea "AI Chatbot"
# Build completes, creates Example Builds entry
# BUT: "Related Idea" relation is blank (should link to origin idea)

# OR cost rollup shows $0 despite software linked:
# Example Builds entry has 5 software relations
# Total Cost formula shows: $0/month (incorrect)
```

**Diagnosis**:
```bash
# Step 1: Verify relation exists in database schema
Task "Fetch Notion database schema for Example Builds"

# Check for relation property:
# Expected output should include:
# "Related Idea": {
#   "type": "relation",
#   "relation": {
#     "database_id": "984a4038-3e45-4a98-8df4-fd64dd8a1032",  # Ideas Registry
#     "type": "single_property"
#   }
# }

# Step 2: Check if relation is one-way or two-way
# One-way: Only visible in Example Builds → Ideas
# Two-way: Visible in both Example Builds → Ideas AND Ideas → Example Builds

# Step 3: Verify origin idea exists and is accessible
Task "Fetch Notion page '[Origin Idea URL]'"
# If error "Page not found": Idea deleted or permissions issue
# If success: Idea exists, relation should work
```

**Root Causes**:
- Incorrect database ID in relation configuration (pointing to wrong database)
- Using page URL instead of page ID for relation value
- Relation property name mismatch (database expects "Related Idea", code provides "Origin Idea")
- Permission issue (integration lacks access to related database)
- Two-way relation not properly synced (one side updated, other side orphaned)

**Resolution**:
```bash
# Case 1: Missing Relation Link

# Step 1: Get correct page ID for origin idea
Task "Search Notion Ideas Registry for 'AI Chatbot' and return page ID"
# Expected output: "Page ID: 123abc456def789"

# Step 2: Update Example Builds entry with correct relation
Task "Update Notion page '[Example Builds URL]' property 'Related Idea' to link to page ID '123abc456def789'"

# Verify relation created:
Task "Fetch Notion page '[Example Builds URL]' and show 'Related Idea' property"
# Expected: Shows link to origin idea with title "💡 AI Chatbot"

# Case 2: Cost Rollup Shows $0 Despite Software Links

# Step 1: Verify Software Tracker entries exist
Task "Fetch Notion pages for all software linked to build '[Build Name]'"

# Step 2: Check if software has Monthly Cost property populated
# Expected: Each software entry should have Monthly Cost value (e.g., $50)
# If $0 or blank: Software cost not entered, rollup correctly shows $0

# Step 3: Check rollup formula in Example Builds database
Task "Fetch Notion database schema for Example Builds and show 'Total Cost' property"

# Expected formula (should be):
# Property Type: Rollup
# Relation Property: Software Used
# Rollup Property: Monthly Cost
# Function: sum

# If formula incorrect: Update database schema
Task "Update Notion database 'Example Builds' property 'Total Cost' with rollup formula: sum(Software Used.Monthly Cost)"

# Step 4: Verify rollup calculates
Task "Fetch Notion page '[Example Builds URL]' and show 'Total Cost' property"
# Expected: Shows sum of all linked software costs (e.g., $275/month)
```

**Relation Best Practices**:
```yaml
DO:
  ✓ Use page IDs (not URLs) for programmatic relation creation
  ✓ Verify relation database ID matches target database
  ✓ Check property name exact match (case-sensitive)
  ✓ Test relation after creation (fetch page and verify property shows link)
  ✓ Use two-way relations for bidirectional visibility

DON'T:
  ✗ Hardcode page URLs in relation code (use search to get current ID)
  ✗ Assume relation worked without verification
  ✗ Delete pages with relations without checking dependents
  ✗ Create relations to archived pages (creates orphaned links)
```

**Automated Relation Validation** (Future Enhancement):
```bash
# Planned: Post-creation validation hook
# After creating Notion page with relations:
#   1. Wait 2 seconds (allow Notion API to propagate)
#   2. Re-fetch page and verify all relations populated
#   3. If any relation missing: Retry link creation
#   4. If retry fails: Log error, alert user
```

---

### Issue 8: Notion API Rate Limit Exceeded

**Symptoms**:
```bash
Task "Create 50 Notion pages in Ideas Registry for batch import"
# After ~15 pages:
# Error: 429 Too Many Requests
# Notion API rate limit exceeded (3 requests/second)
```

**Diagnosis**:
```bash
# Notion API limits:
# - 3 requests per second (rolling window)
# - Violating limit: HTTP 429 response with Retry-After header

# Check error details:
# Error message should include: "Retry after 1 second"
```

**Root Causes**:
- Creating pages individually in rapid succession (exceeds 3 req/sec)
- Concurrent operations (multiple agents accessing Notion simultaneously)
- No rate limiting logic in automation scripts
- Large batch operations without pagination delays

**Resolution**:
```bash
# Immediate Fix: Wait and Retry

# If hit rate limit mid-operation:
# 1. Wait 2 seconds (allow rolling window to reset)
# 2. Resume operation

# Programmatic retry with exponential backoff:
# Pseudo-code:
retries = 0
max_retries = 5

while retries < max_retries:
  try:
    create_notion_page()
    break  # Success
  except RateLimitError:
    wait_time = 2 ** retries  # Exponential: 1s, 2s, 4s, 8s, 16s
    sleep(wait_time)
    retries += 1

if retries == max_retries:
  log_error("Notion API rate limit exceeded after 5 retries")

# Long-Term Fix: Batch Operations

# Instead of creating 50 pages individually:
# ❌ Inefficient (50 API calls):
for i in range(50):
  create_notion_page(idea_data[i])

# ✅ Efficient (1 API call for up to 100 pages):
create_notion_pages_batch(idea_data)  # Single API call

# Benefits:
# - 50x fewer API calls
# - 97% reduction in rate limit risk
# - 75% faster execution (fewer network round-trips)
```

**Batch Creation with MCP**:
```bash
# Notion MCP supports batch page creation (up to 100 pages per call)
Task "Create 50 Notion pages in Ideas Registry with the following data: [JSON array of 50 ideas]"

# Behind the scenes:
# MCP batches into single API call: notion-create-pages with 50 pages
# Notion API processes all 50 in one request
# Returns array of created page IDs
```

**Prevention**:
```yaml
Rate Limiting Best Practices:

1. Batch Operations (Primary Strategy):
   - Use notion-create-pages for multiple pages (up to 100)
   - Group related operations (e.g., create page + add relations)
   - Amortize API calls across operations

2. Implement Retry Logic (Defensive Strategy):
   - Catch 429 errors, retry with exponential backoff
   - Max retries: 5 (after 31 seconds total, likely resolved)
   - Log retries for monitoring (detect systemic issues)

3. Rate Limit Monitoring (Proactive Strategy):
   - Track API calls per second in application logs
   - Alert if approaching 2.5 req/sec (80% of limit)
   - Throttle proactively before hitting limit

4. Caching (Efficiency Strategy):
   - Cache frequently accessed data (database schemas, reference lists)
   - TTL: 1 hour for schemas (rarely change)
   - Reduces redundant API calls by 60-80%

5. Asynchronous Operations (Concurrency Strategy):
   - Serialize Notion operations within single agent session
   - Use queue for multi-agent scenarios (prevents concurrent bursts)
   - Respect 3 req/sec limit globally (not per agent)
```

**Monitoring API Usage**:
```bash
# Check Notion API usage (if available in workspace settings)
# Navigate to: Notion Settings > Integrations > Innovation Nexus Claude Integration > Usage

# Expected:
# Requests (Last 24 Hours): ~2,000
# Rate Limit Violations: 0 (goal)
# If violations >10/day: Investigate and implement rate limiting
```

---

## Agent Delegation Issues

### Issue 9: Agent Handoff Failed - Missing Context

**Symptoms**:
```bash
# Agent A completes research:
@research-coordinator "Completed research on AI chatbot feasibility. Handoff to @build-architect-v2 for implementation."

# Agent B starts work:
@build-architect-v2 "Starting chatbot build..."
# Error: Missing research findings, cannot determine technology stack
# Agent B halts, requests human intervention
```

**Diagnosis**:
```bash
# Step 1: Check Agent Activity Hub for handoff entry
Task "Search Notion Agent Activity Hub for entries mentioning 'chatbot' and 'handoff'"

# Expected: Should find entry with:
#   - Status: "Handed Off"
#   - Next Agent: "@build-architect-v2"
#   - Context Provided: Yes/No

# Step 2: Review handoff context quality
Task "Fetch Notion page '[Handoff Entry URL]' and show 'Context Provided' field"

# Good Context Includes:
#   ✓ Summary of work completed
#   ✓ Key findings/decisions
#   ✓ Links to related Notion items (Research, Idea)
#   ✓ Explicit next steps for receiving agent
#   ✓ Files/artifacts created

# Poor Context (Missing):
#   ✗ Generic statement: "Completed research"
#   ✗ No links to research findings
#   ✗ No technology stack recommendation
#   ✗ No success criteria for build
```

**Root Causes**:
- Sending agent logged activity without sufficient context
- Research findings not documented in Notion (only in agent memory)
- Assumption that receiving agent has access to previous conversation
- No explicit handoff checklist followed

**Resolution**:
```bash
# Step 1: Retrieve missing context
Task "Search Notion Research Hub for 'AI chatbot feasibility' and return full research findings"

# Step 2: Provide context to receiving agent
Task "@build-architect-v2, review research findings at [Research Hub URL]. Key recommendations: Technology stack: Azure Bot Service + OpenAI GPT-4. Architecture pattern: Conversational AI with product catalog integration. Budget: $8,000 development, $170/month operational. Build MVP focusing on product recommendations. Success criteria: Demo ready in 10 days."

# Step 3: Update Agent Activity Hub with complete context
Task "Update Notion Agent Activity Hub entry '[Handoff Entry URL]' with complete handoff context: [detailed summary]"

# Step 4: Resume build with full context
@build-architect-v2 "Proceed with chatbot build using provided research context"
```

**Handoff Best Practices** (Mandatory Checklist):
```yaml
Before Handing Off Work:

1. Document Deliverables:
   ✓ Create/update Notion entries (Research, Build, Idea)
   ✓ Upload artifacts (diagrams, code, reports)
   ✓ Link all related items (cross-reference for discoverability)

2. Summarize Key Findings:
   ✓ What was accomplished?
   ✓ What decisions were made? (with rationale)
   ✓ What challenges were encountered?
   ✓ What assumptions were validated/invalidated?

3. Define Next Steps:
   ✓ What should receiving agent do first?
   ✓ What are success criteria?
   ✓ What risks should they watch for?
   ✓ What timeline/deadline applies?

4. Provide References:
   ✓ Link to Notion pages (Research, Idea, Build)
   ✓ Link to external resources (docs, APIs, GitHub repos)
   ✓ Provide contact for questions (if human expertise needed)

5. Log Handoff Activity:
   ✓ Use /agent:log-activity with "Handed Off" status
   ✓ Include receiving agent name
   ✓ Attach complete context summary
   ✓ Set status to "Handed Off" (not "Completed")

# Example (good handoff):
/agent:log-activity @research-coordinator "Handed Off" "Completed AI chatbot feasibility research. Findings documented in Research Hub: [URL]. Recommended stack: Azure Bot Service + OpenAI GPT-4 (details in research). Budget validated: $8K dev, $170/mo ops. Next: @build-architect-v2 should design architecture, generate code, provision Azure resources. Success: Demo ready in 10 days. Risk: Timeline aggressive, prioritize MVP features. Files: research-summary.md, architecture-diagram.png. Contact Mitch for ML questions."
```

**Handoff Verification Protocol**:
```bash
# After logging handoff:
# 1. Receiving agent reviews handoff entry
# 2. Receiving agent verifies sufficient context:
#    - Can I start work immediately without questions? (Yes = good handoff)
#    - Do I understand success criteria? (Yes = good handoff)
#    - Do I have access to all referenced materials? (Yes = good handoff)
# 3. If any answer is No: Request clarification from sending agent or human

# Example verification:
Task "@build-architect-v2, review handoff from @research-coordinator in Agent Activity Hub entry '[URL]'. Confirm you have sufficient context to proceed or request clarifications."

# Expected response:
# "Handoff context is complete. I have:
#  ✓ Research findings with technology stack recommendation
#  ✓ Budget constraints ($8K dev, $170/mo ops)
#  ✓ Success criteria (demo in 10 days)
#  ✓ Architecture guidance (conversational AI + product catalog)
# Proceeding with architecture design."

# OR:
# "Handoff context missing:
#  ✗ Product catalog API documentation (need endpoint specs)
#  ✗ Customer requirements (what features required vs nice-to-have?)
# Requesting clarification before proceeding."
```

---

### Issue 10: Agent Resource Conflict - Multiple Agents Modifying Same File

**Symptoms**:
```bash
# Agent A working on file:
@markdown-expert "Updating onboarding documentation in .claude/docs/onboarding/05-azure-infrastructure.md"

# Simultaneously, Agent B:
@documentation-orchestrator "Refreshing all onboarding docs including .claude/docs/onboarding/05-azure-infrastructure.md"

# Result: Merge conflict, lost changes, or inconsistent file state
```

**Diagnosis**:
```bash
# Step 1: Check Agent Activity Hub for concurrent sessions
Task "Search Notion Agent Activity Hub for 'In Progress' status in last 1 hour"

# Expected: Lists all currently active agent sessions
# If multiple agents working on same file: Resource conflict

# Step 2: Check file modification history
git log --oneline --all -- .claude/docs/onboarding/05-azure-infrastructure.md

# Shows recent commits, identify which agent made which changes

# Step 3: Review for merge conflicts
git status
# If shows "both modified": Merge conflict exists
```

**Root Causes**:
- No coordination between agents (parallel work on shared resource)
- Agent Activity Hub not checked before starting work
- No file locking mechanism (multiple writers)
- Task delegation without explicit resource allocation

**Resolution**:
```bash
# Step 1: Identify primary agent (who started first or has more context)
# Check Agent Activity Hub timestamps:
Task "Fetch Notion Agent Activity Hub entries for @markdown-expert and @documentation-orchestrator, show start times"

# Primary: Earlier start time OR more domain-specific (markdown-expert > general orchestrator)

# Step 2: Pause secondary agent
Task "@documentation-orchestrator, pause work on 05-azure-infrastructure.md. @markdown-expert is currently editing this file. Wait for completion notification."

# Step 3: Allow primary agent to complete
@markdown-expert "Continue work on 05-azure-infrastructure.md. Notify when complete."

# Step 4: After primary completes, resume secondary agent
@markdown-expert "Completed updates to 05-azure-infrastructure.md. Committed changes."
Task "@documentation-orchestrator, @markdown-expert has completed edits to 05-azure-infrastructure.md. You may now proceed with your review/refresh."

# Step 5: Secondary agent incorporates primary's changes
@documentation-orchestrator "Review changes from @markdown-expert in 05-azure-infrastructure.md. Apply additional updates as needed, preserving @markdown-expert's work."
```

**Prevention (Resource Coordination Protocol)**:
```yaml
Before Starting Work on Shared Resources:

1. Check Agent Activity Hub:
   Task "Search Notion Agent Activity Hub for 'In Progress' status and resource '[file/database name]'"
   - If no matches: Proceed
   - If match found: Coordinate with active agent

2. Log Intent BEFORE Modifying:
   /agent:log-activity @agent-name "In Progress" "Starting work on [file/resource]. ETA: [minutes]."
   - Establishes claim on resource
   - Allows other agents to detect conflict proactively

3. Acquire Lock (Manual, for now):
   Task "Check if file [path] is currently being edited by another agent"
   - If yes: Wait or coordinate
   - If no: Proceed and log activity

4. Release Lock When Complete:
   /agent:log-activity @agent-name "Completed" "Finished work on [file/resource]. Resource available."

5. For Coordinated Multi-Agent Work:
   - Explicit handoff: Agent A completes, notifies Agent B
   - Sequential processing: Agent B waits for Agent A to log "Completed"
   - Parallel work on DIFFERENT resources only (never same file)

# Example (correct coordination):
# Agent A:
/agent:log-activity @markdown-expert "In Progress" "Updating 05-azure-infrastructure.md with Key Vault security section. ETA: 20 minutes."

# Agent B (checks before starting):
Task "Search Agent Activity Hub for 'In Progress' on '05-azure-infrastructure.md'"
# Finds Agent A's entry
Task "@documentation-orchestrator, wait for @markdown-expert to complete 05-azure-infrastructure.md (ETA 20 min) before starting documentation refresh. Work on other docs in meantime."
```

**Automated Conflict Detection** (Future Enhancement):
```bash
# Planned: Pre-commit hook checks for concurrent edits
# Before committing file:
#   1. Query Agent Activity Hub for other "In Progress" entries on same file
#   2. If found: Warn user of potential conflict
#   3. Prompt: "Another agent is editing this file. Proceed anyway? (y/n)"
#   4. If no: Abort commit, allow coordination
#   5. If yes: Proceed with merge conflict risk
```

---

## Cost Tracking Issues

### Issue 11: Software Not Appearing in Cost Tracker

**Symptoms**:
```bash
/autonomous:enable-idea "AI Chatbot"
# Build uses: Azure Bot Service, OpenAI API, Cosmos DB

# Check Software Tracker:
Task "Search Software Tracker for 'Azure Bot Service'"
# Result: Not found (should have been created automatically)

# Result: Total Cost rollup incorrect (missing $X/month)
```

**Diagnosis**:
```bash
# Step 1: Verify software should have been tracked
# Review build deliverables:
Task "Fetch Notion Example Builds entry for 'AI Chatbot' and show 'Technologies Used' property"

# Expected: Lists all technologies (Azure Bot Service, OpenAI API, Cosmos DB)

# Step 2: Check if Software Tracker entry exists but not linked
Task "Search Software Tracker for 'Bot Service' OR 'OpenAI' OR 'Cosmos'"

# If found: Software exists, just not linked to build (relation issue)
# If not found: Software never created (automation gap)

# Step 3: Check build automation logs
# Review agent activity logs for build creation:
Task "Search Agent Activity Hub for @deployment-orchestrator entries related to 'AI Chatbot'"

# Expected: Should show "Created Software Tracker entries for: Azure Bot Service, OpenAI API, Cosmos DB"
# If missing: Automation failed to create software entries
```

**Root Causes**:
- Build automation script didn't detect all dependencies
- Software already exists but with different name (e.g., "Azure Bot Framework" vs "Azure Bot Service")
- Software creation failed silently (error not surfaced)
- Manual build deployment (not via autonomous pipeline, software not auto-tracked)

**Resolution**:
```bash
# Step 1: Manually create missing Software Tracker entries

# For each missing software:
Task "Create Notion page in Software Tracker database with properties:
  Tool/Service Name: Azure Bot Service
  Category: Cloud Services
  Vendor: Microsoft
  Monthly Cost per License: $50
  License Count: 1
  Status: Active
  Renewal Date: Consumption-based (N/A)
  Used By: Innovation Nexus (team)
  Related Builds: [Link to 'AI Chatbot' build]
  Related Research: [Link if exists]
  Related Ideas: [Link to origin idea]
"

# Repeat for OpenAI API, Cosmos DB

# Step 2: Link software to Example Builds entry
Task "Update Notion Example Builds entry '[AI Chatbot URL]' property 'Software Used' to link to:
  - [Azure Bot Service page ID]
  - [OpenAI API page ID]
  - [Cosmos DB page ID]
"

# Step 3: Verify Total Cost rollup calculates
Task "Fetch Notion Example Builds entry '[AI Chatbot URL]' and show 'Total Cost' property"

# Expected: Shows sum of all linked software costs (e.g., $170/month)
```

**Prevention (Enhanced Automation)**:
```yaml
Autonomous Build Pipeline Enhancement:

1. Dependency Detection:
   - Parse package.json, requirements.txt, Gemfile for external services
   - Scan Bicep/Terraform for Azure resources
   - Detect API calls in code (e.g., fetch('https://api.openai.com/...'))

2. Software Tracker Auto-Creation:
   - For each dependency:
     a. Search Software Tracker for existing entry (fuzzy match)
     b. If exists: Link to build
     c. If not exists: Create new entry with estimated cost
     d. Log creation in Agent Activity Hub

3. Cost Estimation:
   - Query public pricing APIs (Azure Pricing API, AWS Price List API)
   - Use historical data from existing builds
   - Apply environment-based SKU selection (dev vs prod pricing)

4. Verification Step:
   - After build completion, generate cost summary
   - Compare to budget threshold ($X/month)
   - Alert if exceeds: "Build will cost $Y/month, budget is $X. Proceed? (y/n)"

5. Manual Review Trigger:
   - If ANY software not in Software Tracker: Flag for review
   - Email/Teams notification: "New software detected in build '[Name]': [List]. Please review and confirm costs."
```

**Manual Build Software Tracking Checklist**:
```yaml
# If deploying build manually (outside autonomous pipeline):

After Deployment:
  1. List all software/tools/services used
  2. For each, check Software Tracker:
     - Search for existing entry
     - If not found: Create new entry
  3. Link all software to Example Builds entry
  4. Verify Total Cost rollup calculates correctly
  5. Tag software with build name for easy filtering

# Example:
# Build: "Customer Portal v2"
# Software Used:
#   - Azure App Service (P1v3): $240/month [Already in Tracker, link it]
#   - SendGrid Email API: $20/month [Not in Tracker, create it]
#   - Twilio SMS: $15/month [Not in Tracker, create it]
# Total: $275/month
```

---

### Issue 12: Cost Rollup Shows Incorrect Total

**Symptoms**:
```bash
# Example Builds entry "AI Chatbot" has 3 software relations:
#   - Azure Bot Service: $50/month
#   - OpenAI API: $120/month
#   - Cosmos DB: $24/month
# Expected Total: $194/month

# Actual Total Cost shown: $50/month (only counting first entry)
```

**Diagnosis**:
```bash
# Step 1: Verify rollup formula configuration
Task "Fetch Notion database schema for Example Builds and show 'Total Cost' property definition"

# Expected formula:
# Property Type: Rollup
# Relation Property: Software Used
# Rollup Property: Monthly Cost per License
# Function: sum

# Check for issues:
#   - Relation Property: Should be "Software Used" (exact name match)
#   - Rollup Property: Should be "Monthly Cost per License" (not "Monthly Cost" or "Cost")
#   - Function: Should be "sum" (not "average", "count", etc.)

# Step 2: Verify software entries have costs populated
Task "Fetch Notion pages for all software linked to '[AI Chatbot]' and show 'Monthly Cost per License' property"

# Expected: Each should have numeric value >0
# If any show $0 or blank: Missing cost data (rollup correctly sums to lower total)

# Step 3: Check License Count multiplier
# Total Cost should be: sum(Monthly Cost per License × License Count)
# If formula only uses Monthly Cost per License: Missing multiplier

Task "Fetch Notion database schema for Example Builds and check if 'Total Cost' formula includes License Count"

# Correct formula (if accounting for license count):
# sum(Software Used.Monthly Cost per License × Software Used.License Count)
```

**Root Causes**:
- Rollup formula misconfigured (wrong property name, wrong function)
- Software entries missing cost data (blank or $0 Monthly Cost)
- Rollup formula not accounting for License Count (multiplier missing)
- Database schema changed (property renamed, rollup broken)

**Resolution**:
```bash
# Case 1: Rollup Formula Incorrect

# Fix formula:
Task "Update Notion database 'Example Builds' property 'Total Cost' with correct rollup:
  Relation Property: Software Used
  Rollup Property: Monthly Cost per License
  Function: sum
"

# Verify fix:
Task "Fetch Notion page '[AI Chatbot]' and show 'Total Cost' property"
# Expected: $194/month (sum of 3 software costs)

# Case 2: Software Entries Missing Costs

# Identify which software has blank cost:
Task "Fetch Notion pages for all software linked to '[AI Chatbot]' and show 'Monthly Cost per License' property"

# For each blank entry, update cost:
Task "Update Notion Software Tracker entry '[Azure Bot Service]' property 'Monthly Cost per License' to $50"

# Verify rollup recalculates:
Task "Fetch Notion page '[AI Chatbot]' and show 'Total Cost' property"
# Expected: $194/month (after all costs populated)

# Case 3: License Count Not Accounted For

# If build uses 5 OpenAI API licenses ($120 each):
# Current formula: sum(Monthly Cost) = $120 (incorrect)
# Correct formula: sum(Monthly Cost × License Count) = $600

# Update formula to include License Count:
Task "Update Notion database 'Example Builds' property 'Total Cost' with formula:
  sum(Software Used.Monthly Cost per License × Software Used.License Count)
"

# Note: This requires Notion to support calculated rollups (may need workaround)
# Workaround: Create intermediate property "Total Cost Per Software" = Monthly Cost × License Count
# Then rollup: sum(Software Used.Total Cost Per Software)
```

**Rollup Formula Best Practices**:
```yaml
Notion Rollup Configuration:

1. Use Consistent Property Names:
   - Monthly Cost per License (not "Cost", "Monthly Cost", "Price")
   - License Count (not "Licenses", "Quantity", "Count")
   - Reduces formula breakage due to typos

2. Validate Rollup After Creation:
   - Create test entry with known software costs
   - Verify rollup calculates correctly
   - If incorrect: Debug formula before deploying

3. Document Formula Logic:
   - Add description to Total Cost property explaining formula
   - Example: "Rollup: sum(Monthly Cost per License × License Count) from Software Used relation"
   - Helps troubleshooting when formula breaks

4. Handle Missing Data Gracefully:
   - If Monthly Cost blank: Rollup treats as $0 (acceptable)
   - If License Count blank: Rollup treats as 0 (may want default to 1)
   - Solution: Set default License Count = 1 in database

5. Test Edge Cases:
   - No software linked: Rollup should show $0 (not error)
   - 100+ software linked: Rollup should handle large sums
   - Software with $0 cost (free tier): Should count as $0, not error
```

---

## Repository Operations Issues

### Issue 13: GitHub API Rate Limit Exceeded

**Symptoms**:
```bash
/repo:scan-org --deep
# Scans 5 repositories successfully
# On 6th repository:
# Error: 403 Forbidden - API rate limit exceeded for user
# Remaining: 0/5000 requests, resets in 45 minutes
```

**Diagnosis**:
```bash
# Check GitHub API rate limit status
curl -H "Authorization: Bearer $env:GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/rate_limit

# Expected output:
{
  "resources": {
    "core": {
      "limit": 5000,
      "remaining": 0,
      "reset": 1698264000,  # Unix timestamp (next hour)
      "used": 5000
    }
  }
}

# If remaining = 0: Rate limit exceeded
# Reset time: When quota refreshes (top of next hour for OAuth, rolling 1 hour for PAT)
```

**Root Causes**:
- Repository scan made too many API calls (not using GraphQL for bulk queries)
- Multiple concurrent scans (parallel agents querying GitHub)
- No caching of repository metadata (redundant API calls)
- Deep analysis flag (`--deep`) increased API call volume 10x

**Resolution**:
```bash
# Immediate: Wait for Rate Limit Reset

# Check reset time:
curl -H "Authorization: Bearer $env:GITHUB_PERSONAL_ACCESS_TOKEN" https://api.github.com/rate_limit | jq '.resources.core.reset'

# Convert timestamp to readable time:
date -d @1698264000  # Linux/macOS
# OR
[DateTimeOffset]::FromUnixTimeSeconds(1698264000).DateTime  # PowerShell

# Wait until reset time, then retry:
/repo:scan-org --deep --resume-from brookside-bi/repo-6

# Medium-Term: Optimize API Usage

# 1. Use GraphQL instead of REST API (80% fewer calls)
# Example: Get repo + latest commit + open issues (1 GraphQL call vs 3 REST calls)

# 2. Implement caching (60-80% reduction)
# Cache repository metadata for 1 hour
# Only re-query if cache expired or data stale

# 3. Batch operations
# Scan 5 repos, pause 10 seconds, scan next 5
# Spreads API calls over time, reduces burst

# 4. Disable --deep flag unless necessary
# Standard scan: ~20 API calls per repo
# Deep scan: ~200 API calls per repo
# Use deep scan only for critical repositories
```

**Prevention (Rate Limit Management)**:
```yaml
GitHub API Best Practices:

1. Monitor Rate Limit Proactively:
   - Check remaining quota before large operations
   - If remaining <1000: Wait until reset
   - Alert if quota depleted >3 times per day (systemic issue)

2. Use GraphQL for Bulk Queries:
   - REST API: 1 call per resource (inefficient)
   - GraphQL: 1 call for multiple resources (efficient)
   - Example: Fetch 20 repos + commits + issues = 1 GraphQL call vs 60 REST calls

3. Cache Frequently Accessed Data:
   - Repository metadata (name, description, URL): 24 hours TTL
   - Latest commit SHA: 1 hour TTL
   - Branch list: 1 hour TTL
   - Reduces redundant API calls by 70-90%

4. Implement Exponential Backoff:
   - If rate limit hit: Wait 1 second, retry
   - If still limited: Wait 2 seconds, retry
   - Max wait: 60 seconds (then abort, wait for reset)

5. Distribute Load:
   - Scan repositories sequentially (not parallel)
   - Add 1-second delay between repositories
   - Spread large scans over multiple hours

6. Use Conditional Requests (Advanced):
   - Include `If-None-Match: "<etag>"` header
   - If data unchanged: Returns 304 (doesn't count against quota)
   - Saves quota for frequently polled resources

7. Consider GitHub Apps (Future):
   - Higher rate limit: 15,000 requests/hour (vs 5,000 for PAT)
   - Better for organization-wide automation
   - Requires infrastructure to host app
```

**Caching Implementation Example**:
```typescript
// Simple in-memory cache with TTL
const cache = new Map<string, {data: any, expires: number}>();

async function getRepository(owner: string, repo: string): Promise<Repository> {
  const cacheKey = `${owner}/${repo}`;
  const cached = cache.get(cacheKey);

  // Check if cached and not expired
  if (cached && cached.expires > Date.now()) {
    console.log(`Cache hit: ${cacheKey}`);
    return cached.data;
  }

  // Cache miss or expired: Fetch from GitHub API
  console.log(`Cache miss: ${cacheKey}, fetching from API`);
  const data = await github.repos.get({owner, repo});

  // Cache for 1 hour
  cache.set(cacheKey, {
    data: data.data,
    expires: Date.now() + 3600000  // 1 hour in ms
  });

  return data.data;
}

// Result: 80% reduction in GitHub API calls for repeated queries
```

---

## Performance Optimization

### Issue 14: Notion Database Queries Slow (>5 seconds)

**Symptoms**:
```bash
Task "Search Notion Ideas Registry for 'cost optimization'"
# Takes 8-12 seconds to return results (expected: <2 seconds)
```

**Diagnosis**:
```bash
# Step 1: Measure baseline query performance
# Time simple query:
time Task "Search Notion Ideas Registry for 'test'"

# Expected: <2 seconds for small databases (<1000 pages)
# If >5 seconds: Performance issue

# Step 2: Check database size
Task "Count pages in Ideas Registry database"

# If >5,000 pages: Large database (slower queries expected)
# If <1,000 pages: Should be fast (investigate other causes)

# Step 3: Check Notion API status
# Visit: https://status.notion.so/
# If degraded performance reported: Notion-side issue (wait for resolution)
# If operational: Issue is query-specific or network-related
```

**Root Causes**:
- Notion database has >5,000 pages (query scans all pages)
- Complex filter query (multiple AND/OR conditions)
- Network latency (slow internet connection)
- Notion API experiencing degraded performance
- No indexing on searched properties (Notion doesn't expose indexes)

**Resolution**:
```bash
# Short-Term: Optimize Query

# Instead of broad search:
Task "Search Notion Ideas Registry for 'cost optimization platform AI chatbot recommendation engine'"

# Use targeted search with fewer keywords:
Task "Search Notion Ideas Registry for 'cost optimization AI'"

# Benefits:
# - Fewer keywords = faster indexing lookup
# - More focused results (less post-processing)

# Medium-Term: Implement Caching

# Cache frequently searched queries:
# Query: "Search Ideas Registry for 'cost optimization'"
# Cache result for 15 minutes
# Subsequent searches return cached results (instant)

# Long-Term: Database Partitioning

# If Ideas Registry >10,000 pages:
# Consider splitting into multiple databases:
#   - Ideas Registry 2024 (archived)
#   - Ideas Registry 2025 (active)
#   - Ideas Registry 2026 (future)

# Benefits:
# - Smaller databases = faster queries
# - Archived ideas separated from active work
# - Reduced clutter in active database

# Query both databases when full search needed:
Task "Search Notion 'Ideas Registry 2024' AND 'Ideas Registry 2025' for 'cost optimization'"
```

**Performance Optimization Strategies**:
```yaml
Notion Query Optimization:

1. Limit Result Count:
   - Default: Notion returns all matching pages (can be 1000+)
   - Optimized: Request top 10-20 results only
   - Example: "Search Ideas Registry for 'cost', limit 10 results"
   - Benefits: 80% faster for large result sets

2. Use Specific Filters:
   - Broad: Search all properties for 'cost'
   - Specific: Search only 'Title' property for 'cost'
   - Benefits: 50% faster (narrower index scan)

3. Leverage Notion Views:
   - Create filtered view: "Active Ideas Only" (Status = Active)
   - Query view instead of entire database
   - Benefits: Pre-filtered results, faster queries

4. Implement Client-Side Caching:
   - Cache query results for 5-15 minutes
   - Invalidate cache on database updates (webhook or polling)
   - Benefits: 95% faster for repeated queries

5. Batch Queries:
   - Instead of 10 individual searches:
     - Search for "cost" → 100 results
     - Filter client-side for specific keywords
   - Benefits: 90% fewer API calls, faster overall

6. Use Notion Search Operators (Future):
   - Currently limited support for operators
   - Planned: Boolean operators (AND, OR, NOT), exact match ("")
   - Benefits: More precise queries, less post-processing

7. Monitor Notion Status:
   - Subscribe to https://status.notion.so/ for outage notifications
   - If degraded performance: Delay non-urgent queries
   - Benefits: Avoid retry loops during Notion incidents
```

**Caching Implementation**:
```typescript
// Query cache with TTL
const queryCache = new Map<string, {results: any[], expires: number}>();
const CACHE_TTL = 15 * 60 * 1000;  // 15 minutes

async function searchNotion(database: string, query: string): Promise<any[]> {
  const cacheKey = `${database}:${query}`;
  const cached = queryCache.get(cacheKey);

  if (cached && cached.expires > Date.now()) {
    console.log(`Cache hit: ${cacheKey}`);
    return cached.results;
  }

  console.log(`Cache miss: ${cacheKey}, querying Notion API`);
  const results = await notionClient.databases.query({
    database_id: database,
    filter: {
      property: "Title",
      rich_text: {
        contains: query
      }
    }
  });

  queryCache.set(cacheKey, {
    results: results.results,
    expires: Date.now() + CACHE_TTL
  });

  return results.results;
}

// Result: Sub-second response for cached queries (vs 5-8 seconds uncached)
```

---

## Emergency Contacts

### Critical Issue Escalation Matrix

**Infrastructure Issues** (Azure, Key Vault, deployments):
- **Primary Contact**: Alec Fielding
- **Email**: alec@brooksidebi.com
- **Teams**: @Alec Fielding
- **Response Time**: 2 hours (business hours), 4 hours (after hours)
- **Escalation**: Markus Ahling (if no response after 4 hours)

**Authentication Issues** (Azure AD, MCP servers, OAuth):
- **Primary Contact**: Alec Fielding
- **Secondary Contact**: Markus Ahling
- **For Notion OAuth**: Brad Wright (workspace admin)
- **Response Time**: 1 hour (critical access blocking work)

**Notion Integration Issues** (database schema, permissions, API):
- **Primary Contact**: Markus Ahling
- **Email**: markus@brooksidebi.com
- **Teams**: @Markus Ahling
- **Response Time**: 3 hours (business hours)
- **Escalation**: Brad Wright (workspace-level permissions)

**Cost Tracking Issues** (Software Tracker, budget alerts):
- **Primary Contact**: Brad Wright (business owner)
- **Technical Support**: Markus Ahling
- **Response Time**: 1 business day (non-urgent), 4 hours (budget exceeded)

**Agent System Issues** (delegation failures, activity logging):
- **Primary Contact**: Markus Ahling
- **Response Time**: 4 hours (business hours)
- **Workaround**: Manual completion, document issue for later fix

**Repository Operations Issues** (GitHub, CI/CD, deployments):
- **Primary Contact**: Alec Fielding (DevOps)
- **Secondary Contact**: Mitch Bisbee (code quality)
- **Response Time**: 2 hours (broken builds), 1 business day (enhancements)

**Data Issues** (corrupted Notion data, lost work):
- **Primary Contact**: Markus Ahling
- **Backup Recovery**: Contact Notion support (workspace admin: Brad Wright)
- **Response Time**: Immediate (data loss), 4 hours (data corruption)

### Emergency Procedures

**Scenario: Production Build Deployment Failed, Customer Demo in 2 Hours**

```yaml
Step 1: Assess Impact (5 minutes)
  - Is production down? (customer-facing)
  - Is staging down? (internal demo OK?)
  - Is dev down? (not critical)

Step 2: Immediate Triage (10 minutes)
  - Check Azure Portal for resource health
  - Review GitHub Actions logs for failure point
  - Check Agent Activity Hub for deployment logs

Step 3: Escalate (if not resolved in 15 minutes)
  - Contact: Alec Fielding (Teams direct message + phone call)
  - Provide: Build name, error message, Azure resource IDs, urgency (demo in 2 hours)

Step 4: Parallel Workarounds
  - Option A: Rollback to previous working deployment
    az webapp deployment slot swap --slot staging --name [app-name] --resource-group [rg-name]
  - Option B: Use staging environment for demo (if staging works)
  - Option C: Record demo video from working dev environment

Step 5: Post-Incident Review (after demo)
  - Document root cause in Knowledge Vault
  - Update deployment procedures to prevent recurrence
  - Consider additional safeguards (pre-deployment smoke tests)
```

**Scenario: All MCP Servers Disconnected, Cannot Proceed with Work**

```yaml
Step 1: Quick Diagnostics (2 minutes)
  - Run: claude mcp list
  - Identify which servers disconnected (all or specific)

Step 2: Self-Service Resolution (5 minutes)
  - Re-authenticate: az login
  - Reconfigure environment: .\scripts\Set-MCPEnvironment.ps1
  - Restart Claude Code: close and relaunch

Step 3: If Still Disconnected (escalate)
  - Contact: Markus Ahling (MCP configuration expert)
  - Provide: Output of `claude mcp list`, error messages, recent changes

Step 4: Temporary Workaround
  - Manual Notion operations: Use Notion web UI directly
  - Manual GitHub operations: Use GitHub web UI or git CLI
  - Manual Azure operations: Use Azure Portal or Azure CLI

Step 5: Document Issue
  - Log in Agent Activity Hub: "Blocked - MCP servers disconnected"
  - Include troubleshooting steps attempted
  - Note workarounds used to continue progress
```

---

## Additional Resources

**Troubleshooting Documentation**:
- **Azure MCP Health Check Script**: `.claude/utils/mcp-health.ps1`
- **Notion Query Examples**: `.claude/utils/notion-queries.ps1`
- **Repository Analyzer Docs**: `brookside-repo-analyzer/docs/TROUBLESHOOTING.md`
- **Agent Activity Logging**: `.claude/docs/agent-activity-center.md`

**External Documentation**:
- **Notion API**: https://developers.notion.com/
- **GitHub API**: https://docs.github.com/en/rest
- **Azure CLI**: https://learn.microsoft.com/en-us/cli/azure/
- **Playwright**: https://playwright.dev/docs/intro

**Internal Knowledge Base**:
- **Common Workflows**: `.claude/docs/onboarding/07-common-workflows.md`
- **Database Architecture**: `.claude/docs/onboarding/03-database-architecture.md`
- **MCP Server Setup**: `.claude/docs/onboarding/06-mcp-server-setup.md`
- **Azure Infrastructure**: `.claude/docs/onboarding/05-azure-infrastructure-setup.md`

---

## Feedback and Improvements

**Encountered an issue not covered here?**

1. Document the issue in Knowledge Vault:
   ```bash
   Task "Create Knowledge Vault entry: 'Troubleshooting: [Issue Title]' with symptoms, diagnosis, resolution, and prevention steps"
   ```

2. Submit improvement suggestion:
   ```bash
   /innovation:new-idea "Add troubleshooting guidance for [specific issue] to onboarding documentation"
   ```

3. Update this guide directly:
   ```bash
   # Add new issue section following existing format
   # Submit PR to main branch with tag "Documentation Enhancement"
   ```

**This troubleshooting guide improves through team contributions. Share your solutions to help the entire team.**

---

**Document Information**:
- **Last Updated**: October 26, 2025
- **Maintained By**: Markus Ahling (Primary), Alec Fielding (Infrastructure), Brad Wright (Business)
- **Review Schedule**: Quarterly (issue trends), As-needed (critical gaps)
- **Feedback**: Submit improvements to Innovation Nexus Ideas Registry with tag "Troubleshooting Enhancement"
