# Sync Documentation to Notion

**Category**: Documentation | Notion Integration
**Command**: `/docs:sync-notion`
**Agent**: `@documentation-orchestrator` → `@knowledge-curator` → `@notion-mcp-specialist`
**Purpose**: Archive documentation to Notion Knowledge Vault with proper content classification and relation establishment

**Best for**: Organizations requiring systematic knowledge preservation with team-accessible documentation in Notion for enhanced discoverability and cross-database insights.

## Command Syntax

```bash
/docs:sync-notion <source-file> [options]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `source-file` | string | Yes | Path to documentation file to sync (relative to repository root) |

### Optional Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--content-type` | Knowledge Vault content type | Auto-detected |
| `--evergreen` | Mark as evergreen (timeless) content | Auto-assessed |
| `--related-idea` | Link to Ideas Registry entry by title | None |
| `--related-research` | Link to Research Hub entry by title | None |
| `--related-build` | Link to Example Builds entry by title | None |
| `--tags` | Comma-separated tags for categorization | Auto-extracted |
| `--reusability` | Reusability score (High/Medium/Low) | Auto-assessed |
| `--update-existing` | Update existing entry if found | false |

## Usage Examples

### Example 1: Sync Architecture Documentation

```bash
/docs:sync-notion "docs/architecture/event-sourcing.md" \
  --content-type "Technical Doc" \
  --evergreen \
  --related-build "Cost Tracker MVP" \
  --tags "Event Sourcing,Azure,Architecture"
```

**What Happens:**
1. **Read Source File** (10 seconds):
   - Fetches `docs/architecture/event-sourcing.md`
   - Parses markdown structure
   - Extracts key sections and metadata

2. **Content Classification** (20 seconds):
   - Confirms content type: "Technical Doc"
   - Assesses as Evergreen (architectural patterns are timeless)
   - Determines reusability: High

3. **Format for Notion** (30 seconds):
   - `@markdown-expert` converts to Notion-flavored Markdown
   - Optimizes for Notion rendering
   - Preserves code blocks and diagrams

4. **Search for Duplicates** (15 seconds):
   - `@notion-mcp-specialist` searches Knowledge Vault
   - Checks for existing "Event Sourcing" documentation
   - No duplicates found

5. **Create Knowledge Vault Entry** (45 seconds):
   - Creates new entry with properties:
     - Title: "Event Sourcing Pattern"
     - Content Type: Technical Doc
     - Evergreen/Dated: Evergreen
     - Reusability: High
     - Tags: Event Sourcing, Azure, Architecture
   - Links to "Cost Tracker MVP" build
   - Adds source file reference to GitHub

6. **Establish Relations** (30 seconds):
   - Links to Example Builds → "Cost Tracker MVP"
   - Links to Pattern Library (if pattern entry exists)
   - Links to Software Tracker (Azure services mentioned)

7. **Verify Success** (10 seconds):
   - Confirms entry created successfully
   - Validates all relations established
   - Returns Notion URL

**Total Duration**: 2 minutes 40 seconds

**Output**:
```json
{
  "status": "completed",
  "notion_entry_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "notion_url": "https://notion.so/Event-Sourcing-Pattern-a1b2c3d4",
  "content_type": "Technical Doc",
  "evergreen": true,
  "reusability": "High",
  "relations_established": {
    "builds": ["Cost Tracker MVP"],
    "patterns": ["Event Sourcing"],
    "software": ["Azure Event Hubs", "Azure Cosmos DB"]
  },
  "duration_seconds": 160
}
```

### Example 2: Sync API Tutorial

```bash
/docs:sync-notion "docs/api/getting-started.md" \
  --content-type "Tutorial" \
  --related-build "API Gateway" \
  --tags "API,Getting Started,Tutorial"
```

**What Happens:**
1. Reads API getting started guide
2. Classifies as Tutorial (step-by-step instructions)
3. Assesses as Dated (API versions evolve)
4. Formats with code examples preserved
5. Creates Knowledge Vault entry
6. Links to "API Gateway" build
7. Returns Notion URL

**Duration**: 3 minutes

### Example 3: Sync Post-Mortem Documentation

```bash
/docs:sync-notion "docs/retrospectives/azure-migration-postmortem.md" \
  --content-type "Post-Mortem" \
  --related-research "Azure Migration Feasibility" \
  --related-build "Azure Infrastructure MVP" \
  --tags "Post-Mortem,Azure,Migration,Lessons Learned"
```

