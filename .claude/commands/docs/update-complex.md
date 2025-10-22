# Update Complex Documentation

**Category**: Documentation
**Command**: `/docs:update-complex`
**Agent**: `@documentation-orchestrator` (orchestrates 3-5 agents in parallel waves)
**Purpose**: Multi-file documentation updates with diagram generation, cross-reference validation, and repository synchronization

**Best for**: Organizations requiring comprehensive documentation overhauls with automated quality enforcement, visual diagram generation, and systematic consistency across file hierarchies.

## Command Syntax

```bash
/docs:update-complex <scope> <description> [options]
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `scope` | string/pattern | Yes | Files to update (single file, glob pattern, or comma-separated list) |
| `description` | string | Yes | Comprehensive description of changes across all files |

### Optional Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--diagrams` | Generate Mermaid diagrams for architecture/workflows | false |
| `--sync-repo` | Sync to GitHub repository after updates | false |
| `--sync-notion` | Sync to Notion Knowledge Vault after updates | false |
| `--full-refresh` | Complete documentation refresh with all quality checks | false |
| `--parallel-agents` | Maximum agents to run in parallel | 3 |
| `--commit` | Auto-commit with conventional message | false |
| `--create-pr` | Create GitHub Pull Request after commit | false |

## Usage Examples

### Example 1: Update Multiple API Documentation Files

```bash
/docs:update-complex "docs/api/*.md" \
  "Migrate all API documentation to new authentication method using Azure Managed Identity" \
  --diagrams
```

**What Happens:**
1. Analysis identifies 5 files matching pattern
2. Wave 1: 3 parallel `@markdown-expert` agents format files
3. Wave 2: `@mermaid-diagram-expert` creates auth flow diagram
4. Wave 3: Cross-file validation ensures consistency
5. Quality score: 92/100 (EXCELLENT)
6. Duration: 6 minutes 47 seconds

### Example 2: Architecture Documentation Refresh

```bash
/docs:update-complex "README.md,docs/architecture/*.md,CLAUDE.md" \
  "Document new event sourcing pattern for cost tracking with architecture diagrams" \
  --diagrams \
  --full-refresh \
  --commit
```

**Duration**: 12-15 minutes
**Output**: 7 files updated, 3 diagrams generated, auto-committed

### Example 3: Repository-Wide Brand Transformation

```bash
/docs:update-complex "**/*.md" \
  "Apply Brookside BI brand voice transformations to all documentation" \
  --full-refresh \
  --sync-repo \
  --create-pr
```

**Duration**: 18-22 minutes
**Output**: 23 files transformed, PR created with quality report

## Workflow Execution

### Multi-Wave Parallel Execution

```
Phase 1: Analysis & Planning (30-60 seconds)
├─ Identify all files matching scope
├─ Parse dependencies between files
├─ Create execution plan with wave sequencing
└─ Determine required specialized agents

Phase 2: Wave 1 - Content Updates (Parallel)
├─ Agent 1: @markdown-expert formats file A
├─ Agent 2: @markdown-expert formats file B
├─ Agent 3: @markdown-expert formats file C
└─ Wait for all Wave 1 agents to complete

Phase 3: Wave 2 - Diagram Generation (Parallel)
├─ Agent 4: @mermaid-diagram-expert creates diagrams
└─ Wait for all Wave 2 agents to complete

Phase 4: Wave 3 - Cross-Validation (Sequential)
├─ Validate cross-file consistency
├─ Check all internal links
└─ Ensure uniform terminology

Phase 5: Wave 4 - Repository Sync (Optional)
├─ @documentation-sync pushes to GitHub
└─ Triggers external integrations

Phase 6: Completion & Reporting
├─ Aggregate quality scores
├─ Generate comprehensive report
└─ Return results to user
```

## Performance Expectations

**Target SLAs:**
- 3-5 files: 8-12 minutes
- 6-10 files: 12-18 minutes
- 11-20 files: 18-25 minutes
- 20+ files: 25-35 minutes

**Parallel Efficiency:**
- 3 agents: 60-70% time savings
- 5 agents: 75-85% time savings

## Related Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `/docs:update-simple` | Single file updates | Quick fixes, minor changes |
| `/docs:sync-notion` | Sync to Knowledge Vault | Archive completed work |

---

**Update Complex Documentation Command** - Establish comprehensive documentation management through intelligent multi-agent orchestration and systematic quality enforcement.

**Designed for**: Organizations scaling documentation practices who require enterprise-grade quality consistency and parallel execution efficiency.
