---
description: Batch migrate blog posts from Notion to Webflow with phased validation
category: Blog Publishing
---

# Migrate Batch

Establish systematic content migration pipeline to transfer existing blog posts from multiple Notion databases (Knowledge Vault, Example Builds, Editorial) to Webflow CMS collections. Designed for organizations executing initial content backfills (50+ posts) or ongoing batch publishing operations with automated validation, asset optimization, and rollback capability.

## Usage

```bash
/blog:migrate-batch --mode=<mode> --database=<database> [options]
```

## Parameters

### Required

- **`--mode`** - Execution mode determining migration behavior
  - `dry-run` - Validation only, no Webflow publishing (0 API writes)
  - `sample` - Test migration with 3-5 posts published as drafts
  - `full` - Complete migration of all ready posts

- **`--database`** - Source Notion database to migrate from
  - `knowledge-vault` - Published Knowledge Vault articles → Webflow Editorial
  - `example-builds` - Published Example Builds → Webflow Portfolio
  - `editorial` - Notion Editorial database → Webflow Editorial (future)

### Optional

- **`--publish-live`** - Publish posts with `_draft=false` (live on site)
  - Default: `false` (publish as drafts for review)
  - Use with caution in `full` mode

- **`--sample-count=N`** - Number of posts to migrate in sample mode
  - Default: `3` (short, medium, long post for representative testing)
  - Range: `1-10`

- **`--batch-size=N`** - Concurrent posts per batch (rate limiting)
  - Default: `5` (respects Webflow 60 req/min limit)
  - Range: `1-10`

- **`--filter`** - Additional filtering criteria (optional)
  - `category=<name>` - Only migrate specific category
  - `status=<status>` - Only migrate specific status
  - `published-after=<date>` - Only posts after date (YYYY-MM-DD)

## Examples

### Dry-Run Validation (Recommended First Step)

Validate all Knowledge Vault articles without publishing:

```bash
/blog:migrate-batch --mode=dry-run --database=knowledge-vault
```

**Output**: Validation report showing ✅ Ready, ⚠️ Warnings, ❌ Blocked posts with actionable fixes

---

### Sample Batch Test (Draft Publishing)

Test migration with 3 representative posts published as drafts:

```bash
/blog:migrate-batch --mode=sample --database=knowledge-vault
```

**Output**: 3 draft Webflow URLs for manual review + validation report + approval prompt

---

### Sample Batch with Custom Count

Test with 5 posts instead of default 3:

```bash
/blog:migrate-batch --mode=sample --database=knowledge-vault --sample-count=5
```

---

### Full Migration (Draft Mode - Safest)

Migrate all ready posts from Knowledge Vault as drafts:

```bash
/blog:migrate-batch --mode=full --database=knowledge-vault
```

**Output**: Real-time progress tracking, batch-by-batch status, final migration report

---

### Full Migration (Live Publishing - Production)

Migrate all ready posts and publish live immediately:

```bash
/blog:migrate-batch --mode=full --database=knowledge-vault --publish-live
```

⚠️ **Warning**: Posts will be live on public site. Ensure dry-run and sample validation completed successfully first.

---

### Filtered Migration (Specific Category)

Migrate only AI/ML category posts:

```bash
/blog:migrate-batch --mode=full --database=knowledge-vault --filter=category="AI/ML"
```

---

### Example Builds Migration

Migrate Example Builds to Webflow Portfolio collection:

```bash
/blog:migrate-batch --mode=full --database=example-builds
```

---

## Workflow

This command delegates to **@content-migration-orchestrator** which executes the 6-phase migration pipeline:

### Phase 1: Discovery & Extraction (1-2 sec/post)
- Query source Notion database with filters
- Fetch full page content via @notion-mcp-expert
- Extract metadata (title, summary, category, hero image, body, publish date)
- Filter candidates based on publishing criteria

### Phase 2: Content Transformation (0.5-1 sec/post)
- Parse Notion blocks to Markdown via @notion-content-parser
- Convert Markdown to sanitized HTML (CommonMark + GFM)
- Detect visual content (Mermaid diagrams, Lottie animations)
- Calculate metadata (word count, read time, heading structure)

