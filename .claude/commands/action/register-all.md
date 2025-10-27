---
name: action:register-all
description: Bootstrap Actions Registry by scanning all command files and establishing META self-documentation system
allowed-tools: Glob, Read, mcp__notion__notion-search, mcp__notion__notion-create-pages, mcp__notion__notion-fetch
argument-hint: [--dry-run] [--force-update]
model: claude-sonnet-4-5-20250929
---

# /action:register-all

**Category**: META System Bootstrap
**Related Databases**: Actions Registry (self-documenting command catalog)
**Agent Compatibility**: @schema-manager, @notion-mcp-specialist

## Purpose

Establish comprehensive self-documentation infrastructure by scanning all slash command files and populating the Actions Registry database. This META command enables automatic command discovery, usage analytics, deprecation workflows, and serves as the single source of truth for all Innovation Nexus automation capabilities.

**Best for**: Organizations requiring centralized automation governance, command lifecycle management, and sustainable documentation practices that scale with system growth.

---

## Command Parameters

**Optional Flags:**
- `--dry-run` - Preview what would be registered without making changes (default: false)
- `--force-update` - Update existing registry entries even if unchanged (default: false, only updates if metadata differs)
- `--category=filter` - Only register commands from specific category (Innovation, Cost, Knowledge, etc.)

---

## Workflow

### Step 1: Scan Command Directory Structure
```javascript
// Discover all command files recursively
const commandFiles = await glob({
  pattern: "**/*.md",
  path: ".claude/commands"
});

console.log(`📂 Found ${commandFiles.length} command files to process`);

// Expected structure:
// .claude/commands/
//   innovation/
//     new-idea.md
//     start-research.md
//   cost/
//     monthly-spend.md
//     add-software.md
//   [etc.]
```

### Step 2: Parse Frontmatter YAML from Each Command
```javascript
const commands = [];

for (const filePath of commandFiles) {
  const content = await readFile(filePath);

  // Extract frontmatter (between --- delimiters)
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);

  if (!frontmatterMatch) {
    console.warn(`⚠️ No frontmatter found in ${filePath}`);
    continue;
  }

  // Parse YAML
  const metadata = parseYAML(frontmatterMatch[1]);

  // Extract category from file path
  const category = filePath.split('/')[2]; // .claude/commands/{category}/file.md

  commands.push({
    name: metadata.name,
    description: metadata.description,
    category: capitalizeCategory(category),
    argumentHint: metadata['argument-hint'] || '',
    allowedTools: metadata['allowed-tools'] || '',
    model: metadata.model || 'claude-sonnet-4-5-20250929',
    filePath: filePath
  });
}

console.log(`✅ Parsed ${commands.length} commands successfully`);
```

### Step 3: Extract Related Databases from Command Content
```javascript
// Read full content to find "Related Databases" section
for (const cmd of commands) {
  const content = await readFile(cmd.filePath);

  // Find "**Related Databases**:" line
  const relatedDbMatch = content.match(/\*\*Related Databases\*\*:\s*([^\n]+)/);

  if (relatedDbMatch) {
    // Parse comma-separated database names
    const databases = relatedDbMatch[1]
      .split(',')
      .map(db => db.trim())
      .filter(db => db.length > 0);

    cmd.relatedDatabases = databases;
  } else {
    cmd.relatedDatabases = [];
  }
}
```

### Step 4: Check for Existing Registry Entries
```javascript
const existingEntries = new Map();

// Search Actions Registry for each command
for (const cmd of commands) {
  const results = await notionSearch({
    query: `/${cmd.name}`,
    data_source_url: "collection://9d5a1db0-585f-4f5b-b2bb-a41f875a7de4"
  });

  if (results.results.length > 0) {
    existingEntries.set(cmd.name, results.results[0]);
  }
}

console.log(`📊 Found ${existingEntries.size} existing registry entries`);
```

### Step 5: Determine Create vs Update Actions
```javascript
const toCreate = [];
const toUpdate = [];
const unchanged = [];

for (const cmd of commands) {
  const existing = existingEntries.get(cmd.name);

  if (!existing) {
    toCreate.push(cmd);
  } else {
    // Check if metadata changed
    const needsUpdate =
      existing.properties.Description !== cmd.description ||
      existing.properties.Category !== cmd.category ||
      forceUpdate;

    if (needsUpdate) {
      toUpdate.push({ cmd, existingId: existing.id });
    } else {
      unchanged.push(cmd);
    }
  }
}

console.log(`\n📈 **Registration Summary:**`);
console.log(`   ➕ Create: ${toCreate.length} new commands`);
console.log(`   🔄 Update: ${toUpdate.length} existing commands`);
console.log(`   ✓ Unchanged: ${unchanged.length} commands`);
```

