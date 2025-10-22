# Update Simple Documentation

**Category**: Documentation
**Command**: `/docs:update-simple`
**Agent**: `@documentation-orchestrator` → `@markdown-expert`
**Purpose**: Quick single-file documentation updates with brand compliance and quality validation

**Best for**: Teams requiring fast documentation fixes while maintaining Brookside BI brand standards and technical accuracy.

## Command Syntax

```bash
/docs:update-simple <file-path> <update-description>
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file-path` | string | Yes | Path to documentation file (relative to repository root) |
| `update-description` | string | Yes | Clear description of changes to make |

### Optional Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--no-validation` | Skip quality validation | false |
| `--brand-voice` | Apply Brookside BI brand transformations | true |
| `--commit` | Auto-commit changes with conventional commit message | false |

## Usage Examples

### Example 1: Update API Documentation

```bash
/docs:update-simple "docs/api/endpoints.md" \
  "Add POST /api/builds endpoint with request/response schemas"
```

**What Happens:**
1. `@documentation-orchestrator` receives request
2. Reads current `docs/api/endpoints.md`
3. Delegates to `@markdown-expert` for formatting
4. Adds new endpoint documentation
5. Validates brand compliance and markdown syntax
6. Writes updated file
7. Returns summary of changes

**Expected Duration**: 2-3 minutes

### Example 2: Fix Typos in README

```bash
/docs:update-simple "README.md" \
  "Fix typos in installation section and update Node.js version requirement to 18.0.0"
```

**What Happens:**
1. Reads README.md
2. Corrects spelling errors
3. Updates version requirement
4. Maintains existing structure and brand voice
5. Validates all changes
6. Writes corrected file

**Expected Duration**: 1-2 minutes

### Example 3: Update with Auto-Commit

```bash
/docs:update-simple "docs/guides/deployment.md" \
  "Add Azure Managed Identity authentication instructions" \
  --commit
```

**What Happens:**
1. Updates deployment guide
2. Applies brand voice transformations
3. Validates quality
4. Writes updated file
5. **Creates Git commit:**
   ```
   docs: Enhance deployment guide with Managed Identity authentication for secure Azure access

   🤖 Generated with Claude Code
   Co-Authored-By: Claude <noreply@anthropic.com>
   ```

**Expected Duration**: 3-4 minutes (includes commit)

### Example 4: Quick Fix Without Validation

```bash
/docs:update-simple "CHANGELOG.md" \
  "Add v1.2.3 release notes" \
  --no-validation
```

**What Happens:**
1. Reads CHANGELOG.md
2. Adds new version entry
3. **Skips** quality validation (faster)
4. Writes updated file
5. Returns summary

**Expected Duration**: <1 minute

**⚠️ Warning**: Use `--no-validation` only for non-critical updates like changelogs or version bumps.

## Workflow Execution

### Step-by-Step Process

```
Step 1: Request Reception
├─ Parse command parameters
├─ Validate file path exists
└─ Confirm update description is clear

Step 2: Read Current Content
├─ Use Read tool to fetch file
├─ Parse markdown structure
├─ Identify update target sections
└─ Preserve existing formatting

Step 3: Apply Updates
├─ Delegate to @markdown-expert
├─ Make requested changes
├─ Apply Brookside BI brand voice (if --brand-voice=true)
├─ Maintain consistent structure
└─ Ensure AI-agent readability

Step 4: Validate Quality (unless --no-validation)
├─ Check markdown syntax
├─ Verify code blocks have language tags
├─ Validate internal links
├─ Assess brand compliance
└─ Generate quality score

Step 5: Write Updated File
├─ Use Write tool to save changes
├─ Preserve file permissions
└─ Maintain line endings

Step 6: Optional Commit (if --commit)
├─ Stage file: git add <file-path>
├─ Create conventional commit message
├─ Include Claude co-authorship
└─ Commit changes

Step 7: Return Summary
├─ List changes made
├─ Report quality score (if validated)
├─ Note any issues or warnings
└─ Provide next steps (if applicable)
```

## Output Format

### Success Response

```json
{
  "status": "completed",
  "file": "docs/api/endpoints.md",
  "changes": [
    "Added POST /api/builds endpoint documentation",
    "Included request schema with validation rules",
    "Added response examples for 201 Created and 400 Bad Request",
    "Applied brand voice transformation to introduction"
  ],
  "quality_score": 87,
  "rating": "GOOD",
  "brand_compliant": true,
  "duration_seconds": 142,
  "commit_hash": "a1b2c3d4" // Only if --commit was used
}
```

### Error Response

```json
{
  "status": "failed",
  "error": "File not found: docs/api/endpoints.md",
  "suggestion": "Verify file path is correct. Did you mean 'docs/api/endpoint.md'?",
  "duration_seconds": 5
}
```

## Quality Validation Details

When validation is enabled (default), the following checks are performed:

### Brand Compliance (0-30 points)
- ✓ Professional but approachable tone
- ✓ Solution-focused language
- ✓ "Best for:" qualifiers present
- ✓ Outcome-focused descriptions
- ✓ Consultative positioning

### Technical Standards (0-25 points)
- ✓ No ambiguous instructions
- ✓ Explicit version requirements
- ✓ Idempotent setup steps
- ✓ Verification commands included
- ✓ Error handling documented

### Structure (0-20 points)
- ✓ Proper header hierarchy
- ✓ Code blocks with language tags
- ✓ Working examples with outputs
- ✓ Clear visual hierarchy
- ✓ Consistent formatting

