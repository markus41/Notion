# notion-webflow-syncer

**Agent ID:** `notion-webflow-syncer`
**Version:** 1.0.0
**Category:** Integration Orchestration
**Dependencies:** notion-mcp-expert, webflow-api-expert, notion-content-parser, asset-migration-handler

**Best for:** Organizations scaling content publishing across teams while maintaining centralized governance and quality standards.

---

## Purpose

Establish end-to-end blog publishing orchestration to automate content flow from Notion to Webflow. Coordinates API integrations, content transformation, image migration, category mapping, and sync state tracking. Designed for teams publishing structured content at scale (10-100+ posts/month) with zero manual CMS entry.

**Business Value:**
- Publish 50 blog posts in 3 minutes vs. 2+ hours manually (95% time savings)
- Maintain single source of truth in Notion (no content drift between systems)
- Enforce category taxonomy consistency (fail-fast validation prevents broken references)
- Track sync state automatically (Last Synced timestamps, Webflow Item IDs)
- Enable batch operations with error recovery (partial success accepted, failed items logged)

---

## Capabilities

### Core Operations
- **Single Post Sync** - Orchestrate 8-step workflow from Notion fetch to Webflow publish
- **Batch Sync** - Process 50+ posts with rate limiting and error recovery
- **Category Mapping** - Convert Notion relation to Webflow reference ID
- **SEO Generation** - Auto-create title (60 char) + description (155 char)
- **Sync State Tracking** - Update Notion with Webflow Item ID, timestamps, status
- **Validation** - Pre-flight checks before publish

### Integration Points
- **Notion Blog Posts DB** - Source content (ID: `97adad39160248d697868056a0075d9c`)
- **Knowledge Vault Categories** - Category taxonomy (relation source)
- **Webflow Blog-Categories** - Category reference collection
- **Webflow Editorials** - Published blog posts collection

---

## Tools

### 1. sync_notion_to_webflow

**Purpose:** Orchestrate single post publish from Notion to Webflow

**When to use:**
- Publish new blog post
- Update existing post content
- Republish after edits

**Function Signature:**
```python
def sync_notion_to_webflow(
    notion_page_id: str,
    force_update: bool = False,
    dry_run: bool = False
) -> SyncResponse
```

**Sync Flow (8 Steps):**

```
1. Fetch Notion Page
   ↓ @notion-mcp-expert.notion_fetch_page
   ↓ Returns: properties + content blocks

2. Validate Required Fields
   ↓ Check: Post Title, Summary, Category, Hero Image, Body
   ↓ Fail fast if missing

3. Parse Content to Markdown
   ↓ @notion-content-parser.parse_notion_page_to_markdown
   ↓ Returns: clean Markdown

4. Convert Markdown to HTML
   ↓ @notion-content-parser.convert_markdown_to_html
   ↓ Returns: sanitized HTML

5. Extract & Migrate Images
   ↓ @asset-migration-handler.extract_and_upload_images
   ↓ Returns: Webflow CDN URLs, URL mapping

6. Map Category
   ↓ Query Notion relation → Lookup Webflow reference ID
   ↓ Fail fast if category missing from Webflow

7. Generate SEO Metadata
   ↓ Auto-create SEO Title (Post Title, max 60 chars)
   ↓ Auto-create SEO Description (Summary, max 155 chars)

8. Publish to Webflow
   ↓ @webflow-api-expert.webflow_publish_item
   ↓ Update Notion sync tracking fields
   ↓ Return: published URL, Webflow Item ID
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `notion_page_id` | string | Yes | Notion page ID or URL |
| `force_update` | boolean | No (default: false) | Overwrite if already synced |
| `dry_run` | boolean | No (default: false) | Validate without publishing |

**Example:**
```bash
/agent notion-webflow-syncer sync-to-webflow \
  --page-id "abc123def456" \
  --force-update
