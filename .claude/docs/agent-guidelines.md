# Agent Guidelines

**Purpose**: Establish comprehensive guidelines for Claude Code agents operating within the Innovation Nexus environment.

**Best for**: Agents executing operations, understanding best practices, and maintaining consistency across workflows.

---

## Core Principles

### 1. Notion = Source of Truth
- All innovation tracking lives in Notion databases
- Always search Notion before creating new entries
- Maintain accurate relations between databases
- Update status fields promptly

### 2. Azure Key Vault = Secret Hub
- All credentials centralized in Key Vault
- Never hardcode secrets in code or documentation
- Use retrieval scripts for secret access
- Reference Key Vault locations in docs

### 3. Cost Tracking = Critical
- Every build/research MUST link all software used
- Software Tracker is central hub (all databases link TO it)
- Maintain accurate cost rollups
- Track license counts and renewal dates

### 4. Microsoft-First Approach
- Check M365 → Azure → Power Platform → GitHub before third-party
- Prioritize Microsoft ecosystem for cost optimization
- Document Microsoft alternatives for third-party tools

### 5. Status > Timelines
- Focus on viability and progress, not deadlines
- Use status emojis consistently (🔵 🟢 ⚫ ✅)
- Avoid timeline language ("due date", "by Friday", "1-2 weeks")
- Emphasize current state and next actions

### 6. Archive Liberally
- Every completed build becomes reference material
- Document lessons learned in Knowledge Vault
- Preserve context and lineage (Idea → Research → Build → Knowledge)

### 7. AI-Agent Friendly Documentation
- All docs must be executable by future AI agents
- Explicit instructions without human interpretation
- Idempotent operations (safe to repeat)
- Versioned with timestamps

---

## Automated Integration Patterns

### When Creating Example Builds

**Always Execute These Steps**:

1. **Create GitHub Repository**
   ```typescript
   // Use GitHub MCP
   const repo = await createRepository({
     name: projectName,
     description: projectDescription,
     private: false,
     autoInit: true
   });
   ```

2. **Link Repo to Notion Build**
   ```typescript
   await updatePage({
     page_id: buildPageId,
     properties: {
       "Repository URL": repo.html_url
     }
   });
   ```

3. **Track ALL Software/Tools**
   ```typescript
   // Link to Software Tracker for cost rollup
   await updatePage({
     page_id: buildPageId,
     properties: {
       "Software & Tools": [
         { id: azureFunctionsId },
         { id: azureOpenAIId },
         { id: appInsightsId }
         // ... all tools used
       ]
     }
   });
   ```

4. **Generate Technical Documentation**
   ```typescript
   // Use @markdown-expert for AI-agent-friendly docs
   await generateTechnicalDocs({
     build: buildDetails,
     outputPath: `${repoPath}/TECHNICAL.md`,
     format: "ai-agent-executable"
   });
   ```

5. **Deploy to Azure (if applicable)**
   ```typescript
   // Use Azure MCP or @deployment-orchestrator
   await deployToAzure({
     resourceGroup: `rg-${projectName}-${environment}`,
     template: bicepTemplate,
     parameters: deploymentParams
   });
   ```

6. **Register in Integration Registry**
   ```typescript
   // If external integrations exist
   await createIntegrationEntry({
     buildId: buildPageId,
     integrationType: "GitHub", // or Azure, etc.
     connectionDetails: integrationConfig
   });
   ```

---

### When Starting Research

**Always Execute These Steps**:

1. **Create Research Hub Entry**
   ```typescript
   const researchPage = await createPage({
     parent: { data_source_id: RESEARCH_HUB_ID },
     properties: {
       "Research Topic": topicName,
       "Origin Idea": [{ id: ideaPageId }],  // Required
       "Status": "Active",
       "Research Type": "Feasibility Study"
     }
   });
   ```

2. **Link to Originating Idea**
   ```typescript
   // REQUIRED - maintain lineage
   // Already done in step 1 properties
   ```

3. **Track Research Tools**
   ```typescript
   // Link all software used during research
   await updatePage({
     page_id: researchPageId,
     properties: {
       "Software Used": [
         { id: azureOpenAIId },  // If using AI for analysis
         { id: notionId },       // Research documentation
         // ... other tools
       ]
     }
   });
   ```

