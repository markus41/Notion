---
description: Batch publish unpublished blog posts from Notion to Webflow
category: Blog Publishing
---

# Bulk Sync Blog Posts

Batch publish multiple blog posts from Notion Blog Posts database to Webflow Editorial collection. Processes posts with Status="Draft" or "In Review" that haven't been synced yet. Includes error recovery and partial success handling.

## Usage

```bash
/blog:bulk-sync [--max-items 50] [--filter-status "Draft"] [--dry-run]
```

## Parameters

- **`--max-items`** (optional, default: 50) - Maximum posts to sync in batch
- **`--filter-status`** (optional, default: "Draft,In Review") - Notion Status filter
- **`--dry-run`** (optional) - Simulate without publishing (validation only)

## Examples

**Publish up to 50 draft posts:**
```bash
/blog:bulk-sync
```

**Publish specific number:**
```bash
/blog:bulk-sync --max-items 25
```

**Publish only "Published" status posts (initial migration):**
```bash
/blog:bulk-sync --filter-status "Published" --max-items 100
```

**Dry run (validate without publishing):**
```bash
/blog:bulk-sync --dry-run
```

## Workflow

This command delegates to **@notion-webflow-syncer** which:

1. **Query Notion Database** → Filter by Status + Sync Status, sort by Publish Date
2. **For Each Post** → Execute same workflow as `/blog:sync-post`
3. **Aggregate Results** → Count successes, failures, skipped
4. **Log Failures** → Write to `.claude/data/blog-sync-failures.jsonl`
5. **Return Summary** → Success rate, failure details, next steps

**Query Filters Applied:**
- Status = `filter_status` (default: "Draft" OR "In Review")
- Sync Status = "Not Synced" OR "Sync Failed"
- Limit = `max_items`
- Sort = Publish Date descending (newest first)

## Success Output (Partial Success Example)

```
📊 Bulk Sync Results

Total Attempted: 50
✅ Successful: 47 (94%)
❌ Failed: 3 (6%)
⏭️  Skipped: 0

Duration: 2 minutes 45 seconds
API Calls: 235 (Notion: 52, Webflow: 183)

Successful Posts:
1. "Introduction to LLMs" → https://yoursite.com/editorial/intro-to-llms
2. "Power BI Governance" → https://yoursite.com/editorial/power-bi-governance
... (44 more)

Failed Posts:
1. ❌ "ML Model Deployment Strategies"
   Error: CategoryMappingError: 'Data Science' not in Webflow Blog-Categories
   Fix: Add 'Data Science' category to Webflow, then retry

2. ❌ "Azure Cost Optimization Techniques"
   Error: ImageUploadTimeout: Hero image 12MB (max 10MB)
   Fix: Compress hero image, then retry

3. ❌ "Real-Time BI Dashboards with SignalR"
   Error: WebflowAPIError: Rate limit exceeded (auto-retry queued)
   Fix: Automatic retry in 60 seconds

Next Steps:
- Fix category mapping for 1 post
- Compress hero image for 1 post
- 1 post queued for auto-retry

View failures: .claude/data/blog-sync-failures.jsonl
Retry failed posts: /blog:retry-failed
```

## Error Recovery

**Partial Success Philosophy:**
- 47 of 50 successful = **valid outcome** (94% success rate acceptable)
- Failed posts logged for manual review/retry
- Successful posts remain published (no rollback)

**Retry Policy:**

| Error Type | Retry Eligible | Action |
|------------|----------------|--------|
| Transient (timeout, rate limit) | Yes | Auto-retry up to 3x with exponential backoff |
| Validation (missing field, bad data) | No | Log error, skip, continue batch |
| Dependency (missing category) | No | Fix dependency first, manual retry |
| Infrastructure (Webflow down) | Yes | Delay 5 min, retry entire batch |

**Dead Letter Queue:**

Failed posts written to `.claude/data/blog-sync-failures.jsonl`:
```json
{"timestamp": "2025-10-26T10:30:00Z", "page_id": "abc123", "title": "ML Model Deployment", "error": "CategoryMappingError: 'Data Science' not in Webflow", "retry_count": 0, "retry_eligible": false}
{"timestamp": "2025-10-26T10:30:15Z", "page_id": "def456", "title": "Azure Cost Optimization", "error": "ImageUploadTimeout: Hero image 12MB", "retry_count": 0, "retry_eligible": true}
```

## Dry Run Output

When run with `--dry-run`, validates all posts without publishing:

```
🔍 Bulk Sync Validation (Dry Run)

Posts to Process: 50

✅ Ready to Publish: 47 (94%)
- "Introduction to LLMs" (AI/ML, 2,500 words, hero image valid)
- "Power BI Governance" (Business Intelligence, 3,200 words, hero image valid)
... (45 more)

❌ Would Fail: 3 (6%)
1. "ML Model Deployment"
   Issue: Category 'Data Science' not in Webflow
   Fix Required: Add category before sync

2. "Azure Cost Optimization"
   Issue: Hero image 12MB (max 10MB)
   Fix Required: Compress image

3. "Real-Time BI Dashboards"
   Issue: Summary field empty (SEO description required)
   Fix Required: Add summary

⚠️  Validation Complete (No posts published)

To publish, run:
/blog:bulk-sync --max-items 47  # Skip failed posts
```

## Performance Metrics

**Expected Duration:**
- 50 posts: ~3 minutes (3.6 seconds/post average with rate limiting)
- 100 posts: ~6 minutes (sequential processing to avoid rate limits)

**API Calls Per Post:**
- Notion: 1 fetch + 1 update = 2 calls
- Webflow: 1 category cache + 1 image upload + 1 item publish = 3 calls
- Total: ~5 API calls/post (250 calls for 50 posts)

**Rate Limiting:**
- Webflow: 60 req/min (standard) or 120 req/min (CMS plan)
- Notion: ~3 req/second (throttled if excessive)
- Strategy: Add 1.2s delay between posts to stay within limits

## Related Commands

- `/blog:sync-post` - Publish single post
- `/blog:validate-schema` - Pre-flight validation before bulk sync
- `/blog:retry-failed` - Retry posts from dead letter queue (future)

## Agent Invocation

This command invokes:
- **@notion-webflow-syncer** (batch orchestration)
  - Internally calls same agents as `/blog:sync-post` for each post

## Best Practices

1. **Validate Schema First** - Run `/blog:validate-schema` before first bulk sync
2. **Start Small** - Test with `--max-items 10` before full batch
3. **Use Dry Run** - Always run `--dry-run` first to preview failures
4. **Fix Common Errors** - Address category mapping, image sizes before retry
5. **Monitor Progress** - Watch output for patterns in failures
6. **Retry Failed** - Use dead letter queue to retry after fixing issues

## Troubleshooting

**Issue:** "Too many failures (>20%)"
**Solution:** Stop batch, run `/blog:validate-schema`, fix systemic issues (missing categories, image sizes)

**Issue:** "Webflow rate limit exceeded frequently"
**Solution:** Reduce `--max-items` to 25, increase delay between posts

**Issue:** "Notion API timeout"
**Solution:** Check internet connection, retry batch (successful posts skipped automatically)

**Issue:** "Partial batch completed, how to resume?"
**Solution:** Re-run command - already synced posts automatically skipped (check Sync Status field)

---

**Command Version:** 1.0.0
**Category:** Blog Publishing
**Agent:** @notion-webflow-syncer
**Status:** Production-Ready