**What Happens:**
1. Reads post-mortem documentation
2. Classifies as Post-Mortem (lessons learned format)
3. Assesses as Evergreen (migration lessons remain relevant)
4. Extracts key learnings and recommendations
5. Creates Knowledge Vault entry with rich formatting
6. Links to both Research Hub and Example Builds entries
7. Establishes software relations for tools mentioned
8. Returns comprehensive report

**Duration**: 4 minutes

### Example 4: Update Existing Documentation

```bash
/docs:sync-notion "docs/guides/deployment.md" \
  --content-type "Process" \
  --update-existing \
  --tags "Deployment,Azure,Process"
```

**What Happens:**
1. Reads updated deployment guide
2. Searches Knowledge Vault for existing entry
3. **Finds existing "Deployment Process" entry**
4. Compares current vs. new content
5. Updates existing entry with new content
6. Preserves all existing relations
7. Updates "Last Updated" timestamp
8. Returns update confirmation

**Duration**: 2 minutes

## Content Type Classification

### Automatic Detection

The command automatically detects content type based on file structure:

| Content Type | Detection Criteria |
|--------------|-------------------|
| **Tutorial** | Step-by-step instructions, numbered lists, "How to" language |
| **Technical Doc** | Architecture diagrams, API specs, technical specifications |
| **Case Study** | Project outcomes, before/after comparisons, success metrics |
| **Process** | Repeatable workflows, SOP format, checklists |
| **Template** | Reusable structures, placeholder content, "Example" sections |
| **Post-Mortem** | "Lessons learned", "What worked", "What didn't", retrospective format |
| **Reference** | Quick-lookup tables, command lists, cheat sheet format |

### Manual Override

Use `--content-type` flag to override automatic detection:

```bash
--content-type "Tutorial"
--content-type "Technical Doc"
--content-type "Case Study"
--content-type "Process"
--content-type "Template"
--content-type "Post-Mortem"
--content-type "Reference"
```

## Evergreen vs. Dated Assessment

### Automatic Assessment

**Evergreen Content** (timeless value):
- ✓ Architectural patterns and design principles
- ✓ Best practices and methodologies
- ✓ Conceptual frameworks
- ✓ Strategic approaches
- ✓ Lessons learned from projects

**Dated Content** (time-sensitive):
- ✓ Version-specific guides (API v1.2, Node 18)
- ✓ Tool-specific tutorials (current UI)
- ✓ Release notes and changelogs
- ✓ Time-sensitive announcements
- ✓ Deprecated information

### Manual Override

```bash
--evergreen         # Force as evergreen
--dated             # Force as dated (not evergreen)
```

## Reusability Assessment

### Automatic Scoring

**High Reusability:**
- ✓ Generic patterns applicable across projects
- ✓ Framework-agnostic best practices
- ✓ Templates with clear customization points
- ✓ Well-documented processes

**Medium Reusability:**
- ✓ Project-specific patterns with adaptation needed
- ✓ Tool-specific guides applicable to similar tools
- ✓ Processes requiring minor customization

**Low Reusability:**
- ✓ One-off solutions to unique problems
- ✓ Highly context-specific implementations
- ✓ Deprecated approaches

### Manual Override

```bash
--reusability "High"
--reusability "Medium"
--reusability "Low"
```

## Notion Knowledge Vault Integration

### Database Structure

**Knowledge Vault Database ID**: (To be configured after creation)

**Properties**:
- **Title** (title): Entry name
- **Content Type** (select): Tutorial | Technical Doc | Case Study | Process | Template | Post-Mortem | Reference
- **Evergreen/Dated** (select): Evergreen | Dated
- **Reusability** (select): High | Medium | Low
- **Status** (select): Draft | Published | Deprecated | Archived
- **Tags** (multi-select): Categorization tags
- **Source File** (url): GitHub file link
- **Related Ideas** (relation): Links to Ideas Registry
- **Related Research** (relation): Links to Research Hub
- **Related Builds** (relation): Links to Example Builds
- **Related Software** (relation): Links to Software & Cost Tracker
- **Related Patterns** (relation): Links to Pattern Library
- **Created Date** (created_time): Auto-populated
- **Last Updated** (last_edited_time): Auto-populated

### Relation Establishment

When syncing, the command automatically establishes these relations:

**Ideas Registry:**
- Links if `--related-idea` specified
- Auto-links if idea title mentioned in content