### Total Score: 0-100
- **90-100**: EXCELLENT - Production-ready
- **70-89**: GOOD - Minor improvements suggested
- **50-69**: ADEQUATE - Needs work
- **0-49**: POOR - Significant issues

**Minimum Required Score**: 70 (GOOD) for automated approval

## Common Use Cases

### 1. API Documentation Updates

**Scenario**: New endpoint added to API

```bash
/docs:update-simple "docs/api/endpoints.md" \
  "Add GET /api/research endpoint with query parameter documentation"
```

**Changes Applied:**
- New endpoint section created
- Request/response schemas added
- Example curl commands included
- Error response codes documented
- Brand voice applied to descriptions

### 2. README Maintenance

**Scenario**: Update installation instructions for new dependency

```bash
/docs:update-simple "README.md" \
  "Update prerequisites to include PostgreSQL >= 14.0 and add installation instructions"
```

**Changes Applied:**
- Prerequisites section updated
- Installation commands added
- Verification steps included
- Existing structure preserved

### 3. Troubleshooting Guide Expansion

**Scenario**: Add solution for common error

```bash
/docs:update-simple "docs/guides/troubleshooting.md" \
  "Add resolution for 'Connection timeout' error with Azure SQL Database"
```

**Changes Applied:**
- New troubleshooting entry added
- Error symptoms described
- Solution steps provided (idempotent)
- Related links included

### 4. CHANGELOG Updates

**Scenario**: Release new version

```bash
/docs:update-simple "CHANGELOG.md" \
  "Add v2.1.0 release notes with features and bug fixes" \
  --no-validation \
  --commit
```

**Changes Applied:**
- New version entry created
- Features and fixes listed
- Validation skipped (faster for changelogs)
- Auto-committed with conventional message

## Integration with Documentation Orchestrator

This command is the entry point for simple documentation updates. The workflow delegates to specialized agents:

**Agent Delegation:**
```
/docs:update-simple command
  ↓
@documentation-orchestrator (coordinator)
  ↓
@markdown-expert (formatting & validation)
  ↓
Updated file with quality report
```

**For More Complex Updates:**
- Multiple files: Use `/docs:update-complex`
- Notion sync: Use `/docs:sync-notion`
- Full documentation refresh: Use `/docs:update-complex` with `--full-refresh`

## Error Handling

### Common Errors and Solutions

**Error: File not found**
```
Solution: Verify file path is correct relative to repository root
Example: "docs/api/endpoints.md" not "api/endpoints.md"
```

**Error: Quality validation failed**
```
Solution: Review quality report and address issues
Use --no-validation flag only if update is non-critical
```

**Error: Markdown syntax error**
```
Solution: Check for malformed tables, code blocks, or headers
Review current file structure before applying updates
```

**Error: Git commit failed**
```
Solution: Ensure Git is configured and repository is clean
Check: git status
Fix: Resolve merge conflicts or commit pending changes
```

## Best Practices

### When to Use This Command

**✓ Use `/docs:update-simple` for:**
- Single file modifications
- Typo fixes and minor corrections
- Adding new sections to existing docs
- Updating version numbers or links
- Quick content additions (<500 words)

**✗ Do NOT use for:**
- Multiple file updates → Use `/docs:update-complex`
- Major restructuring → Use `/docs:update-complex`
- Diagram generation → Use `/docs:update-complex --diagrams`
- Notion synchronization → Use `/docs:sync-notion`

### Writing Good Update Descriptions

**Good Descriptions:**
- ✓ "Add POST /api/costs endpoint with authentication requirements"
- ✓ "Fix broken links in architecture overview section"
- ✓ "Update Azure SQL connection instructions to use Managed Identity"

**Poor Descriptions:**
- ✗ "Fix docs" (too vague)
- ✗ "Update stuff in API section" (unclear what to update)
- ✗ "Make it better" (no specific action)

**Rule**: Be specific about what to change and where.

## Performance Expectations

**Target SLAs:**
- Read file: <5 seconds
- Apply updates: <60 seconds
- Quality validation: <30 seconds
- Write file: <5 seconds
- Create commit (if requested): <20 seconds

**Total Duration:**
- Without validation: 1-2 minutes
- With validation: 2-3 minutes
- With validation + commit: 3-4 minutes

## Related Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/docs:update-complex` | Multi-file updates with diagram generation | Architectural changes, full documentation refresh |
| `/docs:sync-notion` | Sync documentation to Knowledge Vault | Archive completed work, share knowledge |
| `/agent:log-activity` | Track documentation work | Log all documentation updates for reporting |

## Agent Activity Logging

All simple documentation updates are automatically logged:

```bash
# Automatic logging
/docs:update-simple "README.md" "Update installation instructions"

# Agent activity logged as:
Session: documentation-orchestrator-2025-10-22-1430
Status: completed
Duration: 142 seconds
Deliverables: README.md updated
Metrics: Quality score 87/100, brand compliant
```

View activity: `.claude/logs/AGENT_ACTIVITY_LOG.md`

## Support

For documentation command questions:
- **Email**: Consultations@BrooksideBI.com
- **Phone**: +1 209 487 2047

---

**Update Simple Documentation Command** - Establish fast, reliable documentation updates that maintain Brookside BI brand compliance and technical quality through intelligent single-file modification workflows.

**Designed for**: Organizations requiring quick documentation maintenance with automated quality enforcement that supports sustainable knowledge management practices.
