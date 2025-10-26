# /agent:process-queue

Process queued agent activity entries and sync to Notion Agent Activity Hub. Establish reliable asynchronous synchronization between local agent activity logs and Notion database through batch processing with retry logic.

**Best for**: Organizations requiring resilient multi-tier activity tracking where Notion sync operates asynchronously to prevent blocking agent work.

## Usage

```bash
/agent:process-queue [--batch-size=N] [--max-retries=N] [--dry-run]
```

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `--batch-size` | Integer | 10 | Number of entries to process in one run |
| `--max-retries` | Integer | 3 | Maximum retry attempts per entry |
| `--dry-run` | Flag | false | Validate queue without syncing to Notion |

## Examples

### Basic Processing
```bash
/agent:process-queue
```
Processes up to 10 queued entries with default retry settings

### Large Batch Processing
```bash
/agent:process-queue --batch-size=50 --max-retries=5
```
Processes up to 50 entries with 5 retry attempts each

### Dry Run Validation
```bash
/agent:process-queue --dry-run
```
Validates queue entries without syncing to Notion or deleting entries

## Command Definition

```markdown
You are a Notion Queue Processor responsible for syncing queued agent activity entries to the Notion Agent Activity Hub database. Execute the PowerShell processor script with appropriate parameters.

## Workflow

### Phase 1: Parse Command Arguments
1. Extract batch-size, max-retries, and dry-run flags from user command
2. Set default values if not provided:
   - batch-size: 10
   - max-retries: 3
   - dry-run: false
3. Validate numeric parameters are positive integers

### Phase 2: Execute Processor Script
1. Build PowerShell command with parameters:
   ```powershell
   .\.claude\utils\process-notion-queue.ps1 -BatchSize <N> -MaxRetries <N> [-DryRun]
   ```

2. Execute script via Bash tool

3. Capture output and exit code:
   - Exit 0: All entries processed successfully
   - Exit 1: Some entries failed (partial success)
   - Exit 2: All entries failed

### Phase 3: Report Results to User
1. Parse processor output for summary statistics
2. Display results in user-friendly format:
   ```
   ## Notion Queue Processing Results

   **Status**: [Success/Partial Success/Failed]
   **Processed**: X of Y entries
   **Successful**: X entries synced to Notion
   **Failed**: Y entries (see logs for details)

   [Notion URL links to successfully created pages]
   ```

3. If failures occurred, provide troubleshooting guidance:
   - Check Notion API connectivity
   - Verify Agent Activity Hub database exists
   - Review processor log: `.claude/logs/notion-queue-processor.log`
   - Suggest retry with increased max-retries

### Phase 4: Cleanup (if successful)
1. Verify successfully processed entries removed from queue
2. Confirm queue file size reduced
3. Report remaining queue size to user

## Error Handling

**Queue File Not Found**:
- Message: "No queued entries to process - queue is empty"
- Action: No error, exit gracefully

**Notion MCP Connection Failed**:
- Message: "Failed to connect to Notion MCP - check configuration"
- Action: Entries remain in queue, suggest troubleshooting
- Log location: `.claude/logs/notion-queue-processor.log`

**JSON Parsing Errors**:
- Message: "Invalid queue entry format on line X"
- Action: Skip invalid entries, process remaining valid entries
- Suggest manual queue file inspection

**Partial Failure**:
- Message: "X of Y entries failed to sync - entries remain in queue"
- Action: Provide failed session IDs for investigation
- Suggest retry or manual Notion entry creation

## Integration Points

**Queue Source**: `.claude/data/notion-sync-queue.jsonl`
- Populated by `.claude/hooks/auto-log-agent-activity.ps1`
- JSONL format (one JSON object per line)

**Target Database**: Agent Activity Hub
- Data Source ID: `7163aa38-f3d9-444b-9674-bde61868bd2b`
- URL: https://www.notion.so/72b879f213bd4edb9c59b43089dbef21

**Processor Log**: `.claude/logs/notion-queue-processor.log`
- Detailed processing log with timestamps
- Error messages and stack traces
- Retry attempt tracking

## Scheduling Options

### Manual Execution
```bash
/agent:process-queue
```
Run on-demand when user wants to sync queued entries

### Periodic Execution (Windows Task Scheduler)
```powershell
# Create scheduled task to run every 5 minutes
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File C:\Users\MarkusAhling\Notion\.claude\utils\process-notion-queue.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5)
Register-ScheduledTask -TaskName "NotionQueueProcessor" -Action $action -Trigger $trigger -Description "Sync agent activity to Notion every 5 minutes"
```

### Hybrid Approach (Recommended)
- Hook-triggered immediate Tier 2 (Markdown) + Tier 3 (JSON) logging
- Notion queue accumulates entries
- Scheduled processor syncs to Notion every 5 minutes
- Manual /agent:process-queue for immediate sync needs

## Success Metrics

**Sync Latency**: Average time from queue entry to Notion sync <5 minutes
**Success Rate**: >95% of entries successfully synced
**Retry Efficiency**: <10% of entries require retries
**Queue Backlog**: <50 entries in queue at any time (indicator of healthy processing)

## Troubleshooting

**Queue Growing Unbounded (>100 entries)**:
- Increase batch size: `/agent:process-queue --batch-size=100`
- Reduce scheduled processor interval (e.g., every 2 minutes)
- Check Notion API rate limits
- Verify MCP server connectivity

**High Failure Rate (>20% failed)**:
- Review processor log for common error patterns
- Test Notion MCP manually: `mcp__notion__notion-create-pages`
- Verify database schema matches expected properties
- Check network connectivity to Notion API

**Duplicate Entries in Notion**:
- Verify queue processing removes successfully synced entries
- Check for concurrent processor executions (should be serialized)
- Review Session ID uniqueness

## Notes

- Processor uses exponential backoff for retries (2s, 4s, 8s, ...)
- Failed entries remain in queue for future processing attempts
- Notion MCP integration placeholder requires actual implementation
- Queue file uses JSONL format for append-only, crash-resistant logging
```

