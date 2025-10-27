---
name: idea:search
description: Retrieve innovation opportunities with flexible filtering across status, viability, and ownership
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [query] [--status=filter] [--viability=level] [--champion=person]
model: claude-sonnet-4-5-20250929
---

# /idea:search

**Category**: Innovation Management
**Related Databases**: Ideas Registry
**Agent Compatibility**: @ideas-capture, @viability-assessor

## Purpose

Establish rapid discovery and retrieval of innovation opportunities through flexible multi-criteria search across Ideas Registry. Drive informed decision-making by enabling teams to find relevant ideas, assess duplication before creating new entries, and track viability progression across the innovation pipeline.

**Best for**: Organizations managing large innovation portfolios requiring efficient idea discovery, duplicate prevention workflows, and viability-based filtering for strategic prioritization.

---

## Command Parameters

**Required:**
- `query` - Search term (idea name, description keywords, or related concepts)

**Optional Flags:**
- `--status=filter` - Filter by idea status
  - Values: `concept` | `active` | `not-active` | `completed` | `all` (default: all)
- `--viability=level` - Filter by viability assessment
  - Values: `high` | `medium` | `low` | `needs-research` | `all` (default: all)
- `--champion=person` - Filter by champion/owner (exact name match)
- `--limit=N` - Maximum results to return (default: 10, max: 50)
- `--sort=field` - Sort results by field
  - Values: `viability` | `created` | `updated` | `name` (default: relevance)

---

## Workflow

### Step 1: Build Search Query
```javascript
// Combine query with filters for targeted search
const searchParams = {
  query: searchTerm,
  data_source_url: "collection://984a4038-3e45-4a98-8df4-fd64dd8a1032"
};

// Apply filters if provided
if (statusFilter && statusFilter !== 'all') {
  // Notion MCP search doesn't support direct property filters
  // We'll filter results post-query
  searchParams.query += ` ${getStatusEmoji(statusFilter)}`;
}
```

### Step 2: Execute Search
```javascript
const results = await notionSearch(searchParams);

console.log(`🔍 Searching Ideas Registry for: "${searchTerm}"`);
console.log(`📊 Found ${results.results.length} potential matches\n`);
```

### Step 3: Apply Post-Search Filters
```javascript
let filteredResults = results.results;

// Filter by status if specified
if (statusFilter && statusFilter !== 'all') {
  const statusMap = {
    'concept': '🔵 Concept',
    'active': '🟢 Active',
    'not-active': '⚫ Not Active',
    'completed': '✅ Completed'
  };

  filteredResults = filteredResults.filter(idea =>
    idea.properties.Status?.select?.name === statusMap[statusFilter]
  );
}

// Filter by viability if specified
if (viabilityFilter && viabilityFilter !== 'all') {
  const viabilityMap = {
    'high': '💎 High',
    'medium': '⚡ Medium',
    'low': '🔻 Low',
    'needs-research': '❓ Needs Research'
  };

  filteredResults = filteredResults.filter(idea =>
    idea.properties.Viability?.select?.name === viabilityMap[viabilityFilter]
  );
}

// Filter by champion if specified
if (championFilter) {
  filteredResults = filteredResults.filter(idea => {
    const champions = idea.properties.Champion?.people || [];
    return champions.some(person =>
      person.name.toLowerCase().includes(championFilter.toLowerCase())
    );
  });
}

// Apply limit
filteredResults = filteredResults.slice(0, limitValue);
```

### Step 4: Sort Results
```javascript
if (sortField && sortField !== 'relevance') {
  filteredResults.sort((a, b) => {
    if (sortField === 'viability') {
      const viabilityOrder = { '💎 High': 4, '⚡ Medium': 3, '🔻 Low': 2, '❓ Needs Research': 1 };
      const aViability = viabilityOrder[a.properties.Viability?.select?.name] || 0;
      const bViability = viabilityOrder[b.properties.Viability?.select?.name] || 0;
      return bViability - aViability; // Descending
    } else if (sortField === 'created') {
      return new Date(b.created_time) - new Date(a.created_time);
    } else if (sortField === 'updated') {
      return new Date(b.last_edited_time) - new Date(a.last_edited_time);
    } else if (sortField === 'name') {
      return a.properties.Title.localeCompare(b.properties.Title);
    }
  });
}
```