```

**Success Output:**
```json
{
  "agent": "notion-webflow-syncer",
  "status": "success",
  "operation": "sync_notion_to_webflow",
  "data": {
    "notion_page_id": "abc123def456",
    "webflow_item_id": "item_xyz789",
    "action_taken": "updated",
    "published_url": "https://yoursite.com/editorial/intro-to-llms-for-bi",
    "sync_details": {
      "category_mapped": "AI/ML → ref_cat123",
      "tags_mapped": ["AI", "Business Intelligence"],
      "hero_image_uploaded": true,
      "hero_image_url": "https://uploads-ssl.webflow.com/...",
      "markdown_word_count": 2500,
      "html_generated": true,
      "seo_title": "Introduction to LLMs for Business Intelligence",
      "seo_description": "Comprehensive guide to using large language models in BI workflows for automated insights, natural language querying, and report generation."
    },
    "notion_updates": {
      "webflow_item_id_set": true,
      "sync_status_updated": "Synced",
      "last_synced_timestamp": "2025-10-26T10:30:00Z"
    }
  },
  "metadata": {
    "execution_time_ms": 3500,
    "api_calls_made": 8
  },
  "warnings": []
}
```

**Error Handling:**
- Missing required field → `"Required field missing: Hero Image"`
- Category not in Webflow → `"CategoryMappingError: 'Data Science' not found in Webflow. Available: Engineering, AI/ML, ..."`
- Image upload timeout → Skip image, publish without, log warning
- Already synced + no `--force` → Skip, return message

---

### 2. batch_sync_notion_to_webflow

**Purpose:** Batch publish unpublished posts

**When to use:**
- Initial blog migration (50+ posts)
- Scheduled bulk publishing
- Sync all draft posts weekly

**Function Signature:**
```python
def batch_sync_notion_to_webflow(
    filter_status: str = "Draft",
    max_items: int = 50
) -> BatchSyncResponse
```

**Batch Process:**
1. Query Notion Blog Posts DB with filters:
   - Status = `filter_status` (default: "Draft" OR "In Review")
   - Sync Status = "Not Synced" OR "Sync Failed"
   - Limit = `max_items`
2. For each post: Call `sync_notion_to_webflow`
3. Aggregate results (success count, failure count)
4. Write failures to `.claude/data/blog-sync-failures.jsonl`

**Example:**
```bash
/agent notion-webflow-syncer batch-sync \
  --filter-status "Draft" \
  --max-items 50
```

**Success Output:**
```json
{
  "agent": "notion-webflow-syncer",
  "status": "partial_success",
  "operation": "batch_sync_notion_to_webflow",
  "data": {
    "total_items": 50,
    "successful": 47,
    "failed": 3,
    "skipped": 0,
    "success_rate": 0.94,
    "results": [
      {
        "notion_page_id": "abc123",
        "webflow_item_id": "item_001",
        "status": "success",
        "published_url": "https://yoursite.com/editorial/post-1"
      },
      {
        "notion_page_id": "def456",
        "webflow_item_id": null,
        "status": "failure",
        "error": "CategoryMappingError: 'Data Science' not in Webflow"
      },
      {
        "notion_page_id": "ghi789",
        "webflow_item_id": null,
        "status": "failure",
        "error": "ImageUploadTimeout: Hero image >10MB"
      }
    ]
  },
  "metadata": {
    "execution_time_ms": 125000,
    "api_calls_made": 235
  },
  "next_steps": [
    "Fix category mapping for 1 post (add 'Data Science' to Webflow)",
    "Compress hero image for 1 post (reduce from 12MB to <10MB)",
    "Review failures: .claude/data/blog-sync-failures.jsonl"
  ]
}
```

**Retry Policy:**
- Transient failures (timeout, rate limit) → Auto-retry up to 3x with exponential backoff
- Permanent failures (missing category, validation) → Log, skip, continue
- Partial success accepted → 47 of 50 = valid outcome

---

### 3. build_category_cache

**Purpose:** Load category mappings at startup

**When to use:**
- System initialization
- After new Webflow categories added
- Manual cache refresh

**Function Signature:**
```python
def build_category_cache() -> CacheBuildResponse
```

**Process:**
1. Query Webflow Blog-Categories collection via @webflow-api-expert
2. Build mapping: `{notion_category_name: webflow_reference_id}`
3. Store in memory for fast lookups during sync

**Example Cache Structure:**
```python
category_cache = {
    "Engineering": "ref_abc123",
    "AI/ML": "ref_def456",
    "Business Intelligence": "ref_ghi789",
    "Data Engineering": "ref_jkl012",
    "Cloud Architecture": "ref_mno345",
    "DevOps": "ref_pqr678",
    "Security": "ref_stu901",
    "Product Management": "ref_vwx234",
    "Leadership": "ref_yz567"
}
```

**Example:**
```bash
/agent notion-webflow-syncer build-category-cache
```

**Success Output:**
```json
{
  "agent": "notion-webflow-syncer",
  "status": "success",
  "data": {
    "categories_mapped": 9,
    "cache": {
      "Engineering": "ref_abc123",
      "AI/ML": "ref_def456",
      ...
    }
  }
}
```

**Error Handling:**
- Webflow collection not found → Clear error, provide setup instructions
- Empty collection → Warn, return empty cache

---

### 4. map_category

**Purpose:** Convert Notion category to Webflow reference ID

**When to use:**
- During sync workflow (Step 6)
- Validation before publish

**Function Signature:**
```python
def map_category(notion_category_name: str) -> str
```

**Logic:**
```python
def map_category(notion_category_name: str) -> str:
    """
    Map Notion category name to Webflow reference ID.

    Fails fast if category missing - prevents publishing with
    broken category references.

    Args:
        notion_category_name: Category name from Notion relation field

    Returns:
        Webflow reference ID (e.g., "ref_abc123")

    Raises:
        CategoryMappingError: Category not found in Webflow
    """
    if notion_category_name not in category_cache:
        available = ", ".join(category_cache.keys())
        raise CategoryMappingError(
            f"Category '{notion_category_name}' exists in Notion Knowledge Vault "
            f"but not found in Webflow Blog-Categories collection.\n\n"
            f"Available categories: {available}\n\n"
            f"Fix: Add '{notion_category_name}' to Webflow Blog-Categories collection, "
            f"then run /agent notion-webflow-syncer build-category-cache"
        )

    return category_cache[notion_category_name]
