# /dsp:sync-notion - Bidirectional GitHub-Notion Synchronization

**Purpose**: Establish automated bidirectional synchronization between DSP Command Central GitHub repository documentation and Notion DSP Command Center database, ensuring single source of truth across platforms.

**Best for**: Documentation consistency, agent activity tracking, and stakeholder visibility into technical progress without requiring GitHub access.

---

## Command Syntax

```bash
/dsp:sync-notion [--direction <github-to-notion|notion-to-github|bidirectional>] [--scope <docs|activity|builds|all>] [--dry-run]
```

### Options

- `--direction`: Synchronization direction (default: bidirectional)
  - `github-to-notion`: One-way sync from GitHub → Notion
  - `notion-to-github`: One-way sync from Notion → GitHub
  - `bidirectional`: Two-way sync with conflict detection

- `--scope`: Content scope to synchronize (default: all)
  - `docs`: Documentation files only (README.md, /docs/, ADRs)
  - `activity`: Agent activity logs and session tracking
  - `builds`: Build documentation and deployment records
  - `all`: Complete synchronization across all content types

- `--dry-run`: Preview changes without executing (validation mode)

---

## Execution Workflow

When this command is invoked, perform the following steps in sequence:

### Phase 1: Notion Database Verification (1 minute)

1. **Validate DSP Command Center Database**
   - Verify database page ID: `[TO BE CREATED]`
   - Confirm data source (collection) ID exists
   - Check required properties exist (see schema below)
   - Validate MCP server connectivity

2. **Required Database Schema**
   ```
   DSP Command Center Properties:
   - Title (title) - Document/page name
   - Type (select) - [Documentation, Agent Activity, Build Record, ADR]
   - Status (select) - [Draft, In Progress, Completed, Archived]
   - Last Synced (date) - Timestamp of last GitHub sync
   - GitHub Path (url) - Source file path in repository
   - Assigned Agent (relation) - Link to Agent Registry
   - Related Build (relation) - Link to Example Builds (if applicable)
   - Content Hash (text) - MD5 hash for change detection
   - Sync Direction (select) - [GitHub→Notion, Notion→GitHub, Conflict]
   ```

3. **Execute Verification**
   ```powershell
   # Verify Notion MCP connectivity
   $notionTest = notion-search --query "DSP Command Center" --query-type internal

   # Validate database structure
   $database = notion-fetch --id "[DATABASE_ID]"

   # Check for required properties
   $requiredProps = @('Title', 'Type', 'Status', 'Last Synced', 'GitHub Path', 'Content Hash')
   foreach ($prop in $requiredProps) {
       if (-not $database.properties.ContainsKey($prop)) {
           Write-Error "Missing required property: $prop"
           exit 1
       }
   }
   ```

**Expected Output**: ✅ DSP Command Center database validated with all required properties

---

### Phase 2: Change Detection & Conflict Analysis (2-3 minutes)

1. **Scan GitHub Repository for Changes**
   ```bash
   cd dsp-command-central

   # Get all documentation files modified since last sync
   git log --since="$(cat .last-notion-sync)" --name-only --pretty=format: \
       | grep -E '(README\.md|docs/.*\.md|\.claude/agents/dsp-.*\.md|ADR-.*\.md)' \
       | sort -u > /tmp/github-changes.txt

   # Calculate content hashes for changed files
   while IFS= read -r file; do
       if [ -f "$file" ]; then
           hash=$(md5sum "$file" | cut -d' ' -f1)
           echo "$file|$hash" >> /tmp/github-hashes.txt
       fi
   done < /tmp/github-changes.txt
   ```

2. **Query Notion for Corresponding Pages**
   ```typescript
   /**
    * Establish change detection by comparing content hashes between GitHub and Notion.
    * Identifies conflicts where both platforms have modifications since last sync.
    */
   interface SyncConflict {
       githubPath: string;
       githubHash: string;
       githubModified: Date;
       notionPageId: string;
       notionHash: string;
       notionModified: Date;
       conflictType: 'github-newer' | 'notion-newer' | 'both-modified';
   }

   async function detectConflicts(): Promise<SyncConflict[]> {
       const conflicts: SyncConflict[] = [];

       // Read GitHub changes
       const githubChanges = fs.readFileSync('/tmp/github-hashes.txt', 'utf-8')
           .split('\n')
           .filter(line => line.trim())
           .map(line => {
               const [path, hash] = line.split('|');
               return { path, hash };
           });

       // Query Notion for matching pages
       for (const change of githubChanges) {
           const notionPage = await prisma.execute(`
               SELECT page_id, content_hash, last_modified
               FROM dsp_command_center
               WHERE github_path = '${change.path}'
           `);

           if (notionPage && notionPage.content_hash !== change.hash) {
               const githubStat = fs.statSync(change.path);

               conflicts.push({
                   githubPath: change.path,
                   githubHash: change.hash,
                   githubModified: githubStat.mtime,
                   notionPageId: notionPage.page_id,
                   notionHash: notionPage.content_hash,
                   notionModified: new Date(notionPage.last_modified),
                   conflictType: determineConflictType(githubStat.mtime, notionPage.last_modified)
               });
           }
       }

       return conflicts;
   }
   ```