4. **Invoke Research Swarm** (for comprehensive research)
   ```typescript
   // Parallel execution
   await Promise.all([
     invokeAgent("@market-researcher", { topic, context }),
     invokeAgent("@technical-analyst", { topic, context }),
     invokeAgent("@cost-feasibility-analyst", { topic, context }),
     invokeAgent("@risk-assessor", { topic, context })
   ]);
   ```

5. **Document Findings**
   ```typescript
   await updatePage({
     page_id: researchPageId,
     command: "update_properties",
     properties: {
       "Key Findings": aggregatedFindings,
       "Viability Score": overallScore,  // 0-100
       "Next Steps": recommendation       // Build | More Research | Archive
     }
   });
   ```

6. **Archive for Knowledge Vault** (when complete)
   ```typescript
   // Use @knowledge-curator
   await archiveResearch({
     researchId: researchPageId,
     contentType: "Case Study",
     reusability: "Evergreen"
   });
   ```

---

### When Managing Costs

**Always Execute These Steps**:

1. **Query Software Tracker**
   ```typescript
   // Use Notion MCP
   const software = await notionSearch({
     data_source_url: `collection://${SOFTWARE_TRACKER_ID}`,
     query: ""  // All software
   });
   ```

2. **Calculate Rollups from Relations**
   ```typescript
   // Verify cost rollups are accurate
   const totalCost = software.reduce((sum, item) => {
     return sum + (item.monthlyCost * item.licenseCount);
   }, 0);
   ```

3. **Identify Unused Tools**
   ```typescript
   // Status = Active BUT no relations
   const unused = software.filter(s =>
     s.status === "Active" &&
     s.usedInIdeas.length === 0 &&
     s.usedInResearch.length === 0 &&
     s.usedInBuilds.length === 0
   );
   ```

4. **Check Contract Expiration**
   ```typescript
   // Within 60 days
   const expiring = software.filter(s => {
     const daysUntilExpiry = calculateDays(s.contractEndDate, today);
     return daysUntilExpiry > 0 && daysUntilExpiry <= 60;
   });
   ```

5. **Suggest Microsoft Alternatives**
   ```typescript
   // For third-party tools
   await analyzeMicrosoftAlternatives({
     currentTools: thirdPartyTools,
     criteria: ["cost", "features", "integration"]
   });
   ```

---

## Performance Optimization

### MCP Server Usage Best Practices

#### Notion MCP
**✅ DO**:
- Cache database schemas (fetch once per session)
- Reuse relation IDs across operations
- Batch search queries (broad query + local filtering)
- Use data source IDs instead of searching by name

**❌ DON'T**:
- Fetch same database schema repeatedly
- Search for same item multiple times
- Make narrow searches when broad search works
- Query by name when ID is available

**Example**:
```typescript
// ✅ Correct - cache and reuse
const schema = await fetchDatabase(IDEAS_REGISTRY_ID);
for (const idea of newIdeas) {
  await createPage({ schema, ...idea });
}

// ❌ Wrong - fetch every iteration
for (const idea of newIdeas) {
  const schema = await fetchDatabase(IDEAS_REGISTRY_ID);
  await createPage({ schema, ...idea });
}
```

#### GitHub MCP
**✅ DO**:
- Use `push_files` for multiple files (single commit)
- Batch operations when possible
- Cache repository metadata

**❌ DON'T**:
- Use `create_or_update_file` repeatedly
- Make multiple commits for related changes
- Query same repository info multiple times

**Example**:
```typescript
// ✅ Correct - single commit
await pushFiles({
  files: [file1, file2, file3, file4, file5]
});

// ❌ Wrong - multiple commits
await createOrUpdateFile({ path: "file1.py", content: "..." });
await createOrUpdateFile({ path: "file2.py", content: "..." });
```

#### Azure MCP
**✅ DO**:
- Verify `az account show` before operations
- Cache resource lists and filter locally
- Use resource IDs instead of names when possible

**❌ DON'T**:
- Re-authenticate repeatedly (tokens last 24 hours)
- Query resources individually when batch query works
- Make redundant API calls

#### Playwright MCP
**✅ DO**:
- Reuse browser sessions for multi-step workflows
- Use snapshots instead of multiple screenshots
- Close browser when done

**❌ DON'T**:
- Open/close browser for each operation
- Take screenshots when snapshot sufficient

---

## Security Best Practices

### Credential Handling

#### ✅ DO: Use Key Vault
```powershell
# Retrieve secrets via script
$pat = .\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token" -AsPlainText

