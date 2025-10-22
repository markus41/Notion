# Sync Agent Logs to Notion

Process the Notion sync queue to create Agent Activity Hub database entries using Notion MCP, completing the 3-tier agent activity tracking system.

**Command**: `/agent:sync-notion-logs`

---

## Implementation

You are processing the Notion sync queue. Follow these steps:

1. **Read Queue File**: `.claude/data/notion-sync-queue.jsonl` (JSONL format, one JSON per line)
2. **For each pending entry** (where `syncStatus` is "pending" and `retryCount` < 3):
   - Create Notion page using `mcp__notion__notion-create-pages`
   - Database ID: `72b879f2-13bd-4edb-9c59-b43089dbef21`
   - Map properties:
     - `sessionId` → Session ID (title)
     - `agentName` → Agent Name (select)
     - `status` → Status (select, convert "in-progress" to "In Progress")
     - `workDescription` → Work Description (rich_text)
     - `startTime` → `date:Start Time:start` + `date:Start Time:is_datetime: 1`
3. **On success**: Remove entry from queue file
4. **On failure**: Increment `retryCount`, update `syncStatus` to "retry", keep in queue
5. **If retryCount >= 3**: Update `syncStatus` to "failed", keep in queue for manual review
6. **Report statistics**: Total processed, succeeded, failed, remaining

---

## What This Does

1. Reads pending entries from `.claude/data/notion-sync-queue.jsonl`
2. Creates Notion pages in Agent Activity Hub database (via Notion MCP)
3. Removes successfully synced entries from queue
4. Retries failed entries (up to 3 attempts)
5. Reports sync statistics

---

## When to Use

- **After automatic logging**: Hook queues Notion syncs, run this command to sync them
- **Periodic sync**: Run daily/weekly to process accumulated queue
- **After Notion downtime**: Sync queued entries after connectivity restored
- **Manual verification**: Check that automatic logging is working end-to-end

---

## Prerequisites

✅ Notion MCP connected and authenticated
✅ Agent Activity Hub database exists (ID: `72b879f2-13bd-4edb-9c59-b43089dbef21`)
✅ Queue file exists with pending entries

---

## Options

- `--dry-run`: Show what would be synced without actually syncing
- `--status-only`: Report queue status without processing
- `--max-retries N`: Override default retry limit (default: 3)

---

## Example Usage

```bash
# Process all pending entries
/agent:sync-notion-logs

# Check what needs syncing without processing
/agent:sync-notion-logs --dry-run

# Check queue status
/agent:sync-notion-logs --status-only
```

---

## Expected Output

```markdown
## Notion Sync Complete

**Queue Status**: 4 entries processed
- ✅ **Succeeded**: 4 entries synced to Notion
- 🔄 **Retried**: 0 entries
- ❌ **Failed**: 0 entries
- ⏳ **Remaining**: 0 entries in queue

**Synced Sessions**:
- cost-feasibility-analyst-2025-10-22-0517 → [Notion page](https://notion.so/...)
- viability-assessor-2025-10-22-0506 → [Notion page](https://notion.so/...)
- market-researcher-2025-10-22-0508 → [Notion page](https://notion.so/...)
- technical-analyst-2025-10-22-0509 → [Notion page](https://notion.so/...)

✅ All agent activities synchronized to Notion
```

---

## Troubleshooting

**No entries found**:
- Queue file is empty (normal if all synced)
- Hook not capturing agent invocations (check settings.local.json)

**Notion MCP errors**:
- Verify Notion MCP connection: `claude mcp list`
- Check database ID is correct
- Ensure database shared with integration

**Repeated failures**:
- Check Notion API rate limits
- Verify database permissions
- Review error logs in hook log file

---

**Brookside BI - Establish transparent agent activity tracking through reliable Notion synchronization**