### Step 5: Format and Display Results
```javascript
console.log(`✅ ${filteredResults.length} ideas match your criteria:\n`);

filteredResults.forEach((idea, index) => {
  const title = idea.properties["Idea Name"]?.title?.[0]?.plain_text || "Untitled";
  const status = idea.properties.Status?.select?.name || "Unknown";
  const viability = idea.properties.Viability?.select?.name || "Unassessed";
  const champion = idea.properties.Champion?.people?.[0]?.name || "Unassigned";
  const estimatedCost = idea.properties["Estimated Monthly Cost"]?.number || 0;

  console.log(`${index + 1}. **${title}**`);
  console.log(`   Status: ${status}`);
  console.log(`   Viability: ${viability}`);
  console.log(`   Champion: ${champion}`);

  if (estimatedCost > 0) {
    console.log(`   Est. Cost: $${estimatedCost}/month`);
  }

  console.log(`   🔗 ${idea.url}\n`);
});

// Provide action suggestions
if (filteredResults.length > 0) {
  console.log(`\n📌 **Next Steps:**`);
  console.log(`1. View idea details: Click Notion URL above`);
  console.log(`2. Assess viability: /idea:assess [idea-name]`);
  console.log(`3. Start research: /innovation:start-research [topic] [idea-name]`);
  console.log(`4. Create new variant: /innovation:new-idea [description]`);
}
```

---

## Execution Examples

### Example 1: Simple Keyword Search
```bash
/idea:search "Azure OpenAI"
```

**Expected Output:**
```
🔍 Searching Ideas Registry for: "Azure OpenAI"
📊 Found 3 potential matches

✅ 3 ideas match your criteria:

1. **💡 Azure OpenAI Integration for Customer Support**
   Status: 🟢 Active
   Viability: 💎 High
   Champion: Markus Ahling
   Est. Cost: $150/month
   🔗 https://notion.so/...

2. **💡 Azure OpenAI Document Summarization**
   Status: 🔵 Concept
   Viability: ❓ Needs Research
   Champion: Unassigned
   🔗 https://notion.so/...

3. **💡 Migrate from OpenAI to Azure OpenAI**
   Status: ✅ Completed
   Viability: 💎 High
   Champion: Alec Fielding
   🔗 https://notion.so/...

📌 **Next Steps:**
1. View idea details: Click Notion URL above
2. Assess viability: /idea:assess [idea-name]
3. Start research: /innovation:start-research [topic] [idea-name]
4. Create new variant: /innovation:new-idea [description]
```

### Example 2: Filter by Status and Viability
```bash
/idea:search "Power BI" --status=active --viability=high
```

**Expected Output:**
```
🔍 Searching Ideas Registry for: "Power BI"
📊 Found 7 potential matches

Filtering by: Status = Active, Viability = High

✅ 2 ideas match your criteria:

1. **💡 Power BI Governance Dashboard**
   Status: 🟢 Active
   Viability: 💎 High
   Champion: Brad Wright
   Est. Cost: $120/month
   🔗 https://notion.so/...

2. **💡 Power BI Embedded Analytics for Clients**
   Status: 🟢 Active
   Viability: 💎 High
   Champion: Markus Ahling
   Est. Cost: $500/month
   🔗 https://notion.so/...

📌 **Next Steps:**
1. View idea details: Click Notion URL above
2. Start research: /innovation:start-research [topic] [idea-name]
3. Create build: /build:create [name] --origin-idea=[idea-name]
```

### Example 3: Find Ideas Needing Research
```bash
/idea:search "" --viability=needs-research --limit=5
```

**Expected Output:**
```
🔍 Searching Ideas Registry for all ideas
📊 Found 24 potential matches

Filtering by: Viability = Needs Research
Limit: 5 results

✅ 5 ideas match your criteria:

1. **💡 Real-time Collaboration with Azure SignalR**
   Status: 🔵 Concept
   Viability: ❓ Needs Research
   Champion: Stephan Densby
   🔗 https://notion.so/...

2. **💡 Multi-tenant Data Isolation Patterns**
   Status: 🔵 Concept
   Viability: ❓ Needs Research
   Champion: Unassigned
   🔗 https://notion.so/...

[... 3 more ideas ...]

📌 **Next Steps:**
1. Start research: /innovation:start-research [topic] [idea-name]
2. Assess viability: /idea:assess [idea-name]
```

### Example 4: No Results Found
```bash
/idea:search "Blockchain" --status=active
```

**Expected Output:**
```
🔍 Searching Ideas Registry for: "Blockchain"
📊 Found 0 potential matches

Filtering by: Status = Active

❌ No ideas found matching your criteria

💡 **Suggestions:**
- Try broader search terms
- Remove filters (--status, --viability) to see all results
- Create new idea: /innovation:new-idea "Blockchain integration for..."
- Search all databases: Use Notion global search
```

---

## Error Handling

### Error 1: Ideas Registry Not Accessible
**Scenario**: Notion MCP can't access Ideas Registry database
**Response**:
```
❌ Cannot access Ideas Registry database

💡 **Resolution:**
1. Verify Notion MCP has read access to Ideas Registry
2. Check data source ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032
3. Ensure workspace permissions are correct
4. See .claude/docs/notion-schema.md lines 40-99 for schema

**Required Permissions**: Viewer or higher
```

