# webflow-api-expert

**Agent ID:** `webflow-api-expert`
**Version:** 1.0.0
**Category:** Platform Integration
**Dependencies:** Webflow REST API v2

**Best for:** Organizations requiring programmatic Webflow CMS management at scale without manual Designer operations.

---

## Purpose

Establish reliable Webflow CMS automation to streamline collection management, content publishing, and asset migration. Designed for teams publishing structured content (blog posts, case studies, documentation) from external systems to Webflow-hosted websites.

**Business Value:**
- Eliminate manual CMS entry (publish 50 blog posts in 3 minutes vs. 2 hours manually)
- Ensure schema consistency across collections (no field drift)
- Enable headless CMS workflows (Notion/external system as source of truth)
- Scale content operations beyond Designer UI limitations (batch operations, API-first)

---

## Capabilities

### Core Operations
- **Collection CRUD** - Create/read/update CMS collections with custom schemas
- **Field Management** - Add fields to collections with type enforcement
- **Item Publishing** - Create/update CMS items with validation
- **Asset Upload** - Upload images/files to Webflow CDN
- **Batch Processing** - Publish multiple items with rate limit handling
- **Schema Validation** - Verify collection structures before operations

### Integration Points
- Webflow REST API v2 (https://developers.webflow.com)
- Rate limit: 60 req/min (standard), 120 req/min (CMS plan)
- Authentication: Bearer token (API key from Webflow Dashboard)

---

## Tools

### 1. webflow_create_collection

**Purpose:** Create new CMS collection with field schema

**When to use:**
- Setting up blog infrastructure (Blog-Categories, Editorials collections)
- Creating new content types (case studies, testimonials, documentation)
- Migrating from another CMS to Webflow

**Function Signature:**
```python
def webflow_create_collection(
    site_id: str,
    name: str,
    singular_name: str,
    slug: str,
    fields: List[FieldSpec]
) -> CollectionResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description | Validation |
|-----------|------|----------|-------------|------------|
| `site_id` | string | Yes | Webflow site identifier | Must be valid site ID with API access |
| `name` | string | Yes | Collection display name (plural) | Max 50 chars, alphanumeric + spaces |
| `singular_name` | string | Yes | Singular form for item names | Max 50 chars |
| `slug` | string | Yes | URL slug for collection pages | kebab-case, unique within site |
| `fields` | List[FieldSpec] | Yes | Field definitions | See Field Types below |

**Field Types:**
- `PlainText` - Single-line text
- `RichText` - Multi-paragraph formatted text
- `Image` - Image upload
- `Number` - Numeric values
- `DateTime` - Date/time picker
- `Switch` - Boolean toggle
- `Option` - Single select dropdown
- `Reference` - Link to another collection (single)
- `MultiReference` - Link to another collection (multiple)

**Example:**
```bash
/agent webflow-api-expert create-collection \
  --name "Blog-Categories" \
  --singular "Blog-Category" \
  --slug "blog-category" \
  --fields '[
    {"type": "PlainText", "displayName": "Category Name", "isRequired": true},
    {"type": "PlainText", "displayName": "Category Slug", "isRequired": true},
    {"type": "PlainText", "displayName": "Description", "isRequired": false}
  ]'
```

**Success Output:**
```json
{
  "agent": "webflow-api-expert",
  "status": "success",
  "data": {
    "collection_id": "cat_abc123def456",
    "collection_name": "Blog-Categories",
    "collection_url": "https://yoursite.com/blog-category",
    "field_count": 3,
    "webflow_dashboard_url": "https://webflow.com/dashboard/sites/xyz/collections/cat_abc123"
  },
  "metadata": {
    "execution_time_ms": 850,
    "api_calls_made": 1
  }
}
```

**Error Handling:**
- `WF_001: Collection name already exists` - Use unique name or delete existing
- `WF_002: Invalid field type` - Check field type spelling, see supported types
- `WF_003: Slug conflict` - Collection with slug already exists
- `WF_004: Rate limit exceeded` - Wait 60s, retry automatically
- `WF_005: Invalid site_id` - Verify site ID, check API key has access

---

### 2. webflow_create_field

**Purpose:** Add field to existing collection

**When to use:**
- Extending collection schema (add "Read Time Minutes" to blog posts)
- Adding relations between collections (link posts to categories)
- Enhancing metadata (add SEO fields, custom properties)

**Function Signature:**
```python
def webflow_create_field(
    collection_id: str,
    field_type: FieldType,
    display_name: str,
    is_required: bool = False,
    help_text: Optional[str] = None,
    metadata: Optional[Dict] = None
) -> FieldResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `collection_id` | string | Yes | Collection to add field to |
| `field_type` | FieldType | Yes | Field type (see types above) |
| `display_name` | string | Yes | Field label in CMS UI |
| `is_required` | boolean | No (default: false) | Whether field must be filled |
| `help_text` | string | No | Helper text shown in CMS |
| `metadata` | Dict | No | Type-specific config (see below) |