### Phase 3: Asset Processing (2-5 sec/image)
- Extract images from Notion content via @asset-migration-handler
- Validate hero image (pixel art: 16:9, hard edges, <32 colors, 1600x900+)
- Optimize images (PNG/JPEG → WebP, 85% quality, max 1920px, typical 82% reduction)
- Upload to Webflow CDN
- Generate URL mapping (Notion S3 URLs → Webflow CDN URLs)

### Phase 4: Pre-Publish Validation (0.5-1 sec/post)
- Verify required fields present (title, summary, category, hero image, body)
- Validate category mapping (Notion category → Webflow reference ID exists)
- Check content structure (headings, code blocks, images)
- Generate SEO metadata (title <60 chars, description <155 chars)

### Phase 5: Webflow Publishing (1-2 sec/post)
- Map Notion fields to Webflow collection schema via @webflow-api-specialist
- Create new CMS item (POST /collections/{collectionId}/items)
- Set draft status (`_draft=true` by default unless `--publish-live`)
- Handle rate limiting (60 req/min with exponential backoff)
- Retry failed publishes (3 attempts with circuit breaker)

### Phase 6: Sync Tracking Update (0.5-1 sec/post)
- Update Notion page with Webflow metadata via @notion-mcp-expert
  - Webflow Item ID
  - Last Synced timestamp
  - Sync Status = "Synced"
  - Migration Status = "Migrated"
- Record in migration state tracker (`.claude/data/migration-state.json`)
- Log activity to Agent Activity Hub

**Total Duration Estimate**:
- **Dry-run**: 2-3 seconds/post (validation only, no publishing)
- **Sample (3 posts)**: 20-30 seconds total
- **Full (50 posts)**: 3-5 minutes total (parallel batches of 5)

---

## Success Output

### Dry-Run Validation Report

```
🔍 Migration Validation Report - Knowledge Vault → Webflow Editorial

Total Posts Analyzed: 52
✅ Ready to Migrate: 45
⚠️  Warnings (can proceed): 4
❌ Blocked (fix required): 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ READY TO MIGRATE (45 posts)

These posts meet all publishing criteria and can proceed immediately.

Sample posts:
- "Introduction to LLMs for Business Intelligence" (2,500 words, AI/ML)
- "Azure Functions Best Practices" (1,800 words, Cloud Architecture)
- "Power BI Embedding Guide" (3,200 words, Business Intelligence)
... +42 more

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  WARNINGS (4 posts - can proceed with reduced quality)

1. "Data Science Fundamentals" (id: abc123def456)
   - Hero image aspect ratio 1.50 (expected 16:9 = 1.78)
   - Fix: Re-export image with correct dimensions
   - Impact: Minor visual inconsistency

2. "Machine Learning Pipeline" (id: def456ghi789)
   - Color palette 38 colors (exceeds 32 max for pixel art)
   - Fix: Reduce color palette in design tool
   - Impact: Minor brand guideline deviation

3. "Kubernetes Architecture" (id: ghi789jkl012)
   - Character count appears to be 6 (expected 3-5)
   - Fix: Adjust hero image composition
   - Impact: Minor visual consistency

4. "DevOps Automation" (id: jkl012mno345)
   - Missing category relation (using fallback "Engineering")
   - Fix: Set explicit category in Notion
   - Impact: Auto-assigned category may be incorrect

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ BLOCKED (3 posts - must fix before migration)

1. "Security Best Practices" (id: mno345pqr678)
   ❌ Missing hero image (required)
   Fix: Add hero image to Notion page (16:9, 1600x900+, pixel art)

2. "API Design Patterns" (id: pqr678stu901)
   ❌ Category "API Development" not found in Webflow
   Fix: Either:
      - Change category in Notion to existing option
      - Add "API Development" to Webflow Blog-Categories collection

3. "Database Optimization" (id: stu901vwx234)
   ❌ Anti-aliasing detected in hero image (pixel art violation)
   Fix: Re-export image with nearest-neighbor scaling (no smoothing)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 CONTENT METRICS

Total word count: 125,000 words
Average read time: 8.5 minutes
Total images: 120 (hero: 52, inline: 68)
Mermaid diagrams: 15
Lottie animations: 3

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS

1. Fix 3 blocked posts (hero images, category mapping, pixel art compliance)
2. Run sample migration to test with 3 posts:
   /blog:migrate-batch --mode=sample --database=knowledge-vault
3. After sample validation, run full migration:
   /blog:migrate-batch --mode=full --database=knowledge-vault
```