**Research Hub:**
- Links if `--related-research` specified
- Auto-links if research topic mentioned

**Example Builds:**
- Links if `--related-build` specified
- Auto-links if build name mentioned in content

**Software & Cost Tracker:**
- Auto-links when tools/services mentioned (Azure OpenAI, GitHub, etc.)

**Pattern Library:**
- Auto-links when architectural patterns mentioned (Event Sourcing, Circuit Breaker, etc.)

## Workflow Execution

```
Step 1: Read Source Documentation
├─ Fetch file from repository
├─ Parse markdown structure
├─ Extract metadata from frontmatter (if present)
└─ Identify key sections and content

Step 2: Content Classification
├─ Agent: @knowledge-curator
├─ Determine content type (or use --content-type)
├─ Assess Evergreen vs. Dated
├─ Evaluate reusability score
└─ Extract tags from content

Step 3: Format for Notion
├─ Agent: @markdown-expert
├─ Convert to Notion-flavored Markdown
├─ Optimize code blocks for Notion rendering
├─ Preserve diagrams and images
└─ Ensure proper heading hierarchy

Step 4: Search for Duplicates
├─ Agent: @notion-mcp-specialist
├─ Search Knowledge Vault by title and tags
├─ Check for similar existing entries
└─ Determine: Create new or update existing

Step 5: Create/Update Knowledge Vault Entry
├─ Agent: @notion-mcp-specialist
├─ Create new entry (or update if --update-existing)
├─ Set all properties (content type, evergreen, etc.)
├─ Add formatted content
└─ Include source file reference

Step 6: Establish Relations
├─ Link to related Ideas (if specified or detected)
├─ Link to related Research (if specified or detected)
├─ Link to related Builds (if specified or detected)
├─ Link to related Software (auto-detected from content)
├─ Link to related Patterns (auto-detected from content)
└─ Verify all relations created successfully

Step 7: Verification & Return
├─ Confirm entry created/updated
├─ Validate all properties set correctly
├─ Verify all relations established
├─ Generate Notion URL
└─ Return comprehensive report to user
```

## Output Format

### Detailed Success Response

```json
{
  "status": "completed",
  "action": "created",
  "notion_entry": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "url": "https://notion.so/Event-Sourcing-Pattern-a1b2c3d4",
    "title": "Event Sourcing Pattern"
  },
  "properties": {
    "content_type": "Technical Doc",
    "evergreen": true,
    "reusability": "High",
    "status": "Published",
    "tags": ["Event Sourcing", "Azure", "Architecture"]
  },
  "source_file": {
    "path": "docs/architecture/event-sourcing.md",
    "github_url": "https://github.com/org/repo/blob/main/docs/architecture/event-sourcing.md"
  },
  "relations_established": {
    "ideas": [],
    "research": [],
    "builds": [
      {
        "id": "build-123",
        "title": "Cost Tracker MVP"
      }
    ],
    "software": [
      {
        "id": "software-456",
        "title": "Azure Event Hubs"
      },
      {
        "id": "software-789",
        "title": "Azure Cosmos DB"
      }
    ],
    "patterns": [
      {
        "id": "pattern-101",
        "title": "Event Sourcing"
      }
    ]
  },
  "execution_summary": {
    "total_duration_seconds": 160,
    "agents_coordinated": 3,
    "duplicate_check_performed": true,
    "existing_entry_found": false
  }
}
```

### Update Response

```json
{
  "status": "completed",
  "action": "updated",
  "notion_entry": {
    "id": "existing-entry-id",
    "url": "https://notion.so/Deployment-Process-existing",
    "title": "Deployment Process"
  },
  "changes": [
    "Content updated with new deployment steps",
    "Added Azure Managed Identity instructions",
    "Preserved all existing relations"
  ],
  "duration_seconds": 120
}
```

## Common Use Cases

### Use Case 1: Archive Completed Build Documentation

**Scenario**: Build completed, document learnings in Knowledge Vault

```bash
/docs:sync-notion "docs/builds/cost-dashboard-postmortem.md" \
  --content-type "Post-Mortem" \
  --related-build "Cost Dashboard MVP" \
  --tags "Post-Mortem,Cost Tracking,Lessons Learned"
```

**Outcome**: Post-mortem archived, linked to build, searchable by team

### Use Case 2: Share Reusable Pattern

**Scenario**: New architectural pattern to share with team