3. **Conflict Resolution Strategy**
   - **GitHub Newer**: Overwrite Notion with GitHub content
   - **Notion Newer**: Overwrite GitHub with Notion content (requires approval)
   - **Both Modified**: Create conflict marker and require manual resolution

**Expected Output**: Conflict report with recommended resolution actions

---

### Phase 3: GitHub → Notion Synchronization (3-5 minutes)

**Skip if `--direction notion-to-github` specified**

1. **Engage @documentation-sync Agent**
   - Convert markdown files to Notion-flavored markdown
   - Preserve code blocks, callouts, and formatting
   - Extract metadata from frontmatter (if exists)
   - Generate table of contents for long documents

2. **Sync Documentation Files**
   ```typescript
   /**
    * Establish GitHub documentation synchronization to Notion DSP Command Center.
    * Converts markdown to Notion blocks while preserving technical formatting.
    *
    * Best for: Ensuring stakeholders have access to latest technical documentation
    */
   async function syncGithubToNotion(files: string[]): Promise<void> {
       for (const filePath of files) {
           const content = fs.readFileSync(filePath, 'utf-8');
           const hash = crypto.createHash('md5').update(content).digest('hex');

           // Check if page exists in Notion
           const existingPage = await searchNotionPage(filePath);

           if (existingPage) {
               // Update existing page
               await updateNotionPage(existingPage.id, {
                   content: convertMarkdownToNotion(content),
                   properties: {
                       'Last Synced': new Date().toISOString(),
                       'Content Hash': hash,
                       'Sync Direction': 'GitHub→Notion'
                   }
               });

               console.log(`✅ Updated: ${filePath} → ${existingPage.url}`);
           } else {
               // Create new page
               const newPage = await createNotionPage({
                   parent: { database_id: DSP_COMMAND_CENTER_DB_ID },
                   properties: {
                       'Title': extractTitle(content),
                       'Type': determineDocType(filePath),
                       'Status': 'Completed',
                       'GitHub Path': filePath,
                       'Content Hash': hash,
                       'Last Synced': new Date().toISOString()
                   },
                   content: convertMarkdownToNotion(content)
               });

               console.log(`✅ Created: ${filePath} → ${newPage.url}`);
           }
       }
   }

   function determineDocType(filePath: string): string {
       if (filePath.includes('ADR-')) return 'ADR';
       if (filePath.includes('.claude/agents/dsp-')) return 'Agent Activity';
       if (filePath.includes('docs/builds/')) return 'Build Record';
       return 'Documentation';
   }
   ```

3. **Sync Agent Activity Logs**
   ```typescript
   /**
    * Establish agent activity log synchronization from markdown to Notion.
    * Parses structured markdown log entries and creates Notion database records.
    */
   async function syncAgentActivityToNotion(): Promise<void> {
       const logContent = fs.readFileSync('.claude/logs/AGENT_ACTIVITY_LOG.md', 'utf-8');

       // Parse log entries (format: ## Agent Name - YYYY-MM-DD HH:MM)
       const entries = parseAgentActivityLog(logContent);

       for (const entry of entries) {
           // Check if already synced to Notion
           const existingEntry = await searchNotionActivityLog(entry.sessionId);

           if (!existingEntry) {
               await createNotionPage({
                   parent: { database_id: AGENT_ACTIVITY_HUB_ID },
                   properties: {
                       'Agent Name': entry.agentName,
                       'Session Start': entry.timestamp,
                       'Duration': entry.durationMinutes,
                       'Work Description': entry.workDescription,
                       'Status': entry.status,
                       'Files Modified': entry.filesModified.length,
                       'Related Project': 'DSP Command Central'
                   }
               });

               console.log(`✅ Synced activity: ${entry.agentName} - ${entry.timestamp}`);
           }
       }
   }
   ```

**Expected Output**: ✅ X documentation files synced, Y agent activity logs synced to Notion

---

### Phase 4: Notion → GitHub Synchronization (2-4 minutes)

**Skip if `--direction github-to-notion` specified**