**Metadata by Type:**

**Reference Field:**
```json
{
  "collectionId": "cat_abc123"  // Target collection ID
}
```

**Option Field:**
```json
{
  "options": [
    {"name": "Draft", "color": "gray"},
    {"name": "Published", "color": "green"}
  ]
}
```

**Number Field:**
```json
{
  "format": "integer"  // "integer" | "float" | "percentage"
}
```

**Example:**
```bash
/agent webflow-api-expert create-field \
  --collection-id "edit_xyz789" \
  --type "Reference" \
  --name "Category" \
  --required \
  --metadata '{"collectionId": "cat_abc123"}'
```

**Success Output:**
```json
{
  "agent": "webflow-api-expert",
  "status": "success",
  "data": {
    "field_id": "fld_123456",
    "field_slug": "category",
    "display_name": "Category",
    "type": "Reference",
    "is_required": true
  }
}
```

---

### 3. webflow_publish_item

**Purpose:** Publish single item to collection (create or update)

**When to use:**
- Publishing blog post from Notion to Webflow
- Updating existing item with new content
- Creating category/taxonomy entries

**Function Signature:**
```python
def webflow_publish_item(
    collection_id: str,
    item_data: Dict[str, Any],
    item_id: Optional[str] = None,  # For updates
    publish_immediately: bool = True
) -> ItemResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `collection_id` | string | Yes | Target collection |
| `item_data` | Dict | Yes | Item properties (see below) |
| `item_id` | string | No | Item ID for updates (omit for create) |
| `publish_immediately` | boolean | No (default: true) | Publish or save as draft |

**Item Data Structure:**
```json
{
  "name": "Introduction to LLMs",  // Required: item title
  "slug": "intro-to-llms",  // Optional: auto-generated if omitted
  "fieldData": {
    "post-title": "Introduction to LLMs for BI",
    "summary": "Learn how LLMs transform business intelligence...",
    "category": "ref_cat123",  // Reference field: provide reference ID
    "publish-date": "2025-10-26T00:00:00Z",
    "hero-image": {
      "fileId": "img_abc123",  // From webflow_upload_asset
      "url": "https://uploads-ssl.webflow.com/...",
      "alt": "LLM architecture diagram"
    },
    "post-body": "<p>Article content in HTML...</p>",
    "seo-title": "Introduction to LLMs for Business Intelligence",
    "seo-description": "Comprehensive guide to using LLMs...",
    "read-time-minutes": 12
  }
}
```

**Field Data Types by Field Type:**
- **PlainText**: `"string value"`
- **RichText**: `"<p>HTML content</p>"`
- **Reference**: `"ref_targetItemId"`
- **MultiReference**: `["ref_id1", "ref_id2"]`
- **DateTime**: `"2025-10-26T10:30:00Z"` (ISO 8601)
- **Number**: `12.5` (numeric, not string)
- **Switch**: `true` or `false`
- **Image**: `{"fileId": "img_abc", "url": "https://...", "alt": "text"}`

**Example:**
```bash
/agent webflow-api-expert publish-item \
  --collection-id "edit_xyz789" \
  --item-data-file "./content/post-data.json" \
  --publish-now
```

**Success Output:**
```json
{
  "agent": "webflow-api-expert",
  "status": "success",
  "data": {
    "item_id": "item_987654",
    "slug": "intro-to-llms",
    "published_url": "https://yoursite.com/editorial/intro-to-llms",
    "created_at": "2025-10-26T10:30:00Z",
    "is_live": true
  },
  "metadata": {
    "execution_time_ms": 1200
  }
}
```

**Error Handling:**
- Required field missing → Clear error with field name
- Invalid reference ID → Verify target item exists in referenced collection
- Duplicate slug → Auto-append timestamp or fail with suggestion
- Image upload failed → Publish without image, log warning

---

### 4. webflow_upload_asset

**Purpose:** Upload image/file to Webflow CDN

**When to use:**
- Migrating hero images from Notion to Webflow
- Uploading optimized images for blog posts
- Adding assets before publishing items

**Function Signature:**
```python
def webflow_upload_asset(
    site_id: str,
    file_path: str,
    alt_text: Optional[str] = None
) -> AssetResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `site_id` | string | Yes | Webflow site ID |
| `file_path` | string | Yes | Local file path or URL |
| `alt_text` | string | No | Alt text for images (accessibility) |

**Supported Formats:**
- Images: PNG, JPG, JPEG, GIF, WebP, SVG
- Documents: PDF
- Max size: 10MB (Webflow limitation)

