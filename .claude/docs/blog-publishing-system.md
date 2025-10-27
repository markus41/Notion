# Blog Publishing System Specification

**Version:** 1.0.0
**Status:** Production-Ready
**Last Updated:** 2025-10-26

---

## Executive Summary

Establish automated blog publishing infrastructure to streamline content delivery from Notion to Webflow. Designed for organizations requiring centralized content management with distributed publishing across web properties.

**Architecture:** Notion-first (Webflow serves as read-only publishing terminal)
**Core Agents:** 5 specialized agents handling API integration, content transformation, and orchestration
**Integration Points:** Innovation Nexus Knowledge Vault (category taxonomy), Webflow Editorial collection

**Business Value:** Eliminates manual copy-paste workflows, ensures brand consistency through automated tone validation, maintains single source of truth in Notion while enabling public web presence.

---

## System Architecture

### Architectural Decisions

**Decision 1: Notion-First, Webflow Read-Only**

Webflow operates as a rendering layer—a dumb publishing terminal that displays content Notion provides. Any edits made in Webflow are overwritten on next sync. This eliminates:
- Bidirectional sync complexity
- Conflict detection requirements
- Webhook infrastructure
- State reconciliation logic

**Rationale:** Organizational malpractice to maintain two sources of truth. Notion already serves as system of record for Innovation Nexus Knowledge Vault, Ideas Registry, Research Hub, and Example Builds. Blog content follows the same pattern.

**Decision 2: Category Taxonomy via Relation Field**

Blog Posts database uses **relation field** (not duplicate select field) pointing to existing Knowledge Vault Categories database. This ensures:
- Single source of truth for taxonomy
- Category changes propagate instantly across systems
- Filtering/grouping works uniformly
- Zero drift between Knowledge Vault and blog content

**Alternative rejected:** Duplicate select field with 9 hardcoded categories would require maintaining identical option lists in two locations. This creates synchronization debt and inevitable divergence.

**Decision 3: SEO Metadata Auto-Generation**

No manual SEO fields in Notion. Metadata derived deterministically during sync:
```
SEO Title = Post Title (truncate at 60 chars if exceeded)
SEO Description = First 155 chars of Summary field
```

**Rationale:** Writers shouldn't think about meta tags—they should write coherent summaries. The sync agent transforms content appropriately for each platform. Manual SEO fields add friction without measurable value. Escape hatch available (add override fields later) if edge cases emerge.

**Decision 4: Image Validation Now, Generation Phase 2**

**Phase 1 (Current):** Manual upload to Notion + automated pixel art validation
**Phase 2 (Future):** Add `pixel-art-generator` agent with Claude API integration for cover generation

**Rationale:** Image generation is cosmetic. Publishing infrastructure is critical path. Ship the plumbing before the paint job.

**Decision 5: 5 Core Agents (Minimal Viable Sync)**

Phase 1 excludes tone-enforcer (nice to have), pixel-art-generator (cosmetic), and all 11 Morningstar agents (financial content deferred to Phase 2).

**Critical path logic:** Can't publish without sync. Can't sync without API wrappers, content transformation, and asset handling. Everything else is feature creep.

---