1. **Query Notion for Modified Content**
   ```typescript
   /**
    * Establish Notion content synchronization back to GitHub repository.
    * Enables stakeholders to update documentation in Notion UI, syncing changes to Git.
    *
    * Best for: Non-technical stakeholders contributing to documentation
    */
   async function syncNotionToGithub(): Promise<void> {
       // Query pages modified in Notion since last sync
       const modifiedPages = await queryNotionDatabase({
           database_id: DSP_COMMAND_CENTER_DB_ID,
           filter: {
               and: [
                   {
                       property: 'Last Synced',
                       date: { before: new Date().toISOString() }
                   },
                   {
                       property: 'Sync Direction',
                       select: { equals: 'Notion→GitHub' }
                   }
               ]
           }
       });

       for (const page of modifiedPages) {
           const githubPath = page.properties['GitHub Path'].url;

           if (!githubPath) {
               console.warn(`⚠️ Skipping ${page.properties.Title.title[0].plain_text} - no GitHub path`);
               continue;
           }

           // Fetch full page content
           const pageContent = await fetchNotionPageContent(page.id);

           // Convert Notion blocks to markdown
           const markdown = convertNotionToMarkdown(pageContent);

           // Write to file
           fs.writeFileSync(githubPath, markdown, 'utf-8');

           // Update content hash in Notion
           const newHash = crypto.createHash('md5').update(markdown).digest('hex');
           await updateNotionPage(page.id, {
               properties: {
                   'Content Hash': newHash,
                   'Last Synced': new Date().toISOString()
               }
           });

           console.log(`✅ Updated GitHub: ${githubPath}`);
       }
   }
   ```

2. **Create Git Commit**
   ```bash
   cd dsp-command-central

   # Stage all modified documentation files
   git add README.md docs/ .claude/agents/dsp-*.md

   # Create commit with sync attribution
   git commit -m "docs: Sync Notion DSP Command Center updates to GitHub

   - Updated documentation from Notion stakeholder edits
   - Synced agent activity logs
   - Content hash validation passed

   🔄 Generated via /dsp:sync-notion bidirectional sync

   Co-Authored-By: Claude <noreply@anthropic.com>"

   # Record sync timestamp
   date -u +"%Y-%m-%d %H:%M:%S UTC" > .last-notion-sync
   ```

**Expected Output**: ✅ Git commit created with Notion updates, ready for push

---

### Phase 5: Validation & Audit Trail (1-2 minutes)

1. **Verify Synchronization Integrity**
   ```typescript
   /**
    * Establish post-sync validation ensuring data integrity across platforms.
    * Detects synchronization failures and maintains audit trail.
    */
   async function validateSync(): Promise<SyncValidationReport> {
       const report: SyncValidationReport = {
           timestamp: new Date(),
           filesProcessed: 0,
           successfulSyncs: 0,
           failures: [],
           conflictsResolved: 0,
           hashMismatches: []
       };

       // Re-calculate all content hashes
       const githubFiles = glob.sync('**/*.md', {
           ignore: ['node_modules/**', '.git/**']
       });

       for (const filePath of githubFiles) {
           const content = fs.readFileSync(filePath, 'utf-8');
           const githubHash = crypto.createHash('md5').update(content).digest('hex');

           // Query corresponding Notion page
           const notionPage = await searchNotionPage(filePath);

           if (notionPage) {
               const notionHash = notionPage.properties['Content Hash'].rich_text[0]?.plain_text;

               if (githubHash !== notionHash) {
                   report.hashMismatches.push({
                       file: filePath,
                       githubHash,
                       notionHash,
                       notionPageUrl: notionPage.url
                   });
               } else {
                   report.successfulSyncs++;
               }
           }

           report.filesProcessed++;
       }

       return report;
   }
   ```

2. **Generate Sync Report**
   ```markdown
   # DSP Notion Sync Report - [Timestamp]

   ## Summary
   - **Direction**: Bidirectional
   - **Files Processed**: 47
   - **Successful Syncs**: 45
   - **Failures**: 2
   - **Conflicts Resolved**: 3

   ## GitHub → Notion
   - Documentation files synced: 23
   - Agent activity logs synced: 15
   - Build records synced: 7

   ## Notion → GitHub
   - Stakeholder edits synced: 2
   - Git commit created: `abc123def456`

   ## Failures
   1. `docs/architecture/system-design.md` - Notion API rate limit (will retry)
   2. `.claude/agents/dsp-operations-architect.md` - Content hash mismatch (requires manual review)

   ## Next Steps
   - Review hash mismatches for manual resolution
   - Push Git commit to remote: `git push origin main`
   - Schedule next sync: 24 hours
   ```

**Expected Output**: ✅ Validation report generated with integrity confirmation

---

## Success Criteria

**Synchronization is successful when:**