### Error 2: Invalid Filter Value
**Scenario**: User provides invalid status or viability value
**Response**:
```
❌ Invalid status filter: "inprogress"

💡 **Valid Status Values:**
- concept (🔵 Concept)
- active (🟢 Active)
- not-active (⚫ Not Active)
- completed (✅ Completed)
- all (no filter)

Example: /idea:search "query" --status=active
```

### Error 3: Empty Query with No Filters
**Scenario**: User provides empty search string and no filters
**Response**:
```
⚠️ Empty search with no filters will return all ideas (may be slow)

💡 **Recommendations:**
- Provide search term: /idea:search "keyword"
- Use filters: --status=active or --viability=high
- Limit results: --limit=10

Continue with full search? (y/n)
```

### Error 4: Too Many Results
**Scenario**: Search returns more than max limit
**Response**:
```
⚠️ Search returned 73 results (exceeds max limit of 50)

Showing first 50 results. Refine your search to see others.

💡 **Tips for Better Results:**
- Use more specific search terms
- Apply filters: --status, --viability, --champion
- Sort by relevance: Results are already sorted by best match
```

---

## Success Criteria

After successful execution, verify:

- ✅ Search executes against Ideas Registry data source
- ✅ Results match search query (keyword relevance)
- ✅ Filters applied correctly (status, viability, champion)
- ✅ Results sorted according to --sort parameter
- ✅ Each result displays:
  - Idea name (with emoji prefix)
  - Status
  - Viability assessment
  - Champion/owner
  - Estimated monthly cost (if set)
  - Notion URL for direct access
- ✅ Next steps suggested based on result context
- ✅ Clear messaging if no results found

---

## Related Commands

**Before this command:**
- N/A - This is a discovery/query command

**Use this command before:**
- `/innovation:new-idea` - Search for duplicates before creating
- `/idea:assess` - Find idea to assess
- `/innovation:start-research` - Find idea to research

**After this command:**
- `/idea:assess [idea-name]` - Re-evaluate viability
- `/innovation:start-research [topic] [idea-name]` - Begin feasibility study
- `/build:create [name] --origin-idea=[idea-name]` - Create build from idea
- `/knowledge:archive [idea-name] idea` - Archive completed idea

**Related workflows:**
- Duplicate prevention: Always search before `/innovation:new-idea`
- Quarterly review: Search `--viability=needs-research` to identify research candidates
- Portfolio management: Search `--status=active` to view current innovation initiatives

---

## Best Practices

### 1. Always Search Before Creating New Ideas
Establish duplicate prevention discipline by searching Ideas Registry before submitting new innovation proposals. Use broad keywords first, then narrow with filters.

### 2. Use Viability Filter for Strategic Prioritization
Filter by `--viability=high` to identify ready-to-build ideas, or `--viability=needs-research` to populate research pipeline with strategic investigations.

### 3. Combine Filters for Targeted Discovery
Example: `--status=active --viability=high --champion="Markus Ahling"` finds high-viability active ideas owned by specific champion.

### 4. Leverage Sort Options for Different Use Cases
- `--sort=viability`: Strategic planning (highest viability first)
- `--sort=created`: Recent submissions review
- `--sort=updated`: Active work identification
- Default (relevance): Best keyword matches

---

## Notes for Claude Code

**When to use this command:**
- User asks "what ideas do we have about..."
- Before `/innovation:new-idea` to check for duplicates
- User requests idea portfolio review
- Finding specific idea for assessment or research

**Execution approach:**
1. Start with broad search (just query, no filters)
2. If too many results, suggest filters to user
3. If no results, suggest broader terms or removing filters
4. Always show Notion URLs for easy access
5. Suggest logical next steps based on search context

**Search Strategy:**
- Notion MCP search uses semantic matching (not exact string match)
- Including status emoji in query (🔵, 🟢) can improve filter accuracy
- Empty query with filters is valid (returns all filtered results)

**Common use cases:**
- Duplicate prevention: `/idea:search "similar concept" --status=all`
- Research pipeline: `/idea:search "" --viability=needs-research`
- Active portfolio: `/idea:search "" --status=active --sort=viability`
- Champion review: `/idea:search "" --champion="Name"`

**Common mistakes to avoid:**
- Not suggesting filters when too many results returned
- Forgetting to suggest `/innovation:new-idea` if no duplicates found
- Not showing next steps after search results
- Using exact match expectations (Notion uses semantic search)

---

**Last Updated**: 2025-10-26
**Command Version**: 1.0.0
**Automation Coverage Impact**: Enables duplicate prevention and idea discovery workflows