## Data Flow Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Notion Blog Posts DB                       │
│                  (System of Record)                           │
│                                                                │
│  • Post Title                                                 │
│  • Summary                                                    │
│  • Category (relation → Knowledge Vault Categories)          │
│  • Tags (multi_select)                                       │
│  • Publish Date                                              │
│  • Hero Image (files)                                        │
│  • Body (rich_text, Markdown)                                │
│  • Status (Draft | In Review | Published)                   │
│  • Webflow Item ID (sync tracking)                          │
│  • Last Synced (sync tracking)                              │
│  • Sync Status (sync tracking)                              │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 │ Trigger: /blog:sync-post <page-id>
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│            @notion-webflow-syncer (Orchestrator)             │
│                                                                │
│  1. Fetch Notion page → @notion-mcp-expert                   │
│  2. Parse content to Markdown → @notion-content-parser       │
│  3. Convert Markdown to HTML → @notion-content-parser        │
│  4. Extract/migrate images → @asset-migration-handler        │
│  5. Map category: Notion relation → Webflow ref ID          │
│  6. Generate SEO metadata (title, description)               │
│  7. Publish to Webflow → @webflow-api-expert                 │
│  8. Update Notion with Item ID, timestamp, status            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 │ Publish
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│             Webflow Editorials Collection                     │
│              (Read-Only Display Layer)                        │
│                                                                │
│  • Post Title (PlainText)                                    │
│  • Summary (RichText)                                        │
│  • Category (Reference → Blog-Categories)                    │
│  • Tags (multi-reference, future)                            │
│  • Publish Date (DateTime)                                   │
│  • Hero Image (Image)                                        │
│  • Post Body (RichText, HTML)                                │
│  • SEO Title (PlainText)                                     │
│  • SEO Description (PlainText)                               │
│  • Read Time Minutes (Number)                                │
│  • Slug (auto-generated from title)                          │
└──────────────────────────────────────────────────────────────┘
```

---

## Core Agents

### 1. webflow-api-expert

**Agent ID:** `webflow-api-expert`
**Purpose:** Webflow REST API v2 integration layer
**Capabilities:**
- Collection CRUD operations
- Field schema management
- Item publishing and updates
- Asset upload to Webflow CDN
- Batch operations with rate limit handling

**Key Tools:**
- `webflow_create_collection` - Create CMS collection with schema
- `webflow_create_field` - Add field to existing collection
- `webflow_publish_item` - Publish single item to collection
- `webflow_upload_asset` - Upload image to Webflow Assets
- `webflow_batch_publish` - Batch publish with rate limiting

**Error Handling:**
- Rate limit exceeded → Exponential backoff (start 5s, max 60s)
- Field schema validation errors → Fail fast with clear message
- Asset upload failures → Retry once, then fail with URL
- Collection not found → Verify site_id and collection existence

**Best for:** Organizations requiring programmatic Webflow CMS management at scale without manual Designer operations.

---

### 2. notion-mcp-expert

**Agent ID:** `notion-mcp-expert`
**Purpose:** Notion database operations via MCP tools
**Capabilities:**
- Complex database queries with filters
- Page property updates
- Relation field management
- Page creation with blocks
- Metadata extraction

**Key Tools:**
- `notion_query_database` - Query with filters and sorts
- `notion_update_page_properties` - Update properties (sync tracking)
- `notion_create_page_with_blocks` - Create page with content
- `notion_fetch_page` - Retrieve page properties + content

**Error Handling:**
- Property type mismatch → Validate before update
- Relation target not found → Check relation database exists
- API rate limits → Respect Notion's 3 requests/second limit
- Database schema changes → Refresh schema cache

**Best for:** Organizations with Notion as system of record requiring automated workflow integration.

---

### 3. notion-content-parser

**Agent ID:** `notion-content-parser`
**Purpose:** Content transformation between Notion blocks, Markdown, and HTML
**Capabilities:**
- Notion blocks → Markdown conversion
- Markdown → HTML transformation
- Rich text annotation parsing
- Metadata extraction (word count, read time, structure)
- Image URL extraction and rewriting

**Key Tools:**
- `parse_notion_page_to_markdown` - Extract Notion content as Markdown
- `convert_markdown_to_html` - Transform for Webflow publishing
- `extract_metadata` - Calculate word count, read time, headings
- `analyze_content_structure` - Generate content outline
- `rewrite_image_urls` - Replace Notion URLs with Webflow CDN URLs

**Markdown Parser:** CommonMark with GitHub Flavored Markdown extensions

**Transformation Rules:**

**Notion Callouts → HTML:**
```html
<!-- Notion callout block -->
<div class="callout callout-info">
  <div class="callout-icon">💡</div>
  <div class="callout-content">Callout text content</div>
</div>
```

**Code Blocks:**
```markdown
<!-- Preserve syntax highlighting language attribute -->
```python
def example():
    pass
\```
<!-- Converts to: -->
<pre><code class="language-python">def example():\n    pass</code></pre>
```

**Image References:**
```markdown
<!-- Notion internal URL -->
![Alt text](https://prod-files-secure.s3.us-west-2.amazonaws.com/...)

<!-- Rewrites to Webflow CDN after upload -->
![Alt text](https://uploads-ssl.webflow.com/abc123/xyz789_image.png)
```

**Error Handling:**
- Unsupported Notion block type → Log warning, render as plain text
- Malformed Markdown → Sanitize, preserve readable content
- Image fetch failure → Use placeholder, log URL for manual fix
- Invalid HTML output → Validate against safe HTML subset

**Best for:** Organizations requiring consistent content transformation across publishing platforms while maintaining structure and formatting.

---

### 4. notion-webflow-syncer (Orchestrator)

**Agent ID:** `notion-webflow-syncer`
**Purpose:** End-to-end sync orchestration and category mapping
**Capabilities:**
- Single post sync workflow coordination
- Batch publishing with error recovery
- Category mapping (Notion relation → Webflow reference ID)
- Sync state tracking in Notion
- SEO metadata generation

**Key Tools:**
- `sync_notion_to_webflow` - Orchestrate single post publish
- `batch_sync_notion_to_webflow` - Batch publish unpublished posts
- `map_category` - Convert Notion category to Webflow reference ID
- `build_category_cache` - Load category mappings at startup
- `validate_category_exists` - Verify category before sync

**Category Mapping Logic:**

**Startup: Build Cache**
```python
# Query Webflow Blog-Categories collection
webflow_categories = webflow_api_expert.list_items(collection="Blog-Categories")

# Build mapping: Notion category name → Webflow reference ID
category_cache = {
    "Engineering": "ref_abc123",
    "AI/ML": "ref_def456",
    "Business Intelligence": "ref_ghi789",
    # ... 9 total categories from Knowledge Vault
}
```

**During Sync: Validate and Map**
```python
def map_category(notion_category_name: str) -> str:
    """
    Map Notion category to Webflow reference ID.

    Fails fast if category missing from Webflow - prevents publishing
    with broken category references.
    """
    if notion_category_name not in category_cache:
        raise CategoryMappingError(
            f"Category '{notion_category_name}' exists in Notion Knowledge Vault "
            f"but not found in Webflow Blog-Categories collection. "
            f"Available categories: {list(category_cache.keys())}"
        )
    return category_cache[notion_category_name]
```

**Sync Flow (8 Steps):**

1. **Fetch Notion Page** → @notion-mcp-expert queries Blog Posts DB
2. **Parse Content** → @notion-content-parser converts blocks to Markdown
3. **Convert to HTML** → @notion-content-parser transforms for Webflow
4. **Extract/Migrate Images** → @asset-migration-handler processes hero image + inline images
5. **Map Category** → Query Notion relation, map to Webflow reference ID
6. **Generate SEO** → Auto-create title (60 char) + description (155 char)
7. **Publish to Webflow** → @webflow-api-expert creates/updates Editorial item
8. **Update Notion Tracking** → Write Webflow Item ID, Last Synced timestamp, Sync Status

