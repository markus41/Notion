# notion-mcp-expert

**Agent ID:** `notion-mcp-expert`
**Version:** 1.0.0
**Category:** Platform Integration
**Dependencies:** Notion MCP tools

**Best for:** Organizations with Notion as system of record requiring automated workflow integration across databases.

---

## Purpose

Establish robust Notion database operations to streamline content queries, property updates, and relation management. Designed for teams treating Notion as source of truth for structured content, projects, and knowledge management.

**Business Value:**
- Query Blog Posts database with complex filters (status="Published", category="Engineering")
- Update sync tracking fields programmatically (Webflow Item ID, Last Synced timestamps)
- Maintain relation integrity across databases (Blog Posts → Knowledge Vault Categories)
- Enable headless workflows (external systems read/write Notion without manual UI interaction)

---

## Capabilities

### Core Operations
- **Database Queries** - Filter, sort, paginate database contents
- **Property Updates** - Modify page properties (text, date, status, relations)
- **Page Creation** - Create pages with properties + content blocks
- **Relation Management** - Link pages across databases via relation fields
- **Schema Inspection** - Retrieve database schema for validation

### Integration Points
- Notion MCP tools (`mcp__notion__*` functions)
- Notion API v2022-06-28
- Rate limit: ~3 requests/second (throttled if excessive)
- Authentication: Integration token (from Notion workspace settings)

---

## Tools

### 1. notion_query_database

**Purpose:** Query database with filters and sorts

**When to use:**
- Fetch all blog posts with Status="Draft" for batch sync
- Find posts needing sync (Sync Status="Not Synced")
- Retrieve unpublished content for review workflow

**Function Signature:**
```python
def notion_query_database(
    database_id: str,
    filter_spec: Optional[Dict] = None,
    sorts: Optional[List[Dict]] = None,
    page_size: int = 100
) -> QueryResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `database_id` | string | Yes | Notion database ID (32-char UUID) |
| `filter_spec` | Dict | No | Filter criteria (see examples below) |
| `sorts` | List[Dict] | No | Sort order specifications |
| `page_size` | int | No (default: 100) | Results per page (max 100) |

**Filter Examples:**

**Simple Filter (Status = "Published"):**
```json
{
  "property": "Status",
  "status": {"equals": "Published"}
}
```

**Compound Filter (Status="Published" AND Category="Engineering"):**
```json
{
  "and": [
    {
      "property": "Status",
      "status": {"equals": "Published"}
    },
    {
      "property": "Category",
      "relation": {"contains": "<category-page-id>"}
    }
  ]
}
```

**Sort Specification:**
```json
[
  {
    "property": "Publish Date",
    "direction": "descending"
  }
]
```

**Example:**
```bash
/agent notion-mcp-expert query-database \
  --database-id "97adad39160248d697868056a0075d9c" \
  --filter '{"property": "Sync Status", "status": {"equals": "Not Synced"}}' \
  --sort '[{"property": "Publish Date", "direction": "descending"}]' \
  --page-size 50
```

**Success Output:**
```json
{
  "agent": "notion-mcp-expert",
  "status": "success",
  "data": {
    "results": [
      {
        "page_id": "abc123def456",
        "properties": {
          "Post Title": {
            "title": [{"plain_text": "Introduction to LLMs"}]
          },
          "Category": {
            "relation": [{"id": "cat_xyz789"}]
          },
          "Publish Date": {
            "date": {"start": "2025-10-26"}
          },
          "Status": {
            "status": {"name": "Published"}
          },
          "Sync Status": {
            "status": {"name": "Not Synced"}
          }
        },
        "url": "https://notion.so/abc123def456"
      }
    ],
    "total_count": 15,
    "has_more": false
  },
  "metadata": {
    "execution_time_ms": 450
  }
}
```

**Filter Property Types:**
- **Text**: `{"property": "Name", "rich_text": {"contains": "keyword"}}`
- **Number**: `{"property": "Count", "number": {"greater_than": 10}}`
- **Checkbox**: `{"property": "Done", "checkbox": {"equals": true}}`
- **Select**: `{"property": "Status", "select": {"equals": "Active"}}`
- **Multi-Select**: `{"property": "Tags", "multi_select": {"contains": "AI"}}`
- **Date**: `{"property": "Created", "date": {"on_or_after": "2025-01-01"}}`
- **Relation**: `{"property": "Category", "relation": {"contains": "page-id"}}`

---

### 2. notion_update_page_properties

**Purpose:** Update page properties (sync tracking, status changes)

**When to use:**
- Write Webflow Item ID after successful publish
- Update Last Synced timestamp
- Change Sync Status ("Not Synced" → "Synced")
- Mark post status ("Draft" → "Published")

**Function Signature:**
```python
def notion_update_page_properties(
    page_id: str,
    property_updates: Dict[str, Any]
) -> UpdateResponse
```

**Input Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `page_id` | string | Yes | Page ID to update (32-char UUID) |
| `property_updates` | Dict | Yes | Properties to update (see format below) |

**Property Update Format:**

**Text Property:**
```json
{
  "Webflow Item ID": {
    "rich_text": [{"text": {"content": "item_xyz789"}}]
  }
}
```

**Date Property:**
```json
{
  "Last Synced": {
    "date": {"start": "2025-10-26T10:30:00Z"}
  }
}
```

**Status Property:**
```json
{
  "Sync Status": {
    "status": {"name": "Synced"}
  }
}
```

**Relation Property (single):**
```json
{
  "Category": {
    "relation": [{"id": "cat_abc123"}]
  }
}
```

**Example:**
```bash
/agent notion-mcp-expert update-properties \
  --page-id "abc123def456" \
  --properties '{
    "Webflow Item ID": {"rich_text": [{"text": {"content": "item_xyz789"}}]},
    "Last Synced": {"date": {"start": "2025-10-26T10:30:00Z"}},
    "Sync Status": {"status": {"name": "Synced"}}
  }'