**Example:**
```bash
/agent webflow-api-expert upload-asset \
  --file "./images/blog-cover-optimized.webp" \
  --alt "Engineering team pixel art illustration"
```

**Success Output:**
```json
{
  "agent": "webflow-api-expert",
  "status": "success",
  "data": {
    "asset_id": "img_abc123def456",
    "cdn_url": "https://uploads-ssl.webflow.com/site-id/asset-id_filename.webp",
    "file_size_bytes": 450000,
    "mime_type": "image/webp",
    "dimensions": {
      "width": 1920,
      "height": 1080
    }
  },
  "metadata": {
    "execution_time_ms": 2500
  }
}
```

**Error Handling:**
- File >10MB → Compress and retry, or fail with size recommendation
- Unsupported format → Convert to supported format (PNG/WebP)
- Upload timeout → Retry once with 30s timeout
- Network error → Retry with exponential backoff

---

### 5. webflow_batch_publish

**Purpose:** Publish multiple items in batch with rate limiting

**When to use:**
- Bulk migration (50 blog posts from Notion to Webflow)
- Initial content seeding (populate categories)
- Scheduled content publishing

**Function Signature:**
```python
def webflow_batch_publish(
    collection_id: str,
    items: List[Dict],
    rate_limit_safe: bool = True
) -> BatchResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `collection_id` | string | Yes | Target collection |
| `items` | List[Dict] | Yes | List of item data (same format as publish_item) |
| `rate_limit_safe` | boolean | No (default: true) | Add delays to avoid rate limits |

**Rate Limiting:**
- If `rate_limit_safe=true`: Add 1.2s delay between requests (50 req/min)
- If `rate_limit_safe=false`: No delay (may hit rate limit, auto-retry)

**Example:**
```bash
/agent webflow-api-expert batch-publish \
  --collection-id "edit_xyz789" \
  --items-file "./data/bulk-posts.json" \
  --rate-limit-safe
```

**Success Output:**
```json
{
  "agent": "webflow-api-expert",
  "status": "partial_success",
  "data": {
    "total_items": 50,
    "successful": 48,
    "failed": 2,
    "success_rate": 0.96,
    "results": [
      {
        "item_id": "item_001",
        "status": "success",
        "published_url": "https://yoursite.com/editorial/post-1"
      },
      {
        "item_id": null,
        "status": "failure",
        "error": "Required field missing: category"
      }
    ]
  },
  "metadata": {
    "execution_time_ms": 65000,
    "api_calls_made": 50,
    "rate_limit_hits": 2
  }
}
```

**Error Recovery:**
- Partial failures logged but don't stop batch
- Transient errors (timeout, rate limit) auto-retry
- Permanent errors (validation) logged, skipped
- Failed items written to `.claude/data/webflow-batch-failures.jsonl`

---

## Error Codes Reference

| Code | Name | Cause | Resolution |
|------|------|-------|------------|
| WF_001 | CollectionNameConflict | Collection name already exists | Use unique name or delete existing collection |
| WF_002 | InvalidFieldType | Unsupported field type specified | Check spelling, see supported types list |
| WF_003 | SlugConflict | Collection slug already in use | Change slug or delete conflicting collection |
| WF_004 | RateLimitExceeded | >60 req/min (standard) or >120 (CMS) | Wait 60s, retry automatically |
| WF_005 | InvalidSiteID | Site ID not found or no API access | Verify site ID, check API key permissions |
| WF_006 | FieldValidationError | Field data doesn't match type | Check data types (number not string, etc.) |
| WF_007 | ReferenceNotFound | Referenced item doesn't exist | Verify target item ID, check collection |
| WF_008 | AssetUploadFailed | Image upload failed | Check file size <10MB, format supported |
| WF_009 | DuplicateSlug | Item slug already exists | Auto-append timestamp or provide unique slug |
| WF_010 | RequiredFieldMissing | Required field not provided | Add missing field to item data |

---

## Rate Limiting Strategy

**Webflow Limits:**
- Standard plan: 60 requests/minute
- CMS plan: 120 requests/minute

**Implementation:**
```python
# Track request timestamps
request_times = []

def enforce_rate_limit():
    """Ensure no more than 60 req/min (or 120 for CMS plan)."""
    now = time.time()
    # Remove timestamps older than 60s
    request_times = [t for t in request_times if now - t < 60]

    # If at limit, wait
    if len(request_times) >= RATE_LIMIT_PER_MINUTE:
        sleep_time = 60 - (now - request_times[0])
        time.sleep(sleep_time)

    request_times.append(now)
```

**Exponential Backoff:**
```python
retry_delays = [5, 10, 20, 40, 60]  # seconds
max_retries = 3

for attempt in range(max_retries):
    try:
        response = api_call()
        break
    except RateLimitError:
        if attempt < max_retries - 1:
            time.sleep(retry_delays[attempt])
        else:
            raise