```bash
/docs:sync-notion "docs/patterns/circuit-breaker.md" \
  --content-type "Technical Doc" \
  --evergreen \
  --reusability "High" \
  --tags "Circuit Breaker,Resilience,Pattern"
```

**Outcome**: Pattern documented in Knowledge Vault, marked as highly reusable

### Use Case 3: API Documentation for Developers

**Scenario**: Tutorial for new API users

```bash
/docs:sync-notion "docs/api/quickstart.md" \
  --content-type "Tutorial" \
  --related-build "API Gateway" \
  --tags "API,Quickstart,Tutorial"
```

**Outcome**: Tutorial accessible in Notion, linked to API Gateway build

### Use Case 4: Process Documentation

**Scenario**: Standard deployment process

```bash
/docs:sync-notion "docs/runbooks/deployment-process.md" \
  --content-type "Process" \
  --evergreen \
  --tags "Deployment,Process,Azure"
```

**Outcome**: Repeatable process documented, marked as evergreen

## Integration with Innovation Nexus

### Automatic Knowledge Capture

When builds complete, automatically sync documentation:

```bash
# Build completes → Archive learnings
/knowledge:archive "Cost Tracker MVP" build

# Behind the scenes:
/docs:sync-notion "docs/builds/cost-tracker-postmortem.md" \
  --content-type "Post-Mortem" \
  --related-build "Cost Tracker MVP"
```

### Research Findings Documentation

When research completes, preserve findings:

```bash
# Research completes → Document findings
/knowledge:archive "Azure OpenAI Feasibility" research

# Behind the scenes:
/docs:sync-notion "docs/research/azure-openai-findings.md" \
  --content-type "Case Study" \
  --related-research "Azure OpenAI Feasibility"
```

## Performance Expectations

**Target SLAs:**
- Read source file: <10 seconds
- Content classification: <30 seconds
- Format for Notion: <30 seconds
- Duplicate search: <20 seconds
- Create/update entry: <60 seconds
- Establish relations: <40 seconds

**Total Duration:**
- Simple sync (no relations): 2-3 minutes
- Complex sync (multiple relations): 4-5 minutes
- Update existing: 2 minutes

## Error Handling

### Common Issues

**Issue: Duplicate Entry Found**
```
Warning: Existing entry "Event Sourcing Pattern" found in Knowledge Vault
Options:
  1. Use --update-existing to update the entry
  2. Cancel and review existing entry
  3. Create with different title
```

**Issue: Related Item Not Found**
```
Error: Related build "Cost Tracker MVP" not found in Example Builds database
Solution: Verify build name is correct or create build entry first
```

**Issue: Notion MCP Not Connected**
```
Error: Notion MCP server not responding
Solution: Restart Claude Code to re-establish Notion connection
Verify: claude mcp list
```

## Best Practices

### When to Sync to Notion

**✓ Always Sync:**
- Completed build documentation (post-mortems, case studies)
- Architectural patterns and design decisions
- Reusable processes and templates
- Research findings and lessons learned
- Team-wide knowledge sharing content

**✗ Don't Sync:**
- Work-in-progress drafts
- Temporary troubleshooting notes
- Repository-specific internal documentation
- Highly version-specific content (unless marked as Dated)

### Writing Sync-Ready Documentation

**Good Documentation Structure:**
- Clear title that matches Notion naming convention
- Outcome-focused introduction with "Best for:" qualifier
- Proper heading hierarchy (H1 → H2 → H3)
- Code blocks with language tags
- References to Ideas/Research/Builds by exact title

**Tags Best Practices:**
- Use consistent naming: "Event Sourcing" not "event-sourcing" or "eventsourcing"
- Include technology: "Azure", "TypeScript", "React"
- Include domain: "Cost Tracking", "Authentication", "Analytics"
- Include type: "Pattern", "Tutorial", "Process"

## Related Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/docs:update-simple` | Quick documentation fixes | Before syncing to ensure quality |
| `/docs:update-complex` | Multi-file documentation updates | Major documentation overhauls |
| `/knowledge:archive` | Complete work lifecycle archival | Automated sync during archival |

## Support

For Notion sync questions:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

---

**Sync Documentation to Notion Command** - Establish systematic knowledge preservation that drives team collaboration and organizational learning through intelligent content classification and comprehensive relation management in Notion Knowledge Vault.

**Designed for**: Organizations scaling innovation across teams who require centralized, searchable documentation with cross-database insights that support sustainable knowledge management practices.
