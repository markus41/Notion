# Agent Activity Logging Template

**Purpose**: Standardized section to be added to all agent specification files for consistent activity logging guidance.

**Location in agent files**: Add this section near the end of each agent specification, before "Related Resources" or as the final operational section.

---

## Template Content (Copy from here)

---

## Activity Logging

### Automatic Logging ✅

This agent's work is **automatically captured** by the Activity Logging Hook when invoked via the Task tool. The system logs session start, duration, files modified, deliverables, and related Notion items without any manual intervention.

**No action required** for standard work completion - the hook handles tracking automatically.

### Manual Logging Required 🔔

**MUST use `/agent:log-activity` for these special events**:

1. **Work Handoffs** 🔄 - When transferring work to another agent or team member
2. **Blockers** 🚧 - When progress is blocked and requires external help
3. **Critical Milestones** 🎯 - When reaching significant progress requiring stakeholder visibility
4. **Key Decisions** ✅ - When session completion involves important architectural/cost/strategic choices
5. **Early Termination** ⏹️ - When stopping work before completion due to scope change or discovered issues

### Command Format

```bash
/agent:log-activity @{AGENT-NAME} {status} "{detailed-description}"

# Status values: completed | blocked | handed-off | in-progress

# Example for this agent:
/agent:log-activity @{AGENT-NAME} completed "{Agent-specific work description with context, decisions, and next steps}"
```

### Best Practices

**✅ DO**:
- Provide specific, actionable details (not generic "work complete")
- Include file paths, URLs, or Notion page IDs for context
- Document decisions with rationale (especially cost/architecture choices)
- Mention handoff recipient explicitly (@agent-name or team member)
- Explain blockers with specific resolution requirements

**❌ DON'T**:
- Log routine completions (automatic hook handles this)
- Use vague descriptions without actionable information
- Skip logging handoffs (causes workflow continuity breaks)
- Forget to update status when blockers are resolved

**→ Full Documentation**: [Agent Activity Center](./../docs/agent-activity-center.md)

---

## Template Usage Instructions

### How to Apply to Agent Files

1. **Read the agent specification file** to understand its current structure
2. **Locate insertion point**:
   - Best position: After "Best Practices" or "Examples" section, before "Related Resources"
   - Alternative: As final operational section before file end
3. **Copy template content** from "Template Content (Copy from here)" section above
4. **Replace placeholders**:
   - `{AGENT-NAME}` → Replace with actual agent name (e.g., `@cost-analyst`)
   - `{Agent-specific work description...}` → Replace with agent-specific example relevant to agent's domain
5. **Adjust formatting** if needed to match agent file's existing style
6. **Verify links** work correctly (relative paths to docs)

### Example Application

**Before** (agent file without logging section):
```markdown
## Related Resources

- [Cost Management](../docs/cost-management.md)
- [Software Tracker](../docs/notion-schema.md#software-tracker)

---

**Last Updated**: 2025-10-26
```

**After** (agent file with logging section added):
```markdown
## Activity Logging

### Automatic Logging ✅

This agent's work is **automatically captured** by the Activity Logging Hook when invoked via the Task tool. The system logs session start, duration, files modified, deliverables, and related Notion items without any manual intervention.

**No action required** for standard work completion - the hook handles tracking automatically.

### Manual Logging Required 🔔

**MUST use `/agent:log-activity` for these special events**:

1. **Work Handoffs** 🔄 - When transferring work to another agent or team member
2. **Blockers** 🚧 - When progress is blocked and requires external help
3. **Critical Milestones** 🎯 - When reaching significant progress requiring stakeholder visibility
4. **Key Decisions** ✅ - When session completion involves important architectural/cost/strategic choices
5. **Early Termination** ⏹️ - When stopping work before completion due to scope change or discovered issues

### Command Format

```bash
/agent:log-activity @cost-analyst {status} "{detailed-description}"

# Status values: completed | blocked | handed-off | in-progress