✅ All documentation files have matching content hashes in GitHub and Notion
✅ Agent activity logs synced to Notion Agent Activity Hub
✅ Build records linked to DSP Command Center database
✅ Conflicts detected and resolved (or flagged for manual review)
✅ Git commit created for Notion → GitHub changes
✅ Sync timestamp recorded (`.last-notion-sync`)
✅ Validation report confirms integrity
✅ No orphaned pages in Notion (all linked to GitHub sources)
✅ Stakeholder visibility: Notion reflects latest GitHub documentation

---

## Estimated Execution Time

- **GitHub → Notion Only**: 3-5 minutes
- **Notion → GitHub Only**: 2-4 minutes
- **Bidirectional Sync**: 8-12 minutes
- **Dry Run (Validation)**: 1-2 minutes

---

## Troubleshooting

### Notion API Rate Limiting
**Symptom**: `429 Too Many Requests` errors
**Solution**: Implement exponential backoff, reduce batch size, or schedule sync during off-peak hours

### Content Hash Mismatches
**Symptom**: Validation report shows hash discrepancies
**Solution**: Review file modifications, check for encoding issues (CRLF vs LF), manually resolve conflicts

### Missing GitHub Path Property
**Symptom**: Notion pages cannot be matched to GitHub files
**Solution**: Populate `GitHub Path` property for all pages, establish naming convention for new pages

### Git Merge Conflicts
**Symptom**: Git commit fails due to conflicts
**Solution**: Resolve conflicts manually, ensure `.last-notion-sync` timestamp is accurate, re-run sync

### Agent Activity Parsing Errors
**Symptom**: Activity log entries not syncing to Notion
**Solution**: Verify log format matches expected structure (see agent-activity-center.md), check for markdown syntax errors

---

## Automation & Scheduling

### GitHub Actions Workflow
```yaml
name: Notion Sync

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch:  # Manual trigger

jobs:
  sync-notion:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure Notion MCP
        run: |
          echo "NOTION_API_KEY=${{ secrets.NOTION_API_KEY }}" >> $GITHUB_ENV
          echo "NOTION_WORKSPACE_ID=${{ secrets.NOTION_WORKSPACE_ID }}" >> $GITHUB_ENV

      - name: Run Bidirectional Sync
        run: |
          /dsp:sync-notion --direction bidirectional --scope all

      - name: Commit Notion Updates
        run: |
          git config --global user.name "DSP Notion Sync Bot"
          git config --global user.email "noreply@brooksidebi.com"
          git push origin main

      - name: Upload Sync Report
        uses: actions/upload-artifact@v3
        with:
          name: notion-sync-report
          path: /tmp/notion-sync-report.md
```

---

## Security Considerations

**✅ DO**:
- Use Notion API key stored in Azure Key Vault (never hardcode)
- Restrict sync to approved file paths only (prevent accidental syncing of secrets)
- Validate content before writing to GitHub (prevent injection attacks)
- Audit all Notion → GitHub changes before committing
- Implement approval workflow for sensitive documentation updates

**❌ DON'T**:
- Sync `.env` files or credential files to Notion
- Allow unrestricted file path modifications from Notion
- Commit directly to `main` without validation
- Skip conflict detection (could overwrite important changes)

---

## Related Commands

- `/dsp:demo-prep` - Complete demo environment setup (includes documentation generation)
- `/knowledge:archive [item] [database]` - Archive completed work with learnings documentation
- `/docs:update-complex <scope> <description>` - Multi-file documentation updates with diagrams

---

## Database Schema Reference

### DSP Command Center Database
```typescript
interface DSPCommandCenterPage {
  title: string;                  // Document/page name
  type: 'Documentation' | 'Agent Activity' | 'Build Record' | 'ADR';
  status: 'Draft' | 'In Progress' | 'Completed' | 'Archived';
  lastSynced: Date;               // Timestamp of last GitHub sync
  githubPath: string;             // Source file path in repository
  assignedAgent?: Agent;          // Link to Agent Registry
  relatedBuild?: Build;           // Link to Example Builds
  contentHash: string;            // MD5 hash for change detection
  syncDirection: 'GitHub→Notion' | 'Notion→GitHub' | 'Conflict';
}
```

### Sync State JSON
```json
{
  "lastSync": "2025-10-26T14:30:00Z",
  "direction": "bidirectional",
  "filesProcessed": 47,
  "successfulSyncs": 45,
  "conflicts": [
    {
      "githubPath": "docs/architecture/system-design.md",
      "notionPageId": "abc123",
      "resolvedBy": "github-newer",
      "timestamp": "2025-10-26T14:32:15Z"
    }
  ],
  "nextScheduledSync": "2025-10-27T02:00:00Z"
}
```

---

**Brookside BI** - *Driving measurable outcomes through unified documentation and knowledge systems*