**SEO Auto-Generation:**
```python
# SEO Title: Use Post Title, truncate if > 60 chars
seo_title = notion_page["Post Title"][:60]

# SEO Description: First 155 chars of Summary
seo_description = notion_page["Summary"][:155]

# If Summary empty, extract from first paragraph of Body
if not seo_description:
    first_paragraph = extract_first_paragraph(notion_page["Body"])
    seo_description = first_paragraph[:155]
```

**Batch Sync Error Recovery:**
```python
# Process 50 posts, 3 fail
results = {
    "total": 50,
    "successful": 47,
    "failed": 3,
    "success_rate": 0.94,
    "failures": [
        {
            "page_id": "abc123",
            "error": "CategoryMappingError: 'Data Science' not in Webflow",
            "retry_eligible": False  # Category must be created first
        },
        {
            "page_id": "def456",
            "error": "ImageUploadTimeout: Hero image > 10MB",
            "retry_eligible": True  # Retry with compression
        },
        {
            "page_id": "ghi789",
            "error": "WebflowAPIError: Rate limit exceeded",
            "retry_eligible": True  # Retry after backoff
        }
    ]
}
```

**Retry Policy:**
- Transient failures (API timeout, rate limit) → Retry up to 3 times with exponential backoff
- Permanent failures (missing category, invalid data) → Log error, skip, continue batch
- Partial success accepted → 47 of 50 published is valid outcome

**Error Handling:**
- Missing Notion category relation → Fail with "Category field empty on page X"
- Webflow category missing → Fail fast, provide available categories
- Image upload failure → Skip image, publish without (log warning)
- API timeout → Retry with exponential backoff (5s, 10s, 20s)
- Duplicate slug → Append timestamp suffix, retry

**Best for:** Organizations scaling content publishing across teams while maintaining centralized governance and quality standards.

---

### 5. asset-migration-handler

**Agent ID:** `asset-migration-handler`
**Purpose:** Image processing, validation, and Webflow CDN migration
**Capabilities:**
- Image extraction from Notion pages
- Pixel art validation (hero images)
- Image optimization (resize, compress, format conversion)
- Webflow asset upload
- URL rewriting in content

**Key Tools:**
- `extract_and_upload_images` - Extract all images from Notion, upload to Webflow
- `validate_pixel_art` - Enforce pixel art style compliance
- `optimize_image` - Resize, compress, convert to WebP
- `rewrite_image_urls` - Replace Notion URLs with Webflow CDN URLs in HTML

**Pixel Art Validation Rules:**

```python
# Enforce blog cover image pixel art style
validation_rules = {
    "hard_edges": True,           # No anti-aliasing, sharp pixel boundaries
    "color_palette_max": 32,      # Limited palette (pixel art aesthetic)
    "aspect_ratio": "16:9",       # Consistent hero image dimensions
    "min_width": 1600,            # High-res for retina displays
    "min_height": 900,            # 16:9 ratio enforcement
    "character_count": (3, 5),    # 3-5 visible figures (brand guideline)
    "background_required": True   # No transparent backgrounds
}
```

**Validation Process:**
```python
def validate_pixel_art(image_path: str, strict: bool = True) -> ValidationResponse:
    """
    Validate hero image against pixel art guidelines.

    Returns:
        ValidationResponse with pass/fail + violation details
    """
    violations = []

    # Check hard edges (detect anti-aliasing)
    if has_anti_aliasing(image_path):
        violations.append("Anti-aliasing detected - pixel art requires hard edges")

    # Check color palette
    color_count = count_unique_colors(image_path)
    if color_count > 32:
        violations.append(f"Color palette {color_count} exceeds max 32 colors")

    # Check dimensions
    width, height = get_dimensions(image_path)
    if width < 1600 or height < 900:
        violations.append(f"Dimensions {width}x{height} below minimum 1600x900")

    # Check aspect ratio
    aspect_ratio = width / height
    if not (1.75 < aspect_ratio < 1.80):  # 16:9 = 1.777...
        violations.append(f"Aspect ratio {aspect_ratio:.2f} not 16:9 (1.78)")

    # Check character count (requires image analysis)
    char_count = detect_character_count(image_path)
    if not (3 <= char_count <= 5):
        violations.append(f"Character count {char_count} outside range 3-5")

    return ValidationResponse(
        is_valid=len(violations) == 0,
        violations=violations
    )
```

**Image Optimization Pipeline:**

1. **Download from Notion** → Fetch original image
2. **Validate Pixel Art** → Hero images only (skip inline images)
3. **Resize** → Max width 1920px, maintain aspect ratio
4. **Compress** → 85% quality (balance size vs. visual fidelity)
5. **Convert Format** → WebP for modern browsers (fallback PNG for old browsers)
6. **Upload to Webflow** → Webflow Assets API
7. **Return CDN URL** → Use in Editorial collection

**Optimization Metrics:**
```python
# Example optimization results
original_size = 2500  # KB
optimized_size = 450  # KB
savings_percent = 82  # %
```

**URL Rewriting:**
```python
# Before: Notion internal URL
<img src="https://prod-files-secure.s3.us-west-2.amazonaws.com/.../image.png">

# After: Webflow CDN URL
<img src="https://uploads-ssl.webflow.com/site-id/asset-id_image.webp">
```