### Step 6: Execute Registration (or Dry Run)
```javascript
if (dryRun) {
  console.log(`\n🔍 **DRY RUN MODE** - No changes will be made\n`);

  if (toCreate.length > 0) {
    console.log(`**Commands to Create:**`);
    toCreate.forEach(cmd => {
      console.log(`  - /${cmd.name} (${cmd.category})`);
    });
  }

  if (toUpdate.length > 0) {
    console.log(`\n**Commands to Update:**`);
    toUpdate.forEach(({cmd}) => {
      console.log(`  - /${cmd.name} (${cmd.category})`);
    });
  }

  return;
}

// Bulk create new entries
if (toCreate.length > 0) {
  await notionCreatePages({
    parent: { data_source_id: "9d5a1db0-585f-4f5b-b2bb-a41f875a7de4" },
    pages: toCreate.map(cmd => ({
      properties: {
        "Name": `/${cmd.name}`,
        "Category": cmd.category,
        "Description": cmd.description,
        "Parameters": cmd.argumentHint,
        "Status": "Active",
        "Related Databases": cmd.relatedDatabases,
        "Example Usage": `See: ${cmd.filePath}`,
        "Last Updated": new Date().toISOString().split('T')[0]
      }
    }))
  });

  console.log(`✅ Created ${toCreate.length} new registry entries`);
}

// Update existing entries
for (const {cmd, existingId} of toUpdate) {
  await notionUpdatePage({
    page_id: existingId,
    command: "update_properties",
    properties: {
      "Description": cmd.description,
      "Category": cmd.category,
      "Parameters": cmd.argumentHint,
      "Related Databases": cmd.relatedDatabases,
      "Last Updated": new Date().toISOString().split('T')[0]
    }
  });
}

if (toUpdate.length > 0) {
  console.log(`✅ Updated ${toUpdate.length} existing registry entries`);
}
```

### Step 7: Generate Summary Report
```javascript
console.log(`\n📊 **Actions Registry Bootstrap Complete**\n`);
console.log(`**Total Commands**: ${commands.length}`);
console.log(`**Categories**: ${[...new Set(commands.map(c => c.category))].join(', ')}`);
console.log(`\n**Coverage by Category:**`);

const byCategory = commands.reduce((acc, cmd) => {
  acc[cmd.category] = (acc[cmd.category] || 0) + 1;
  return acc;
}, {});

Object.entries(byCategory)
  .sort((a, b) => b[1] - a[1])
  .forEach(([category, count]) => {
    console.log(`   ${category}: ${count} commands`);
  });

console.log(`\n🔗 View Actions Registry: https://www.notion.so/9d5a1db0585f4f5bb2bba41f875a7de4`);
```

---

## Execution Examples

### Example 1: Initial Bootstrap (First-Time Setup)
```bash
/action:register-all
```

**Expected Output:**
```
📂 Found 38 command files to process
✅ Parsed 38 commands successfully
📊 Found 0 existing registry entries

📈 **Registration Summary:**
   ➕ Create: 38 new commands
   🔄 Update: 0 existing commands
   ✓ Unchanged: 0 commands

✅ Created 38 new registry entries

📊 **Actions Registry Bootstrap Complete**

**Total Commands**: 38
**Categories**: Innovation, Cost, Knowledge, Team, Repo, Autonomous, Compliance, Sync

**Coverage by Category:**
   Innovation: 12 commands
   Cost: 8 commands
   Knowledge: 5 commands
   Autonomous: 4 commands
   Repo: 4 commands
   Team: 2 commands
   Compliance: 2 commands
   Sync: 1 command

🔗 View Actions Registry: https://www.notion.so/9d5a1db0585f4f5bb2bba41f875a7de4
```

### Example 2: Dry Run to Preview Changes
```bash
/action:register-all --dry-run
```

**Expected Output:**
```
📂 Found 42 command files to process
✅ Parsed 42 commands successfully
📊 Found 38 existing registry entries

📈 **Registration Summary:**
   ➕ Create: 4 new commands
   🔄 Update: 2 existing commands
   ✓ Unchanged: 36 commands

🔍 **DRY RUN MODE** - No changes will be made

**Commands to Create:**
  - /build:link-software (Build)
  - /cost:add-software (Cost)
  - /action:register-all (META)
  - /idea:search (Innovation)

**Commands to Update:**
  - /cost:monthly-spend (Cost) - Description changed
  - /innovation:new-idea (Innovation) - Category changed

💡 Run without --dry-run to apply changes
```

### Example 3: Update Specific Category
```bash
/action:register-all --category=Cost --force-update
```

**Expected Output:**
```
📂 Found 8 command files in Cost category
✅ Parsed 8 commands successfully
📊 Found 8 existing registry entries

📈 **Registration Summary:**
   ➕ Create: 0 new commands
   🔄 Update: 8 existing commands (forced)
   ✓ Unchanged: 0 commands

✅ Updated 8 existing registry entries

📊 **Cost Category Registration Complete**

**Total Commands**: 8
**Updated**: All cost commands refreshed with latest metadata
```

---

## Error Handling

### Error 1: No Command Files Found
**Scenario**: .claude/commands directory empty or missing
**Response**:
```
❌ No command files found in .claude/commands/

💡 **Troubleshooting:**
1. Verify .claude/commands directory exists
2. Check that command files have .md extension
3. Ensure commands follow standard directory structure:
   .claude/commands/{category}/{command-name}.md