---

### Sample Batch Migration Report

```
✅ Sample Batch Migration Complete

Batch ID: batch_2025-10-26T15:30:00Z_sample
Database: Knowledge Vault → Webflow Editorial
Mode: Sample (3 posts as drafts)
Duration: 24 seconds

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MIGRATED POSTS (3/3 successful)

1. "Introduction to LLMs for Business Intelligence" [SHORT]
   ✅ Webflow Item ID: item_abc123
   📝 Draft URL: https://yoursite.webflow.io/editorial/intro-to-llms-for-bi
   📊 2,500 words, 10 min read, 1 hero + 3 inline images
   ⏱️  Duration: 8.2 seconds

2. "Azure Functions Best Practices" [MEDIUM]
   ✅ Webflow Item ID: item_def456
   📝 Draft URL: https://yoursite.webflow.io/editorial/azure-functions-best-practices
   📊 1,800 words, 7 min read, 1 hero + 2 inline images
   ⏱️  Duration: 6.8 seconds

3. "Power BI Embedding Guide" [LONG]
   ✅ Webflow Item ID: item_ghi789
   📝 Draft URL: https://yoursite.webflow.io/editorial/power-bi-embedding-guide
   📊 3,200 words, 13 min read, 1 hero + 5 inline images, 2 Mermaid diagrams
   ⏱️  Duration: 9.4 seconds

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ASSET MIGRATION SUMMARY

Total images processed: 11
Original size: 18.5 MB
Optimized size: 3.2 MB
Savings: 82.7%

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MANUAL REVIEW REQUIRED

Please review the 3 draft posts in Webflow:
1. Verify content formatting (headings, code blocks, images)
2. Check hero image quality and pixel art compliance
3. Validate category assignments
4. Review SEO metadata (title, description)

After review, proceed with:
✅ Approve: /blog:migrate-batch --mode=full --database=knowledge-vault
❌ Rollback: /blog:rollback-batch batch_2025-10-26T15:30:00Z_sample
```

---

### Full Migration Progress (Real-Time)

```
🚀 Full Batch Migration in Progress

Database: Knowledge Vault → Webflow Editorial
Mode: Full (draft publishing)
Total posts: 45
Batch size: 5 concurrent posts

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Batch 1/9 (Posts 1-5) ████████████████████ 100% Complete (18.2s)
Batch 2/9 (Posts 6-10) ████████████████████ 100% Complete (19.8s)
Batch 3/9 (Posts 11-15) ████████████████████ 100% Complete (17.5s)
Batch 4/9 (Posts 16-20) ████████████████████ 100% Complete (20.1s)
Batch 5/9 (Posts 21-25) ████████████████████ 100% Complete (18.9s)
Batch 6/9 (Posts 26-30) ████████████████████ 100% Complete (19.3s)
Batch 7/9 (Posts 31-35) ████████████████████ 100% Complete (18.7s)
Batch 8/9 (Posts 36-40) ████████████████████ 100% Complete (17.9s)
Batch 9/9 (Posts 41-45) ████████████████████ 100% Complete (16.5s)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ MIGRATION COMPLETE

Total Duration: 2 minutes 47 seconds
Successful: 45/45 (100%)
Failed: 0
Average time per post: 3.7 seconds

Batch ID: batch_2025-10-26T16:00:00Z_full

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ASSET MIGRATION SUMMARY

Total images processed: 120
Original size: 285 MB
Optimized size: 48 MB
Savings: 83.2%
Mermaid diagrams: 15 (client-side rendering enabled)
Lottie animations: 3 (web components embedded)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NOTION UPDATES

All 45 posts updated with:
- Webflow Item ID
- Last Synced timestamp
- Sync Status = "Synced"
- Migration Status = "Migrated"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

NEXT STEPS

1. Review draft posts in Webflow CMS
2. Publish posts individually or bulk publish when ready
3. Verify webhook sync working for future edits
4. Archive migration batch: /blog:migration-status batch_2025-10-26T16:00:00Z_full
```