# Use in operations
gh auth login --with-token <<< $pat
```

#### ✅ DO: Reference Key Vault in Docs
```markdown
## Authentication
This integration requires a GitHub Personal Access Token.

**Secret Location**: Azure Key Vault `kv-brookside-secrets` → `github-personal-access-token`

**Retrieve via**:
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "github-personal-access-token"
```
```

#### ✅ DO: Use Environment Variables
```typescript
// Correct - references environment variable
const apiKey = process.env.AZURE_OPENAI_API_KEY;
```

#### ✅ DO: Use Managed Identity
```typescript
// Preferred approach
import { DefaultAzureCredential } from "@azure/identity";
const credential = new DefaultAzureCredential();
const client = new SecretClient(vaultUrl, credential);
```

#### ❌ DON'T: Display Secret Values
```typescript
// Wrong - exposes secret in logs
console.log(`Using API key: ${apiKey}`);

// Correct - masks sensitive data
console.log(`Using API key: ${apiKey.substring(0, 4)}...`);
```

#### ❌ DON'T: Commit Secrets to Git
```bash
# Wrong - hardcoded in code
const connectionString = "Server=tcp:sql.database.windows.net..."

# Correct - environment variable
const connectionString = process.env.SQL_CONNECTION_STRING;
```

**Protection**: Repository hooks detect 15+ secret patterns and block commits

#### ❌ DON'T: Hardcode in Documentation
```markdown
<!-- Wrong -->
API Key: sk-proj-abc123def456...

<!-- Correct -->
API Key: Stored in Azure Key Vault `kv-brookside-secrets` → `service-api-key`
```

---

## Brookside BI Brand Voice

### Apply to ALL Outputs

**Code Comments**:
```typescript
// ❌ Wrong
// Initialize database connection

// ✅ Correct
// Establish scalable data access layer to support multi-team operations
```

**Commit Messages**:
```bash
# ❌ Wrong
feat: add caching layer

# ✅ Correct
feat: Streamline data retrieval with distributed caching for improved performance
```

**Documentation Headers**:
```markdown
<!-- ❌ Wrong -->
# User Authentication
This module handles user login.

<!-- ✅ Correct -->
# User Authentication

Establish secure access control to protect sensitive data across your business environment.

**Best for**: Organizations requiring multi-tenant authentication with role-based access
```

**Agent Responses**:
```markdown
<!-- ❌ Wrong -->
I'll run the tests now.

<!-- ✅ Correct -->
I'll validate the implementation to ensure reliable performance across your environment.
```

**Key Patterns to Use**:
- "Establish structure and rules for..."
- "This solution is designed to..."
- "Organizations scaling [technology] across..."
- "Streamline workflows and improve visibility"
- "Drive measurable outcomes through..."
- "Best for: [clear use case context]"

---

## Validation Checklist

### Before Creating ANY Notion Entry

- ✅ Searched for duplicates (no exact matches found)
- ✅ Identified all required relations (Idea → Research → Build → Software)
- ✅ Fetched related items to understand current state
- ✅ Using correct data source ID for database
- ✅ Using exact property names from schema
- ✅ Proposed action to user (described what will be created)

### After Creating Notion Entry

- ✅ All relations are established correctly
- ✅ Rollup formulas calculate as expected
- ✅ Status fields are accurate
- ✅ Cost tracking is reflected (if applicable)
- ✅ Applied Brookside BI brand voice to content

### Before Any Azure Deployment

- ✅ Authenticated to Azure CLI (`az account show`)
- ✅ Using environment-based SKU selection (dev vs. prod)
- ✅ Managed Identity enabled (no hardcoded secrets)
- ✅ Key Vault integration configured
- ✅ Bicep template follows best practices
- ✅ Cost optimization applied

### Before Committing to Git

- ✅ No secrets or credentials in code/docs
- ✅ Commit message follows Conventional Commits
- ✅ Brookside BI brand voice in commit message
- ✅ All tests pass (if applicable)
- ✅ Pre-commit hooks satisfied

---

## Related Resources

**Core Documentation**:
- [Innovation Workflow](./innovation-workflow.md)
- [Notion Schema](./notion-schema.md)
- [Azure Infrastructure](./azure-infrastructure.md)
- [MCP Configuration](./mcp-configuration.md)

**Operational Guides**:
- [Common Workflows](./common-workflows.md)
- [Team Structure](./team-structure.md)
- [Success Metrics](./success-metrics.md)

---

**Last Updated**: 2025-10-26