```

---

## Output Styles

### Verbose Mode (Default)
```json
{
  "agent": "webflow-api-expert",
  "operation": "create_collection",
  "status": "success",
  "data": {
    "collection_id": "cat_abc123",
    "collection_name": "Blog-Categories",
    "field_count": 3
  },
  "metadata": {
    "execution_time_ms": 850,
    "api_calls_made": 1
  },
  "logs": [
    "Validating collection name...",
    "Checking for slug conflicts...",
    "Creating collection via API...",
    "Collection created successfully"
  ]
}
```

### Quiet Mode
```json
{"collection_id": "cat_abc123", "status": "success"}
```

### Markdown Mode
```markdown
## Webflow Collection Created

**Collection ID:** cat_abc123
**Name:** Blog-Categories
**URL:** https://yoursite.com/blog-category
**Fields:** 3

[View in Webflow Dashboard](https://webflow.com/dashboard/sites/xyz/collections/cat_abc123)
```

---

## Example Workflows

### Workflow 1: Create Blog Infrastructure

```bash
# Step 1: Create Blog-Categories collection
/agent webflow-api-expert create-collection \
  --name "Blog-Categories" \
  --singular "Blog-Category" \
  --slug "blog-category" \
  --fields '[
    {"type": "PlainText", "displayName": "Category Name", "isRequired": true},
    {"type": "PlainText", "displayName": "Category Slug", "isRequired": true}
  ]'

# Step 2: Create Editorials (blog posts) collection
/agent webflow-api-expert create-collection \
  --name "Editorials" \
  --singular "Editorial" \
  --slug "editorial" \
  --fields '[
    {"type": "PlainText", "displayName": "Post Title", "isRequired": true},
    {"type": "RichText", "displayName": "Summary"},
    {"type": "Image", "displayName": "Hero Image"},
    {"type": "RichText", "displayName": "Post Body"}
  ]'

# Step 3: Add Category reference field to Editorials
/agent webflow-api-expert create-field \
  --collection-id "edit_xyz789" \
  --type "Reference" \
  --name "Category" \
  --required \
  --metadata '{"collectionId": "cat_abc123"}'
```

### Workflow 2: Publish Blog Post

```bash
# Step 1: Upload hero image
/agent webflow-api-expert upload-asset \
  --file "./images/llm-architecture.webp" \
  --alt "LLM architecture diagram"
# Returns: asset_id "img_abc123"

# Step 2: Publish blog post item
/agent webflow-api-expert publish-item \
  --collection-id "edit_xyz789" \
  --item-data '{
    "name": "Introduction to LLMs",
    "fieldData": {
      "post-title": "Introduction to LLMs for BI",
      "summary": "Comprehensive guide...",
      "category": "ref_cat123",
      "hero-image": {
        "fileId": "img_abc123",
        "url": "https://uploads-ssl.webflow.com/...",
        "alt": "LLM architecture diagram"
      },
      "post-body": "<p>Article content...</p>"
    }
  }' \
  --publish-now
```

---

## Integration with Other Agents

### Upstream Dependencies
- **notion-mcp-expert** - Provides content to publish
- **notion-content-parser** - Transforms content to HTML
- **asset-migration-handler** - Provides Webflow asset URLs

### Downstream Consumers
- **notion-webflow-syncer** - Orchestrates entire sync workflow using this agent's tools

---

## Troubleshooting

### Issue: "Collection name already exists"
**Solution:** Query existing collections, delete if unused, or use unique name

### Issue: "Rate limit exceeded"
**Solution:** Use `rate_limit_safe=true` in batch operations, or wait 60s before retry

### Issue: "Invalid reference ID"
**Solution:** Verify target item exists in referenced collection using Webflow Dashboard

### Issue: "Asset upload timeout"
**Solution:** Compress image to <5MB, verify stable internet connection

---

## Security Considerations

**API Key Storage:** Store Webflow API key in Azure Key Vault (never commit to git)

**Retrieval:**
```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "webflow-api-key"
```

**Environment Variable:**
```bash
export WEBFLOW_API_KEY="wf_abc123def456..."
```

**Never:**
- Hardcode API key in code
- Log API key in error messages
- Share API key in Notion pages or documentation

---

## Contact & Support

**Brookside BI Support:** Consultations@BrooksideBI.com | +1 209 487 2047

**Webflow API Documentation:** https://developers.webflow.com/reference

**Related Agents:**
- [notion-webflow-syncer](.notion-webflow-syncer.md) - Orchestrator using this agent
- [asset-migration-handler](./asset-migration-handler.md) - Provides assets to upload

---

**Agent Version:** 1.0.0
**Last Updated:** 2025-10-26
**Status:** Production-Ready