```

**Example:**
```bash
/agent notion-webflow-syncer map-category --name "Engineering"
# Returns: "ref_abc123"
```

**Error Example:**
```
❌ CategoryMappingError: Category 'Data Science' exists in Notion Knowledge Vault
but not found in Webflow Blog-Categories collection.

Available categories: Engineering, AI/ML, Business Intelligence, Data Engineering,
Cloud Architecture, DevOps, Security, Product Management, Leadership

Fix: Add 'Data Science' to Webflow Blog-Categories collection, then run:
/agent notion-webflow-syncer build-category-cache
```

---

### 5. generate_seo_metadata

**Purpose:** Auto-create SEO title and description

**When to use:**
- During sync workflow (Step 7)
- Preview SEO before publish

**Function Signature:**
```python
def generate_seo_metadata(
    post_title: str,
    summary: str
) -> SEOMetadata
```

**Logic:**
```python
# SEO Title: Use Post Title, truncate if > 60 chars
seo_title = post_title[:60]

# SEO Description: First 155 chars of Summary
seo_description = summary[:155]

# If Summary empty, extract from first paragraph of Body
if not seo_description:
    first_paragraph = extract_first_paragraph(body_content)
    seo_description = first_paragraph[:155]
```

**Example:**
```bash
/agent notion-webflow-syncer generate-seo \
  --title "A Very Long Title That Exceeds Sixty Characters For SEO Optimization Testing Purposes" \
  --summary "A comprehensive guide to using large language models in business intelligence workflows, covering automated insights, natural language querying, report generation, and more advanced topics that exceed the 155 character limit for SEO descriptions."
```

**Output:**
```json
{
  "seo_title": "A Very Long Title That Exceeds Sixty Characters For SEO Op",
  "seo_title_truncated": true,
  "seo_description": "A comprehensive guide to using large language models in business intelligence workflows, covering automated insights, natural language querying, rep",
  "seo_description_truncated": true
}
```

---

## Integration with Other Agents

### Upstream Dependencies
- **notion-mcp-expert** - Fetch Notion content, update sync tracking
- **notion-content-parser** - Transform content to HTML
- **webflow-api-expert** - Publish to Webflow
- **asset-migration-handler** - Process images

### Downstream Consumers
- **Slash commands** - `/blog:sync-post`, `/blog:bulk-sync` invoke this agent

---

## Error Codes

| Code | Name | Resolution |
|------|------|------------|
| NS_001 | CategoryMappingError | Add missing category to Webflow, refresh cache |
| NS_002 | RequiredFieldMissing | Add missing field to Notion page |
| NS_003 | SyncAlreadyCompleted | Use `--force-update` to overwrite |
| NS_004 | ValidationFailed | Fix validation errors before retry |

---

## Contact & Support

**Brookside BI Support:** Consultations@BrooksideBI.com | +1 209 487 2047

**Related Agents:**
- [webflow-api-expert](./webflow-api-expert.md)
- [notion-mcp-expert](./notion-mcp-expert.md)
- [notion-content-parser](./notion-content-parser.md)
- [asset-migration-handler](./asset-migration-handler.md)

---

**Agent Version:** 1.0.0
**Last Updated:** 2025-10-26
**Status:** Production-Ready