## Examples

### Example 1: Clear Backlog After Outage
```bash
# Notion was down for 30 minutes, now 60 entries in queue
/agent:process-queue --batch-size=60 --max-retries=5

# Output:
## Notion Queue Processing Results

**Status**: Success
**Processed**: 60 of 60 entries
**Successful**: 58 entries synced to Notion
**Failed**: 2 entries (see logs for details)

Failed entries: viability-assessor-2025-10-26-1430, repo-analyzer-2025-10-26-1445
Suggestion: Retry failed entries with: /agent:process-queue
```

### Example 2: Validate Queue Before Processing
```bash
# Check queue health without syncing
/agent:process-queue --dry-run

# Output:
## Notion Queue Validation (Dry Run)

**Total Entries**: 15
**Valid Entries**: 14
**Invalid Entries**: 1 (line 7: JSON parse error)

Agents in queue:
- @cost-analyst: 3 entries
- @database-architect: 5 entries
- @markdown-expert: 4 entries
- @repo-analyzer: 2 entries

Recommendation: Remove invalid entry and process queue: /agent:process-queue
```

### Example 3: Emergency Sync During Critical Session
```bash
# Important work just completed, need immediate Notion sync
/agent:process-queue --batch-size=1

# Output:
## Notion Queue Processing Results

**Status**: Success
**Processed**: 1 of 8 entries
**Successful**: 1 entry synced to Notion

🔗 https://www.notion.so/72b879f213bd4edb9c59b43089dbef21?p=abc123...

Remaining queue: 7 entries (will be processed by scheduled task)
```

---

This command establishes reliable asynchronous synchronization for agent activity tracking, enabling resilient multi-tier logging where local logs provide immediate feedback and Notion provides team-accessible source of truth.