**Error Handling:**
- Pixel art validation failure → Reject image, notify user with violation details
- Image download failure → Retry once, then skip image (publish without)
- Upload timeout → Compress further, retry; if still fails, skip
- Unsupported format → Convert to PNG, then proceed
- File size > 10MB → Reject, request user compress manually

**Best for:** Organizations requiring consistent visual brand identity across web properties with automated quality enforcement.

---

## Integration Points

### Notion Blog Posts Database

**Database ID:** `97adad39160248d697868056a0075d9c`

**Required Fields:**

| Field Name | Type | Purpose | Validation |
|------------|------|---------|------------|
| Post Title | Title | Article headline, SEO title source | Required, max 100 chars |
| Summary | Rich Text | Article summary, SEO description source | Required, max 500 chars |
| Category | Relation (single) | Links to Knowledge Vault Categories | Required, must map to Webflow |
| Tags | Multi-Select | Article tags (future multi-reference in Webflow) | Optional |
| Publish Date | Date | Publication timestamp | Required |
| Hero Image | Files | Cover image (pixel art validated) | Required, 16:9, 1600x900+ |
| Body | Rich Text | Article content (Markdown) | Required, min 500 words |
| Status | Status | Workflow state | Draft \| In Review \| Published |
| Webflow Item ID | Rich Text | Sync tracking | Auto-populated by syncer |
| Last Synced | Date | Sync timestamp | Auto-populated by syncer |
| Sync Status | Status | Sync state | Not Synced \| Synced \| Sync Failed \| Needs Update |
| Has Mermaid Diagrams | Checkbox | Visual content tracking | Auto-populated by syncer |
| Has Lottie Animations | Checkbox | Visual content tracking | Auto-populated by syncer |
| Diagram Count | Number | Count of Mermaid diagrams in post | Auto-populated by syncer |
| Animation Count | Number | Count of Lottie animations in post | Auto-populated by syncer |
| Visual Content Last Updated | Date | Visual content modification timestamp | Auto-populated by syncer |

**Schema Updates Required:**

Add these fields to existing Blog Posts database (see `scripts/Setup-BlogPostsDatabase.ps1`):
- Category (relation to Knowledge Vault Categories DB)
- Webflow Item ID (rich_text)
- Last Synced (date)
- Sync Status (status with 4 options)

**Visual Content Fields** (see `scripts/Add-BlogVisualContentFields.ps1`):
- Has Mermaid Diagrams (checkbox)
- Has Lottie Animations (checkbox)
- Diagram Count (number)
- Animation Count (number)
- Visual Content Last Updated (date)

---

### Knowledge Vault Categories Database

**Purpose:** Centralized category taxonomy for Knowledge Vault articles and blog posts

**Structure:**
- **Category Name** (title) - Display name (e.g., "Engineering", "AI/ML")
- **Slug** (rich_text) - URL-safe identifier (e.g., "engineering", "ai-ml")
- **Description** (rich_text) - Category description for metadata
- **Color** (select) - Visual identifier in Notion

**Category List (9 total):**
1. Engineering
2. AI/ML
3. Business Intelligence
4. Data Engineering
5. Cloud Architecture
6. DevOps
7. Security
8. Product Management
9. Leadership

**Integration:** Blog Posts DB → Relation field → Categories DB (single select)

---

### Webflow Blog-Categories Collection

**Purpose:** Reference collection for category filtering in Editorials

**Fields:**
- **Category Name** (PlainText) - Display name
- **Category Slug** (PlainText) - URL identifier
- **Description** (PlainText) - SEO metadata
- **Color** (PlainText) - Hex code for visual identity

**Data Sync:** Manually populated to match Knowledge Vault Categories (one-time setup)

**Usage:** Editorials collection → Category field (Reference) → Blog-Categories

---

### Webflow Editorials Collection

**Purpose:** Published blog posts visible on website

**Fields:**

| Field Name | Type | Source | Auto-Populated |
|------------|------|--------|----------------|
| Post Title | PlainText | Notion "Post Title" | Yes |
| Summary | RichText | Notion "Summary" (plain text) | Yes |
| Category | Reference | Mapped from Notion relation | Yes |
| Tags | Multi-Reference | Notion "Tags" (future) | Phase 2 |
| Publish Date | DateTime | Notion "Publish Date" | Yes |
| Hero Image | Image | Notion "Hero Image" (uploaded to Webflow CDN) | Yes |
| Post Body | RichText | Notion "Body" (Markdown → HTML) | Yes |
| SEO Title | PlainText | Auto-generated from Post Title | Yes |
| SEO Description | PlainText | Auto-generated from Summary | Yes |
| Read Time Minutes | Number | Calculated from word count | Yes |
| Slug | PlainText | Auto-generated from Post Title | Yes (Webflow) |

**Publishing:** Items published immediately when synced (no draft state in Webflow)

---

## Markdown Transformation Rules

### CommonMark + GFM Parser