```

**Success Output:**
```json
{
  "agent": "notion-mcp-expert",
  "status": "success",
  "data": {
    "page_id": "abc123def456",
    "updated_properties": ["Webflow Item ID", "Last Synced", "Sync Status"],
    "last_edited_time": "2025-10-26T10:30:15Z"
  }
}
```

**Error Handling:**
- Property name not found → Verify property exists in database schema
- Type mismatch → Check property type (text vs. rich_text, etc.)
- Relation target invalid → Verify target page exists
- Page locked → Check edit permissions

---

### 3. notion_fetch_page

**Purpose:** Retrieve page properties + content blocks

**When to use:**
- Fetch blog post content for transformation to HTML
- Extract metadata (title, summary, category)
- Validate post has required fields before sync

**Function Signature:**
```python
def notion_fetch_page(
    page_id: str,
    include_content: bool = True
) -> PageResponse
```

**Example:**
```bash
/agent notion-mcp-expert fetch-page \
  --page-id "abc123def456" \
  --include-content
```

**Success Output:**
```json
{
  "agent": "notion-mcp-expert",
  "status": "success",
  "data": {
    "page_id": "abc123def456",
    "title": "Introduction to LLMs for Business Intelligence",
    "properties": {
      "Post Title": {"title": [{"plain_text": "Introduction to LLMs for BI"}]},
      "Summary": {"rich_text": [{"plain_text": "Comprehensive guide to using LLMs in BI workflows..."}]},
      "Category": {"relation": [{"id": "cat_xyz789"}]},
      "Publish Date": {"date": {"start": "2025-10-26"}},
      "Status": {"status": {"name": "Published"}},
      "Hero Image": {"files": [{"name": "llm-cover.png", "url": "https://..."}]}
    },
    "content_blocks": [
      {
        "type": "heading_2",
        "heading_2": {"rich_text": [{"plain_text": "Introduction"}]}
      },
      {
        "type": "paragraph",
        "paragraph": {"rich_text": [{"plain_text": "Large language models transform..."}]}
      }
    ]
  }
}
```

---

### 4. notion_create_page_with_blocks

**Purpose:** Create new page with properties and content

**When to use:**
- Create test blog posts programmatically
- Generate draft posts from templates
- Backfill missing content entries

**Function Signature:**
```python
def notion_create_page_with_blocks(
    parent_id: str,  # Database ID
    title: str,
    properties: Dict[str, Any],
    content_blocks: List[Dict]
) -> CreateResponse
```

**Example:**
```bash
/agent notion-mcp-expert create-page \
  --parent-db "97adad39160248d697868056a0075d9c" \
  --title "New Blog Post Draft" \
  --properties '{
    "Summary": {"rich_text": [{"text": {"content": "Article summary..."}}]},
    "Category": {"relation": [{"id": "cat_abc123"}]},
    "Publish Date": {"date": {"start": "2025-10-27"}},
    "Status": {"status": {"name": "Draft"}}
  }' \
  --content '[
    {"type": "heading_2", "heading_2": {"rich_text": [{"text": {"content": "Introduction"}}]}},
    {"type": "paragraph", "paragraph": {"rich_text": [{"text": {"content": "Article content..."}}]}}
  ]'
```

**Success Output:**
```json
{
  "agent": "notion-mcp-expert",
  "status": "success",
  "data": {
    "page_id": "new_page_123",
    "url": "https://notion.so/new_page_123",
    "title": "New Blog Post Draft",
    "blocks_created": 2
  }
}
```

---

## Integration with Other Agents

### Upstream Dependencies
- **None** - Foundational agent, no dependencies

### Downstream Consumers
- **notion-content-parser** - Uses fetch_page to retrieve content for transformation
- **notion-webflow-syncer** - Uses query_database to find posts, update_properties to track sync state
- **All agents** - Common Notion data access layer

---

## Error Handling

| Error | Cause | Resolution |
|-------|-------|------------|
| Database not found | Invalid database ID | Verify ID, check integration has access |
| Property not found | Typo in property name | Check database schema for exact names |
| Type mismatch | Wrong property format | Match property type (text, number, etc.) |
| Rate limit | >3 req/s | Add 350ms delay between requests |
| Relation target invalid | Referenced page doesn't exist | Verify target page ID |
| Permission denied | Integration lacks access | Add integration to page/database |

---

## Security Considerations

**API Token Storage:** Azure Key Vault (existing Innovation Nexus pattern)

```powershell
.\scripts\Get-KeyVaultSecret.ps1 -SecretName "notion-api-key"
```

**Environment Variable:**
```bash
export NOTION_API_KEY="secret_abc123..."
```

---

## Contact & Support

**Brookside BI Support:** Consultations@BrooksideBI.com | +1 209 487 2047

**Related Agents:**
- [notion-content-parser](./notion-content-parser.md) - Content transformation
- [notion-webflow-syncer](./notion-webflow-syncer.md) - Orchestration

---

**Agent Version:** 1.0.0
**Last Updated:** 2025-10-26
**Status:** Production-Ready