**Expected Structure:**
.claude/commands/
  innovation/
  cost/
  knowledge/
  [etc.]
```

### Error 2: Malformed Frontmatter
**Scenario**: Command file missing or invalid YAML frontmatter
**Response**:
```
⚠️ Parsing errors in 3 command files:

1. .claude/commands/cost/broken-command.md
   Error: No frontmatter found (missing --- delimiters)

2. .claude/commands/idea/invalid.md
   Error: Invalid YAML syntax at line 5

3. .claude/commands/team/incomplete.md
   Error: Missing required field: description

📊 Successfully parsed: 35 of 38 commands

❓ **Action Required:**
Fix the malformed files before re-running, or continue with partial registration?
```

### Error 3: Actions Registry Not Found
**Scenario**: Actions Registry database doesn't exist or data source ID invalid
**Response**:
```
❌ Actions Registry database not found

💡 **Resolution:**
1. Verify Actions Registry exists in Notion workspace
2. Check data source ID: 9d5a1db0-585f-4f5b-b2bb-a41f875a7de4
3. Ensure Notion MCP has access to Actions Registry
4. See .claude/docs/notion-schema.md lines 445-490 for schema

**Current Status**: Database ID may have changed
**Required Action**: Update data source ID in command file
```

### Error 4: Permission Denied
**Scenario**: Notion MCP lacks write access to Actions Registry
**Response**:
```
❌ Permission denied: Cannot create entries in Actions Registry

💡 **Resolution:**
1. Verify Notion MCP integration has edit access
2. Check workspace permissions for Actions Registry database
3. Ensure authenticated user has Editor or Owner role

**Current Permissions**: Read-only
**Required Permissions**: Editor or Owner
```

---

## Success Criteria

After successful execution, verify:

- ✅ All command files in `.claude/commands/` discovered and parsed
- ✅ Frontmatter YAML extracted successfully from each command
- ✅ Actions Registry populated with all commands
- ✅ Each entry includes:
  - Name (`/category:action` format)
  - Category (Innovation, Cost, Knowledge, etc.)
  - Description (from frontmatter)
  - Parameters (argument-hint from frontmatter)
  - Status (Active by default)
  - Related Databases (parsed from content)
  - Last Updated (current date)
- ✅ No duplicate entries created (search-first protocol)
- ✅ Summary report shows coverage by category
- ✅ Actions Registry viewable in Notion with all entries

**META Validation:**
The Actions Registry should now contain entries for ALL commands, including itself (`/action:register-all`). This self-referential entry proves the META system is working correctly.

---

## Related Commands

**Before this command:**
- N/A - This is the bootstrap/foundation command

**After this command:**
- `/action:search [query]` - Find commands by name, category, or description
- `/action:deprecate [command-name]` - Mark command as deprecated
- `/action:usage-stats` - View command execution analytics
- Any command in the registry - all are now discoverable

**Maintenance workflow:**
Run `/action:register-all` after:
- Creating new command files
- Updating command metadata (name, description, category)
- Reorganizing command directory structure
- Quarterly audits to ensure registry accuracy

---

## Best Practices

### 1. Run Bootstrap Once, Then Use Incremental Updates
Initial setup requires full scan. For ongoing maintenance, use `--category=filter` to update only changed categories, improving performance.

### 2. Always Dry Run Before Force Update
Use `--dry-run` to preview changes before executing `--force-update`, which overwrites all existing entries regardless of change status.

### 3. Maintain Frontmatter Consistency
All command files must follow the standard frontmatter pattern (see command-structure-standard.md). Inconsistent frontmatter causes parsing failures.

### 4. Document Related Databases Explicitly
Include `**Related Databases**:` section in every command file. This powers cross-database automation and dependency tracking.

---

## Notes for Claude Code

**When to use this command:**
- First-time setup of Innovation Nexus (bootstrap)
- After creating multiple new command files
- When Actions Registry appears out-of-sync with actual commands
- Quarterly maintenance to ensure registry accuracy

**Execution approach:**
1. Run with `--dry-run` first to preview changes
2. Review the summary report for accuracy
3. Execute without dry-run to apply changes
4. Verify Actions Registry in Notion UI
5. Test command discovery with `/action:search`

**META Significance:**
This command enables the self-documenting nature of the Innovation Nexus. Once Actions Registry is populated:
- New team members can discover all available commands
- Usage analytics become possible (track which commands are used)
- Deprecation workflows enable graceful command retirement
- Related databases mapping enables intelligent automation suggestions

**Common mistakes to avoid:**
- Running without `--dry-run` first (preview changes!)
- Not validating frontmatter syntax before registration
- Forgetting to update registry after creating new commands
- Using `--force-update` unnecessarily (only when metadata genuinely changed)

**Performance Considerations:**
- First bootstrap: ~30-60 seconds for 60+ commands
- Incremental updates: ~5-10 seconds
- Dry run: ~5 seconds (no Notion writes)

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Automation Coverage Impact**: Enables META self-documentation system for entire Innovation Nexus