# Example for this agent:
/agent:log-activity @cost-analyst completed "Quarterly cost analysis complete - identified $450/month savings through Microsoft consolidation. Detailed recommendations in Software Tracker with 12-month ROI projections."
```

### Best Practices

**✅ DO**:
- Provide specific, actionable details (not generic "work complete")
- Include file paths, URLs, or Notion page IDs for context
- Document decisions with rationale (especially cost/architecture choices)
- Mention handoff recipient explicitly (@agent-name or team member)
- Explain blockers with specific resolution requirements

**❌ DON'T**:
- Log routine completions (automatic hook handles this)
- Use vague descriptions without actionable information
- Skip logging handoffs (causes workflow continuity breaks)
- Forget to update status when blockers are resolved

**→ Full Documentation**: [Agent Activity Center](./../docs/agent-activity-center.md)

---

## Related Resources

- [Cost Management](../docs/cost-management.md)
- [Software Tracker](../docs/notion-schema.md#software-tracker)

---

**Last Updated**: 2025-10-26
```

### Agent-Specific Example Customizations

**For @cost-analyst**:
```bash
/agent:log-activity @cost-analyst completed "Q4 spend analysis complete - identified $450/month savings via Microsoft consolidation. Recommendations in Software Tracker with 12-month ROI."
```

**For @build-architect**:
```bash
/agent:log-activity @build-architect handed-off "Architecture complete, transferring to @code-generator. ADR-2025-10-26-Azure-Functions documents all technical decisions. Bicep templates ready for implementation."
```

**For @research-coordinator**:
```bash
/agent:log-activity @research-coordinator completed "Research swarm complete: Market 78/100, Technical 92/100, Cost 81/100, Risk 85/100. Overall viability: 84/100 (High). Recommend immediate build approval."
```

**For @deployment-orchestrator**:
```bash
/agent:log-activity @deployment-orchestrator completed "Production deployment successful - https://app.example.com live. Zero-downtime migration, all health checks green. Cost: $12.40/month (F1 tier)."
```

**For @viability-assessor**:
```bash
/agent:log-activity @viability-assessor blocked "Assessment halted - insufficient market data for TAM calculation. Need competitive analysis from @market-researcher before proceeding."
```

**For @knowledge-curator**:
```bash
/agent:log-activity @knowledge-curator completed "Knowledge archival complete: 3 technical docs, 2 ADRs, 1 runbook created from Build-2025-10-21-CostTracker. All linked to Knowledge Vault with searchable tags."
```

---

## Batch Update Script

To apply this template to all 38 agent files programmatically:

```powershell
# Script: .claude/utils/update-agent-logging.ps1
# Purpose: Batch-add Activity Logging section to all agent files

param(
    [switch]$DryRun = $false
)

$agentFiles = Get-ChildItem -Path ".claude/agents/*.md" -File
$templateContent = Get-Content -Path ".claude/templates/agent-logging-template.md" -Raw

# Extract template section (between "Template Content (Copy from here)" markers)
$templateSection = ($templateContent -split "## Template Content \(Copy from here\)")[1]
$templateSection = ($templateSection -split "---`n`n## Template Usage Instructions")[0]

foreach ($agentFile in $agentFiles) {
    $agentName = $agentFile.BaseName
    $content = Get-Content -Path $agentFile.FullName -Raw

    # Check if agent already has Activity Logging section
    if ($content -match "## Activity Logging") {
        Write-Host "✓ $agentName - Already has Activity Logging section (skipping)" -ForegroundColor Green
        continue
    }

    # Replace placeholder {AGENT-NAME} with actual agent name
    $customizedTemplate = $templateSection -replace '\{AGENT-NAME\}', "@$agentName"

    # Find insertion point (before "Related Resources" or at end)
    if ($content -match "## Related Resources") {
        $updatedContent = $content -replace "(## Related Resources)", "$customizedTemplate`n`$1"
    } else {
        # Add at end before final separator
        $updatedContent = $content.TrimEnd() + "`n`n$customizedTemplate"
    }

    if ($DryRun) {
        Write-Host "Would update: $agentName" -ForegroundColor Yellow
    } else {
        Set-Content -Path $agentFile.FullName -Value $updatedContent -NoNewline
        Write-Host "✓ Updated: $agentName" -ForegroundColor Green
    }
}

Write-Host "`nBatch update complete!" -ForegroundColor Cyan
```

**Usage**:
```powershell
# Dry run (preview changes without modifying files)
.\.claude\utils\update-agent-logging.ps1 -DryRun

# Execute (actually update all agent files)
.\.claude\utils\update-agent-logging.ps1
```

---

**Last Updated**: 2025-10-26
**Purpose**: Standardize activity logging guidance across all 38 agent specifications
**Status**: Template ready for deployment