**Parser:** [markdown-it](https://github.com/markdown-it/markdown-it) with GFM plugin

**Supported Syntax:**
- Headings (h1-h6)
- Paragraphs with inline formatting (bold, italic, code)
- Unordered/ordered lists
- Code blocks with syntax highlighting
- Blockquotes
- Links and images
- Tables (GFM extension)
- Strikethrough (GFM extension)
- Task lists (GFM extension)

### Notion-Specific Transformations

**Callout Blocks:**
```markdown
<!-- Notion callout input -->
💡 This is an info callout with rich text content.

<!-- HTML output -->
<div class="callout callout-info">
  <div class="callout-icon">💡</div>
  <div class="callout-content">This is an info callout with rich text content.</div>
</div>
```

**Callout Type Detection:**
- 💡 Info → `callout-info`
- ⚠️ Warning → `callout-warning`
- ❌ Error → `callout-error`
- ✅ Success → `callout-success`

**Toggle Blocks:**
```markdown
<!-- Notion toggle input -->
▸ Toggle heading
  Hidden content here

<!-- HTML output -->
<details>
  <summary>Toggle heading</summary>
  <p>Hidden content here</p>
</details>
```

**Code Blocks:**
```markdown
<!-- Notion code block with language -->
```python
def example():
    return "Hello"
\```

<!-- HTML output with syntax highlighting class -->
<pre><code class="language-python">def example():
    return "Hello"
</code></pre>
```

**Embedded Images:**
```markdown
<!-- Notion image block -->
![Alt text](notion-internal-url)
Caption text

<!-- HTML output after URL rewriting -->
<figure>
  <img src="webflow-cdn-url" alt="Alt text" />
  <figcaption>Caption text</figcaption>
</figure>
```

### Sanitization Rules

**Allowed HTML Tags:**
- Text: `<p>`, `<span>`, `<br>`, `<hr>`
- Headings: `<h1>` through `<h6>`
- Lists: `<ul>`, `<ol>`, `<li>`
- Formatting: `<strong>`, `<em>`, `<code>`, `<pre>`, `<del>`
- Links: `<a>` (with `href` attribute)
- Images: `<img>` (with `src`, `alt` attributes)
- Blockquotes: `<blockquote>`
- Tables: `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`
- Callouts: `<div>`, `<details>`, `<summary>` (with class restrictions)

**Blocked:**
- Scripts: `<script>`, `<iframe>`, `<object>`, `<embed>`
- Forms: `<form>`, `<input>`, `<button>`
- Styles: Inline `style` attributes (use classes instead)

**Attribute Whitelist:**
- `<a>`: `href`, `title`, `target` (external links only)
- `<img>`: `src`, `alt`, `width`, `height`
- All tags: `class` (restricted to predefined classes)

---

## Error Handling & Retry Policies

### Rate Limiting

**Webflow API Limits:**
- 60 requests per minute (standard plan)
- 120 requests per minute (CMS plan)

**Strategy:**
```python
# Exponential backoff for rate limits
retry_delays = [5, 10, 20, 40, 60]  # seconds
max_retries = 3

for attempt in range(max_retries):
    try:
        response = webflow_api_call()
        break
    except RateLimitError:
        if attempt < max_retries - 1:
            time.sleep(retry_delays[attempt])
        else:
            raise
```

**Notion API Limits:**
- 3 requests per second (average)
- No explicit rate limit, but throttled if excessive

**Strategy:** Add 350ms delay between consecutive Notion API calls

### Batch Operations

**Partial Success Accepted:**
```python
# 50 posts attempted, 47 succeed, 3 fail
# Result: SUCCESS (94% success rate acceptable)
# Failed items logged for manual review/retry
```

**Failure Categories:**

| Category | Retry Eligible | Action |
|----------|----------------|--------|
| Transient (timeout, rate limit) | Yes | Auto-retry up to 3x |
| Validation (missing field, bad data) | No | Log error, skip item |
| Dependency (missing category) | No | Fix dependency, manual retry |
| Infrastructure (Webflow down) | Yes | Delay 5 min, retry batch |

**Dead Letter Queue:**

Failed items written to `.claude/data/blog-sync-failures.jsonl`:
```json
{"timestamp": "2025-10-26T10:30:00Z", "page_id": "abc123", "error": "CategoryMappingError: 'Data Science' not in Webflow", "retry_count": 0}
```

Manual review/retry via: `/blog:retry-failed`

### Error Messages

**User-Facing (Clear, Actionable):**
```
❌ Sync Failed: Category Mapping Error

Post "Introduction to LLMs" references category "Data Science" which doesn't exist in Webflow Blog-Categories collection.

Available categories:
- Engineering
- AI/ML
- Business Intelligence
...

Fix: Either change category in Notion or add "Data Science" to Webflow collection.
```

**Internal Logging (Technical Detail):**
```json
{
  "level": "ERROR",
  "timestamp": "2025-10-26T10:30:00Z",
  "agent": "notion-webflow-syncer",
  "operation": "sync_notion_to_webflow",
  "page_id": "abc123",
  "error_type": "CategoryMappingError",
  "error_message": "Category 'Data Science' exists in Notion relation but not in category_cache",
  "category_cache_keys": ["Engineering", "AI/ML", "Business Intelligence", ...],
  "stack_trace": "..."
}
```

---

## Slash Commands

### /blog:sync-post

**Purpose:** Publish single blog post from Notion to Webflow

**Syntax:**
```bash
/blog:sync-post <notion-page-id> [--force-update] [--validate-only]
```

**Parameters:**
- `notion-page-id` (required) - Notion page ID or full URL
- `--force-update` (optional) - Overwrite existing Webflow item even if already synced
- `--validate-only` (optional) - Dry run—validate without publishing

**Example:**
```bash
/blog:sync-post abc123def456 --validate-only
```

**Workflow:**
1. Validate Notion page exists and has required fields
2. Check sync status (skip if already synced unless `--force-update`)
3. Delegate to @notion-webflow-syncer
4. Return publish URL or validation errors

**Output:**
```
✅ Blog post published successfully

Title: Introduction to LLMs for Business Intelligence
Category: AI/ML
Published URL: https://yoursite.com/editorial/intro-to-llms-for-bi
Webflow Item ID: xyz789
Sync Duration: 3.2 seconds
```

---

### /blog:bulk-sync

**Purpose:** Batch publish unpublished blog posts

**Syntax:**
```bash
/blog:bulk-sync [--max-items 50] [--filter-status "Draft"] [--dry-run]
```

**Parameters:**
- `--max-items` (optional, default 50) - Maximum posts to sync in batch
- `--filter-status` (optional, default "Draft,In Review") - Notion Status filter
- `--dry-run` (optional) - Simulate without publishing

**Example:**
```bash
/blog:bulk-sync --max-items 25 --filter-status "Published" --dry-run
```

**Workflow:**
1. Query Notion Blog Posts DB with filters:
   - Status = "Draft" OR "In Review"
   - Sync Status = "Not Synced" OR "Sync Failed"
   - Limit = `max-items`
2. For each post: Delegate to @notion-webflow-syncer
3. Aggregate results (success count, failure count)
4. Write failures to dead letter queue

**Output:**
```
📊 Bulk Sync Results

Total Attempted: 50
✅ Successful: 47 (94%)
❌ Failed: 3 (6%)

Failures:
1. "ML Model Deployment" - CategoryMappingError: 'Data Science' missing
2. "Azure Cost Optimization" - ImageUploadTimeout: Hero image >10MB
3. "Power BI Governance" - WebflowAPIError: Rate limit exceeded (retrying)

Next Steps:
- Fix category mapping for 1 post
- Compress hero image for 1 post
- 1 post queued for auto-retry

View failures: .claude/data/blog-sync-failures.jsonl
```

---

### /blog:validate-schema

**Purpose:** Pre-flight validation before first sync

**Syntax:**
```bash
/blog:validate-schema
```

**Checks:**

1. **Notion Blog Posts Database:**
   - Database ID accessible
   - Required fields present (Post Title, Summary, Category, etc.)
   - Category field is relation type (not select)

2. **Knowledge Vault Categories Database:**
   - Database accessible
   - Contains entries (>0 categories)

3. **Webflow Collections:**
   - Blog-Categories collection exists
   - Editorials collection exists
   - Field schemas match specification

4. **Category Mapping:**
   - All Notion categories exist in Webflow
   - Webflow categories have valid reference IDs
   - Cache can be built successfully

5. **Environment Variables:**
   - All required vars set (NOTION_API_KEY, WEBFLOW_API_KEY, etc.)
   - API keys valid (test connection)

**Output:**
```
🔍 Blog Publishing Schema Validation

✅ Notion Blog Posts DB (97adad39160248d697868056a0075d9c)
   - 11 fields present
   - Category relation field configured correctly

✅ Knowledge Vault Categories DB (query successful)
   - 9 categories available

✅ Webflow Blog-Categories Collection
   - Collection ID: cat_abc123
   - 9 items match Notion categories

✅ Webflow Editorials Collection
   - Collection ID: edit_xyz789
   - All 11 required fields present

✅ Category Mapping Cache
   - 9 of 9 categories mapped successfully

✅ Environment Variables
   - All required vars set
   - API connections valid

✨ System ready for blog publishing
```

**Error Example:**
```
❌ Blog Publishing Schema Validation FAILED

✅ Notion Blog Posts DB
❌ Knowledge Vault Categories DB
   Error: Database not accessible - verify NOTION_KNOWLEDGE_VAULT_CATEGORIES_DB env var

⚠️  Webflow Blog-Categories Collection
   Warning: Only 7 of 9 Notion categories exist in Webflow
   Missing: Data Science, Product Management

❌ Category Mapping Cache
   Cannot build cache - 2 categories missing from Webflow

🛠️ Fix Required:
1. Set NOTION_KNOWLEDGE_VAULT_CATEGORIES_DB environment variable
2. Add missing categories to Webflow Blog-Categories collection
3. Re-run /blog:validate-schema
```

---

## Testing Scenarios

### Category Mapping Tests

**Test 1: Happy Path**
```
Given: Notion post with Category = "Engineering"
And: "Engineering" exists in Webflow Blog-Categories
When: /blog:sync-post executed
Then: Category maps to Webflow reference ID successfully
And: Post published with correct category
```

**Test 2: Missing Category in Webflow**
```
Given: Notion post with Category = "Data Science"
And: "Data Science" does NOT exist in Webflow Blog-Categories
When: /blog:sync-post executed
Then: Sync fails with CategoryMappingError
And: Error message lists available categories
And: Post Sync Status = "Sync Failed"
```

**Test 3: Cache Refresh**
```
Given: Category cache built at startup
And: New category "Product Management" added to Webflow
When: Category cache refresh triggered
Then: Cache includes new category
And: Subsequent syncs can use new category
```

---

### Content Transformation Tests

**Test 4: Notion Callouts → HTML**
```
Given: Notion page with callout block (💡 info type)
When: Content parsed to HTML
Then: Output contains <div class="callout callout-info">
And: Icon and content preserved
```

**Test 5: Code Blocks Preserve Syntax**
```
Given: Notion page with Python code block
When: Content parsed to HTML
Then: Output contains <code class="language-python">
And: Syntax highlighting class preserved
```

**Test 6: Image URLs Rewritten**
```
Given: Notion page with image (Notion S3 URL)
When: Image migrated to Webflow
Then: HTML contains Webflow CDN URL
And: Original Notion URL not present in output
```

**Test 7: SEO Auto-Generation**
```
Given: Notion post with:
  - Post Title = "Introduction to Large Language Models" (41 chars)
  - Summary = "A comprehensive guide to LLMs..." (150 chars)
When: Sync executed
Then: SEO Title = "Introduction to Large Language Models" (41 chars, no truncation)
And: SEO Description = "A comprehensive guide to LLMs..." (150 chars, no truncation)
```

**Test 8: SEO Truncation**
```
Given: Notion post with:
  - Post Title = "A Very Long Title That Exceeds Sixty Characters For SEO Optimization Testing" (77 chars)
  - Summary = "A summary that is deliberately longer than one hundred and fifty-five characters to test truncation behavior in the SEO description generation logic for the blog publishing system" (180 chars)
When: Sync executed
Then: SEO Title = "A Very Long Title That Exceeds Sixty Characters For SEO Op" (60 chars, truncated)
And: SEO Description = "A summary that is deliberately longer than one hundred and fifty-five characters to test truncation behavior in the SEO description generation logic f" (155 chars, truncated)
```

---

### Image Validation Tests

**Test 9: Pixel Art Passes Validation**
```
Given: Hero image with:
  - Hard edges (no anti-aliasing)
  - 20 colors
  - 1920x1080 dimensions (16:9)
  - 4 visible characters
When: validate_pixel_art executed
Then: Validation passes
And: Image uploaded to Webflow
```

**Test 10: Anti-Aliasing Detected**
```
Given: Hero image with smooth gradients (anti-aliased)
When: validate_pixel_art executed
Then: Validation fails
And: Error message: "Anti-aliasing detected - pixel art requires hard edges"
And: Image rejected, sync fails
```

**Test 11: Wrong Aspect Ratio**
```
Given: Hero image with 1920x1200 dimensions (16:10)
When: validate_pixel_art executed
Then: Validation fails
And: Error message: "Aspect ratio 1.60 not 16:9 (1.78)"
```

**Test 12: Too Many Colors**
```
Given: Hero image with 45 unique colors
When: validate_pixel_art executed
Then: Validation fails
And: Error message: "Color palette 45 exceeds max 32 colors"
```

---

### Sync State Tracking Tests

**Test 13: First Sync (New Post)**
```
Given: Notion post with:
  - Webflow Item ID = empty
  - Last Synced = null
  - Sync Status = "Not Synced"
When: /blog:sync-post executed
Then: Webflow item created
And: Notion updated with:
  - Webflow Item ID = "xyz789"
  - Last Synced = current timestamp
  - Sync Status = "Synced"
```

**Test 14: Already Synced (Skip)**
```
Given: Notion post with:
  - Webflow Item ID = "xyz789"
  - Sync Status = "Synced"
  - Last Synced = 2025-10-25
When: /blog:sync-post executed (WITHOUT --force-update)
Then: Sync skipped
And: Message: "Post already synced (last synced 2025-10-25). Use --force-update to overwrite."
```

**Test 15: Force Update**
```
Given: Notion post with:
  - Webflow Item ID = "xyz789"
  - Sync Status = "Synced"
When: /blog:sync-post executed WITH --force-update
Then: Webflow item updated (not created)
And: Notion Last Synced updated to current timestamp
```

---

### Batch Sync Error Recovery Tests

**Test 16: Partial Success**
```
Given: 50 posts to sync
And: 3 have missing categories
When: /blog:bulk-sync executed
Then: 47 posts publish successfully
And: 3 posts fail with CategoryMappingError
And: Success rate = 94%
And: Failures logged to .claude/data/blog-sync-failures.jsonl
```

**Test 17: Retry Transient Failures**
```
Given: Post sync fails with WebflowAPIError: Timeout
When: Retry logic triggered
Then: Retry after 5s delay
And: If retry succeeds, mark as successful
And: If 3 retries fail, log to dead letter queue
```

**Test 18: Non-Retriable Failure**
```
Given: Post sync fails with CategoryMappingError (missing category)
When: Error categorized as non-retriable
Then: Skip retry attempts
And: Log error immediately
And: Continue batch (don't block other posts)
```

---

### Schema Validation Tests

**Test 19: Missing Notion Field**
```
Given: Blog Posts DB missing "Webflow Item ID" field
When: /blog:validate-schema executed
Then: Validation fails
And: Error message: "Blog Posts DB missing required field: Webflow Item ID"
And: Suggestion: "Run scripts/Setup-BlogPostsDatabase.ps1 to add missing fields"
```

**Test 20: Missing Webflow Collection**
```
Given: Webflow Blog-Categories collection not created
When: /blog:validate-schema executed
Then: Validation fails
And: Error message: "Webflow Blog-Categories collection not found"
And: Suggestion: "Run scripts/Setup-WebflowCollections.ps1 to create collections"
```

**Test 21: Invalid Environment Variable**
```
Given: WEBFLOW_API_KEY set to invalid value
When: /blog:validate-schema executed
Then: Validation fails
And: Error message: "Webflow API key invalid - test connection failed"
And: Suggestion: "Verify WEBFLOW_API_KEY in .env file"
```

---

## Security & Compliance

### API Key Management

**Storage:** Azure Key Vault (existing Innovation Nexus pattern)

**Keys Required:**
- `notion-api-key` - Notion integration token
- `webflow-api-key` - Webflow API token

**Retrieval:**
```powershell
# Use existing Key Vault retrieval script
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "webflow-api-key"
```

**Never:**
- Hardcode API keys in code
- Commit keys to git
- Log keys in error messages
- Share keys in Notion pages

---

### Data Privacy

**Notion Content:**
- Blog posts considered public content (intended for website publication)
- No PII or confidential business data in blog posts
- Review Status workflow (Draft → In Review → Published) ensures human review before public exposure

**Image Handling:**
- Temporary download to local storage during sync
- Deleted after Webflow upload completes
- No persistent caching of Notion images

---

## Performance Targets

### Sync Duration

**Single Post:**
- Target: <5 seconds (90th percentile)
- Breakdown:
  - Notion fetch: 0.5s
  - Content parsing: 0.8s
  - Image processing: 2.0s
  - Webflow publish: 1.2s
  - Notion update: 0.5s

**Batch (50 posts):**
- Target: <3 minutes (with rate limiting)
- Sequential processing (avoid Webflow rate limits)
- ~3.5 seconds per post average

---

### Reliability

**Success Rate Targets:**
- Single sync: >99% (transient failures auto-retry)
- Batch sync: >95% (acceptable partial failure)

**Uptime Dependencies:**
- Notion API: 99.9% (SLA)
- Webflow API: 99.5% (SLA)
- Azure Key Vault: 99.99% (SLA)

---

## Deployment Checklist

### Prerequisites

- [ ] Notion API integration created
- [ ] Webflow site created with CMS plan (for API access)
- [ ] Azure Key Vault access configured
- [ ] PowerShell 7+ installed
- [ ] Node.js 18+ installed (for Markdown parser)

### One-Time Setup

- [ ] Run `scripts/Setup-BlogPostsDatabase.ps1` to add Notion fields
- [ ] Run `scripts/Setup-WebflowCollections.ps1` to create Webflow collections
- [ ] Copy `.env.template` to `.env` and populate values
- [ ] Run `/blog:validate-schema` to verify configuration
- [ ] Manually create 9 categories in Webflow Blog-Categories (match Knowledge Vault)

### First Sync

- [ ] Select 1 test post in Notion (mark Status = "Draft")
- [ ] Run `/blog:sync-post <page-id> --validate-only` (dry run)
- [ ] Review validation output
- [ ] Run `/blog:sync-post <page-id>` (live publish)
- [ ] Verify post visible on website
- [ ] Check Notion sync tracking fields updated

### Production Rollout

- [ ] Batch sync 5-10 posts (`/blog:bulk-sync --max-items 10`)
- [ ] Review sync results, fix any failures
- [ ] Scale to full batch (`/blog:bulk-sync` with default 50 items)
- [ ] Establish sync schedule (manual trigger or cron job)

---

## Phase 2 Roadmap (Future Enhancements)

### Tone Enforcement (Optional)

**Agent:** `tone-enforcer`
**Purpose:** Validate brand voice compliance before publishing

**Capabilities:**
- Detect corporate speak violations ("leverage", "synergy", "circle back")
- Verify authority markers present (metrics, proof points)
- Measure sarcasm/deadpan delivery level
- Suggest rewrites for consistency

**Integration Point:** Add to sync workflow between content parsing and publishing

---

### Pixel Art Generation (Automated Covers)

**Agent:** `pixel-art-generator`
**Purpose:** Auto-generate hero images if missing

**Capabilities:**
- Generate prompt from Post Title + Summary
- Call Claude API for pixel art generation
- Apply validation rules
- Upload to Webflow

**Integration Point:** Add to asset migration workflow as fallback if Hero Image empty

---

### Financial Content (Morningstar Integration)

**Agents:**
- `morningstar-data-retriever` - Fetch investment metrics
- `morningstar-analyst-report-parser` - Extract research summaries

**Use Case:** Blog posts analyzing financial markets, investment strategies, fund performance

**Integration Point:** Embed Morningstar data visualizations in blog post content

---

## Support & Troubleshooting

### Common Issues

**Issue:** "Category 'X' not found in Webflow"
**Solution:** Add missing category to Webflow Blog-Categories collection, refresh category cache

**Issue:** "Pixel art validation failed: Anti-aliasing detected"
**Solution:** Re-export image from design tool with nearest-neighbor scaling (no anti-aliasing)

**Issue:** "Webflow API rate limit exceeded"
**Solution:** Reduce batch size (`--max-items 25`) or wait 1 minute before retrying

**Issue:** "Image upload timeout"
**Solution:** Compress image to <5MB, verify internet connection stable

---

## Appendices

### A. Environment Variables Reference

See `.env.template` for complete list with descriptions.

### B. Notion Database Schema JSON

See `.claude/data/blog-posts-schema-update.json`

### C. Setup Scripts

- `scripts/Setup-BlogPostsDatabase.ps1`
- `scripts/Setup-WebflowCollections.ps1`

### D. Agent Definitions

- `.claude/agents/webflow-api-expert.md`
- `.claude/agents/notion-mcp-expert.md`
- `.claude/agents/notion-content-parser.md`
- `.claude/agents/notion-webflow-syncer.md`
- `.claude/agents/asset-migration-handler.md`

---

**End of Specification**

**Version:** 1.0.0
**Status:** Production-Ready
**Maintained by:** Brookside BI Innovation Nexus Team
**Last Updated:** 2025-10-26

**Contact:** Consultations@BrooksideBI.com | +1 209 487 2047