---

## Error Scenarios

### Validation Failure (Dry-Run)

```
❌ Dry-Run Validation Failed

Database: Knowledge Vault
Total posts analyzed: 52
Blocked posts: 12 (23%)

Common issues:
- Missing hero images: 5 posts
- Category mapping errors: 4 posts
- Pixel art violations: 3 posts

Fix required before proceeding. See detailed validation report above.
```

**Resolution**: Address blocked posts individually, re-run dry-run validation

---

### Hero Image Validation Failure (Sample/Full)

```
❌ Post Failed: Pixel Art Validation Error

Post: "Security Best Practices" (id: mno345pqr678)

Hero image failed pixel art validation:
- Anti-aliasing detected (pixel art requires hard edges)
- Aspect ratio 1.50 (expected 16:9 = 1.78)
- Color palette 45 colors (exceeds 32 max)

Fix:
1. Re-export image from design tool with:
   - Nearest-neighbor scaling (no anti-aliasing)
   - 16:9 aspect ratio (e.g., 1920x1080)
   - Reduced color palette (<32 colors)
2. Update Notion page with corrected image
3. Re-run migration (skipped post will be retried)

Migration continuing with remaining posts...
```

**Resolution**: Fix image, migration continues with other posts

---

### Category Mapping Error

```
❌ Post Failed: Category Mapping Error

Post: "API Design Patterns" (id: pqr678stu901)

Post references category "API Development" which doesn't exist in Webflow
Blog-Categories collection.

Available categories:
- Engineering
- AI/ML
- Business Intelligence
- Data Engineering
- Cloud Architecture
- DevOps
- Security
- Product Management
- Leadership

Fix (choose one):
1. Change category in Notion to existing option
2. Add "API Development" to Webflow Blog-Categories collection
3. Run: /blog:validate-schema to refresh category cache

Migration continuing with remaining posts...
```

**Resolution**: Fix category mapping, migration continues

---

### Webflow API Rate Limit

```
⚠️  Rate Limit Exceeded - Auto-Retrying

Webflow API rate limit exceeded (60 req/min)
Current batch paused for 30 seconds...
Retrying batch 5/9 (Posts 21-25)

This is normal for large migrations. Progress will resume automatically.
```

**Resolution**: Automatic retry with exponential backoff, no user action needed

---

### Notion Update Failure

```
⚠️  Notion Update Failed (Non-Blocking)

Post: "Introduction to LLMs" (id: abc123def456)
Webflow: ✅ Published successfully (item_xyz789)
Notion: ❌ Failed to update sync metadata

Error: Notion API timeout (exceeded 10s)

Impact: Post successfully published to Webflow but Notion metadata not updated.

Manual cleanup required:
1. Open Notion page: https://notion.so/workspace/abc123def456
2. Set Webflow Item ID: item_xyz789
3. Set Last Synced: 2025-10-26T16:15:00Z
4. Set Sync Status: Synced
5. Set Migration Status: Migrated

Migration continuing with remaining posts...
```

**Resolution**: Manual Notion update, does not block migration

---

## Validation Checks

### Pre-Migration Validation (Dry-Run)

**Required Fields**:
- ✅ Post Title (Title property)
- ✅ Summary (Summary property, 100-200 chars)
- ✅ Category (Category relation to Webflow categories)
- ✅ Hero Image (Hero Image property, 16:9 pixel art)
- ✅ Body (Page content with headings, paragraphs)
- ✅ Publish Date (Published property or Created Time)

