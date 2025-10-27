---
description: Publish single blog post from Notion to Webflow
category: Blog Publishing
---

# Sync Blog Post

Publish a single blog post from Notion Blog Posts database to Webflow Editorial collection. Coordinates content transformation, image migration, category mapping, and sync state tracking.

## Usage

```bash
/blog:sync-post <notion-page-id> [--force-update] [--validate-only]
```

## Parameters

- **`notion-page-id`** (required) - Notion page ID (32-char UUID) or full page URL
- **`--force-update`** (optional) - Overwrite existing Webflow item even if already synced
- **`--validate-only`** (optional) - Dry run - validate content without publishing

## Examples

**Publish new post:**
```bash
/blog:sync-post abc123def456
```

**Update existing post:**
```bash
/blog:sync-post abc123def456 --force-update
```

**Validate before publishing:**
```bash
/blog:sync-post abc123def456 --validate-only
```

**Using full Notion URL:**
```bash
/blog:sync-post https://notion.so/workspace/Post-Title-abc123def456
```

## Workflow

This command delegates to **@notion-webflow-syncer** which coordinates:

1. **Fetch Notion Page** → @notion-mcp-expert
2. **Validate Required Fields** → Post Title, Summary, Category, Hero Image, Body
3. **Parse Content** → @notion-content-parser (Notion blocks → Markdown)
4. **Convert to HTML** → @notion-content-parser (Markdown → sanitized HTML)
5. **Migrate Images** → @asset-migration-handler (validate pixel art, upload to Webflow)
6. **Map Category** → Query Notion relation, lookup Webflow reference ID
7. **Generate SEO** → Auto-create title (60 char) + description (155 char)
8. **Publish to Webflow** → @webflow-api-expert (create or update item)
9. **Update Notion** → Write Webflow Item ID, Last Synced timestamp, Sync Status

## Success Output

```
✅ Blog post published successfully

Title: Introduction to LLMs for Business Intelligence
Category: AI/ML → ref_abc123
Hero Image: Validated (1920x1080, pixel art compliant)
Published URL: https://yoursite.com/editorial/intro-to-llms-for-bi
Webflow Item ID: item_xyz789

Sync Details:
- Content: 2,500 words, 10 min read
- Images: 1 hero + 3 inline images migrated
- SEO: Title (41 chars), Description (150 chars)

Notion Updates:
- Webflow Item ID: item_xyz789
- Last Synced: 2025-10-26T10:30:00Z
- Sync Status: Synced

Duration: 3.5 seconds
```

## Error Scenarios

### Missing Required Field
```
❌ Sync Failed: Required Field Missing

Post "Introduction to LLMs" is missing required field: Hero Image

Fix: Add a hero image to the Notion page (16:9 aspect ratio, 1600x900+ resolution)
```

### Category Not in Webflow
```
❌ Sync Failed: Category Mapping Error

Post "Data Science Fundamentals" references category "Data Science" which doesn't
exist in Webflow Blog-Categories collection.

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

Fix: Either change category in Notion or add "Data Science" to Webflow Blog-Categories collection,
then run: /blog:validate-schema
```

### Pixel Art Validation Failed
```
❌ Sync Failed: Hero Image Validation Error

Hero image failed pixel art validation:
- Anti-aliasing detected (pixel art requires hard edges)
- Aspect ratio 1.50 (expected 16:9 = 1.78)

Fix: Re-export image from design tool with:
- Nearest-neighbor scaling (no anti-aliasing)
- 16:9 aspect ratio (e.g., 1920x1080)
- Hard edges (no smoothing)
```

### Already Synced
```
ℹ️  Post Already Synced

Post "Introduction to LLMs" was last synced on 2025-10-25T14:20:00Z.

Webflow Item ID: item_xyz789
Published URL: https://yoursite.com/editorial/intro-to-llms-for-bi

To overwrite, run:
/blog:sync-post abc123def456 --force-update
```

## Validation Checks (--validate-only)

When run with `--validate-only`, performs all checks without publishing:

```
🔍 Blog Post Validation

✅ Required Fields
   - Post Title: "Introduction to LLMs for Business Intelligence"
   - Summary: 150 characters
   - Category: AI/ML (mapped to ref_abc123)
   - Hero Image: Present
   - Body: 2,500 words
   - Publish Date: 2025-10-26

✅ Hero Image Validation
   - Dimensions: 1920x1080 (16:9)
   - Hard edges: Pass
   - Color palette: 20 colors (< 32 max)
   - File size: 450KB (optimized from 2.5MB)

✅ Content Transformation
   - Markdown parsing: 8 headings, 5 code blocks
   - HTML generation: Sanitized, 15KB
   - Images: 3 inline images ready for migration

✅ SEO Metadata
   - Title: "Introduction to LLMs for Business Intelligence" (41 chars)
   - Description: "Comprehensive guide to using large language models..." (150 chars)

✅ Category Mapping
   - Notion: AI/ML
   - Webflow: ref_abc123 (Blog-Categories)

✅ Ready to Publish
```

## Related Commands

- `/blog:bulk-sync` - Batch publish multiple posts
- `/blog:validate-schema` - Verify system configuration before sync

## Agent Invocation

This command invokes:
- **@notion-webflow-syncer** (primary orchestrator)
  - **@notion-mcp-expert** (Notion data access)
  - **@notion-content-parser** (content transformation)
  - **@asset-migration-handler** (image processing)
  - **@webflow-api-expert** (Webflow publishing)

## Best Practices

1. **Validate First** - Run with `--validate-only` before first publish
2. **Check Hero Image** - Ensure 16:9 aspect ratio, pixel art compliant
3. **Review Category** - Verify category exists in both Notion and Webflow
4. **Monitor Sync Status** - Check Notion Sync Status field after publish
5. **Use Force Sparingly** - Only use `--force-update` when intentionally overwriting

## Troubleshooting

**Issue:** "Notion page not found"
**Solution:** Verify page ID, check Notion API integration has access to page

**Issue:** "Image upload timeout"
**Solution:** Compress hero image to <5MB, verify stable internet connection

**Issue:** "Webflow API rate limit exceeded"
**Solution:** Wait 60 seconds, retry automatically with exponential backoff

**Issue:** "HTML sanitization removed content"
**Solution:** Check for unsupported HTML tags (scripts, iframes), use supported Markdown syntax

---

**Command Version:** 1.0.0
**Category:** Blog Publishing
**Agent:** @notion-webflow-syncer
**Status:** Production-Ready