**Hero Image Validation**:
- ✅ Aspect ratio: 16:9 (1.78 ratio, tolerance ±0.05)
- ✅ Minimum dimensions: 1600x900 (retina displays)
- ✅ Hard edges: No anti-aliasing (pixel art aesthetic)
- ✅ Color palette: Max 32 colors
- ✅ Character count: 3-5 visible figures (brand guideline)
- ✅ Background: Opaque (no transparency)

**Category Mapping**:
- ✅ Notion category exists in Webflow Blog-Categories collection
- ✅ Webflow reference ID retrieved successfully

**Content Validation**:
- ✅ Word count: >300 words (minimum viable content)
- ✅ Heading structure: At least 1 H2 or H3
- ✅ Code blocks: Valid language syntax highlighting
- ✅ Images: Valid URLs, accessible
- ✅ Mermaid diagrams: Valid syntax for client-side rendering
- ✅ Lottie animations: Valid JSON URLs

**SEO Metadata**:
- ✅ Title: 30-60 characters (optimal for search results)
- ✅ Description: 120-155 characters (optimal for snippets)

---

## Related Commands

- `/blog:sync-post <page-id>` - Publish single post (manual operation)
- `/blog:bulk-sync` - Batch publish from queue (alternative approach)
- `/blog:rollback-batch <batch-id>` - Rollback migration batch
- `/blog:migration-status <batch-id>` - View migration batch details
- `/blog:validate-schema` - Verify Webflow schema and category mappings

---

## Agent Invocation

This command invokes:

- **@content-migration-orchestrator** (primary coordinator)
  - **@notion-mcp-expert** (Notion data access: fetch, search, update)
  - **@notion-content-parser** (content transformation: Markdown, HTML, metadata)
  - **@asset-migration-handler** (image processing: validation, optimization, upload)
  - **@webflow-api-specialist** (Webflow publishing: create items, handle rate limits)

**Execution Pattern**:

```
User → /blog:migrate-batch
  ↓
@content-migration-orchestrator
  ↓
  ├─ Phase 1: @notion-mcp-expert.search() → candidate posts
  ├─ Phase 2: @notion-content-parser.parse_to_markdown() → @notion-content-parser.convert_to_html()
  ├─ Phase 3: @asset-migration-handler.extract_and_upload_images()
  ├─ Phase 4: Internal validation (required fields, category mapping, SEO)
  ├─ Phase 5: @webflow-api-specialist.create_collection_item()
  └─ Phase 6: @notion-mcp-expert.update_page() → sync metadata
```

---

## Best Practices

### 1. Always Start with Dry-Run

**❌ Don't**:
```bash
/blog:migrate-batch --mode=full --database=knowledge-vault --publish-live
```

**✅ Do**:
```bash
# Step 1: Validate
/blog:migrate-batch --mode=dry-run --database=knowledge-vault

# Step 2: Test with sample
/blog:migrate-batch --mode=sample --database=knowledge-vault

# Step 3: Review drafts, then proceed
/blog:migrate-batch --mode=full --database=knowledge-vault

# Step 4 (optional): Publish live after reviewing drafts
# Manually publish in Webflow CMS or use --publish-live flag
```

---

### 2. Fix Validation Issues Before Migration

Address all ❌ blocked posts before running sample or full migration:
- Add missing hero images
- Fix pixel art violations (aspect ratio, anti-aliasing, color palette)
- Resolve category mapping errors
- Ensure required fields populated

---

### 3. Test with Sample Before Full Migration

Sample mode provides:
- Representative testing (short, medium, long posts)
- Draft publishing (safe to review before going live)
- Validation of entire pipeline without full commitment
- Rollback capability for quick cleanup

---

### 4. Monitor Real-Time Progress

During full migration, watch for:
- Batch completion times (should average 15-20 seconds per batch)
- Error messages (failed posts, rate limits, API errors)
- Asset optimization metrics (size reduction, upload success)
- Notion update success (sync metadata written)

---

### 5. Use Rollback for Mistakes

If migration publishes incorrect content:
```bash
# Unpublish (set to draft, keep in Webflow)
/blog:rollback-batch <batch-id>

# Permanent deletion (use with caution)
/blog:rollback-batch <batch-id> --delete
```

---

### 6. Verify Webhook Sync After Migration

After full migration, test webhook sync by editing a migrated post in Notion:
1. Edit post title in Notion
2. Wait 30 seconds
3. Verify change reflected in Webflow
4. If not syncing, check Migration Status field (should be "Migrated")

---

## Troubleshooting

### Issue: "No posts found to migrate"

**Cause**: Database query returned no results

**Solutions**:
1. Verify database selection is correct (`--database=knowledge-vault` vs. `example-builds`)
2. Check Notion database has posts with `Published = true` or `Reusability = Evergreen`
3. Remove restrictive filters (`--filter` parameter)
4. Run search manually: `/agent @notion-mcp-expert search-database knowledge-vault`

---

### Issue: "Dry-run shows 100% blocked posts"

**Cause**: Systemic validation issues (missing fields, wrong database structure)

**Solutions**:
1. Verify Notion database schema matches expected structure
2. Check required properties exist: Title, Summary, Category, Hero Image, Body
3. Run schema validation: `/blog:validate-schema`
4. Review sample Notion page to understand field naming mismatches

---

### Issue: "Sample migration succeeded, but full migration fails"

**Cause**: Sample selected only valid posts, full migration includes edge cases

**Solutions**:
1. Review dry-run validation report for specific blocked posts
2. Fix blocked posts individually
3. Re-run dry-run to verify fixes
4. Use `--filter` to exclude problematic posts temporarily
5. Consider incremental migration by category: `--filter=category="AI/ML"`

---

### Issue: "Migration stuck at 'Batch 3/9' for >5 minutes"

**Cause**: Rate limit exhaustion or API timeout

**Solutions**:
1. Wait 2-3 minutes for automatic retry
2. Check Webflow API status: https://status.webflow.com
3. Verify internet connectivity
4. Review migration state: `/blog:migration-status <batch-id>`
5. If persistently stuck, contact support with batch ID

---

### Issue: "Images uploaded but not appearing in Webflow posts"

**Cause**: URL rewriting failed or asset upload incomplete

**Solutions**:
1. Verify asset URLs in Webflow CMS item (should be `https://uploads-ssl.webflow.com/...`)
2. Check image optimization logs for upload failures
3. Re-run migration with `--force-update` to re-upload assets
4. Manually upload images via Webflow Asset Manager if needed

---

### Issue: "Notion updates failing consistently"

**Cause**: Notion API authentication or permission issues

**Solutions**:
1. Verify Notion integration has write access to database
2. Check Notion API key in Azure Key Vault: `notion-api-key`
3. Test Notion API directly: `/agent @notion-mcp-expert update-page <page-id>`
4. Review Notion API rate limits (3 req/sec)
5. If persistent, update Notion manually using batch CSV export

---

### Issue: "Category mapping errors for all posts"

**Cause**: Webflow Blog-Categories collection not synced or accessible

**Solutions**:
1. Verify Blog-Categories collection exists in Webflow
2. Run: `/blog:validate-schema` to refresh category cache
3. Manually create missing categories in Webflow
4. Check Webflow API token has read access to Blog-Categories collection
5. Review category spelling (case-sensitive matching)

---

### Issue: "Migration completed but webhook sync not working"

**Cause**: Migration Status field not updated or webhook not checking field

**Solutions**:
1. Verify Migration Status field added to Notion database schema
2. Check webhook conditional logic deployed to Azure Functions
3. Test webhook manually: Edit migrated post title in Notion, wait 30s
4. Review webhook logs in Azure Portal for errors
5. Ensure webhook signature verification passing

---

**Command Version:** 1.0.0
**Category:** Blog Publishing
**Agent:** @content-migration-orchestrator
**Status:** Production-Ready
