---
name: knowledge:search
description: Establish comprehensive knowledge retrieval across archived learnings to surface reusable patterns and drive informed decision-making through historical insights
allowed-tools: mcp__notion__notion-search
argument-hint: [query] [--content-type=type] [--viability=level] [--tags=list]
model: claude-sonnet-4-5-20250929
---

# /knowledge:search

**Category**: Knowledge Management
**Related Databases**: Knowledge Vault
**Agent Compatibility**: @knowledge-curator

## Purpose

Establish systematic knowledge retrieval from archived learnings to surface reusable patterns, prevent redundant investigations, and drive informed decision-making through historical insights—designed for organizations building institutional knowledge where past research and build experiences inform future innovation initiatives.

**Best for**: Teams starting new ideas/research/builds who need to check if similar work was already completed, understand what succeeded/failed, and leverage proven patterns rather than starting from scratch.

---

## Command Parameters

**Required:**
- `query` - Search term (topic, technology, pattern name)

**Optional Flags:**
- `--content-type=value` - Filter by type (technical-doc | case-study | process | post-mortem | pattern | tutorial)
- `--viability=value` - Filter by assessment (high | medium | low)
- `--tags=list` - Filter by tags (comma-separated: "azure,ml,api")
- `--status=value` - Filter by status (evergreen | time-sensitive | archived)

---

## Workflow

### Step 1: Build Search Query

```javascript
// Construct Notion search with filters
let searchQuery = query;

// Apply content type filter
if (contentTypeFlag) {
  searchQuery += ` ${contentTypeFlag}`;
}

// Apply tag filter
if (tagsFlag) {
  const tagList = tagsFlag.split(',');
  searchQuery += ` ${tagList.join(' ')}`;
}

console.log(`🔍 Searching Knowledge Vault: "${searchQuery}"\n`);
```

### Step 2: Execute Search

```javascript
const knowledgeResults = await notionSearch({
  query: searchQuery,
  // Knowledge Vault database ID (query programmatically or use known ID)
  data_source_url: "collection://[KNOWLEDGE_VAULT_ID]"
});

if (knowledgeResults.results.length === 0) {
  console.log(`❌ No knowledge entries found matching: "${query}"`);
  console.log(`\n💡 Try:`);
  console.log(`   - Broader search: "${query.split(' ')[0]}"`);
  console.log(`   - Different content type: --content-type=pattern`);
  console.log(`   - Check archived items: /knowledge:search "${query}" --status=archived`);
  return;
}

console.log(`✅ Found ${knowledgeResults.results.length} knowledge entries\n`);
```

### Step 3: Filter and Rank Results

```javascript
// Fetch details for each result
const enrichedResults = [];

for (const result of knowledgeResults.results.slice(0, 10)) {
  const details = await notionFetch({ id: result.id });

  const entry = {
    title: details.properties.Title?.title?.[0]?.plain_text,
    contentType: details.properties["Content Type"]?.select?.name,
    viability: details.properties["Viability Assessment"]?.select?.name,
    tags: details.properties.Tags?.multi_select?.map(tag => tag.name) || [],
    status: details.properties.Status?.select?.name,
    summary: details.properties.Summary?.rich_text?.[0]?.plain_text?.substring(0, 200),
    originSource: details.properties["Origin Source"]?.select?.name,
    url: details.url
  };

  // Apply viability filter
  if (viabilityFlag && entry.viability !== viabilityFlag) continue;

  // Apply status filter
  if (statusFlag && entry.status !== statusFlag) continue;

  enrichedResults.push(entry);
}
```

### Step 4: Present Results

```javascript
console.log(`╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║          KNOWLEDGE VAULT SEARCH RESULTS                         ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`📚 **Query:** "${query}"`);
console.log(`📊 **Results:** ${enrichedResults.length} entries\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

enrichedResults.forEach((entry, idx) => {
  console.log(`${idx + 1}. **${entry.title}**`);
  console.log(`   Type: ${entry.contentType} | Viability: ${entry.viability || 'N/A'}`);
  console.log(`   Status: ${entry.status} | Source: ${entry.originSource}`);

  if (entry.tags.length > 0) {
    console.log(`   Tags: ${entry.tags.join(', ')}`);
  }

  if (entry.summary) {
    console.log(`   Summary: ${entry.summary}...`);
  }

  console.log(`   🔗 ${entry.url}\n`);
});

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

// Suggest related actions
console.log(`**Next Steps:**`);
console.log(`   - View full entry: Click URL above`);
console.log(`   - Retrieve pattern: /knowledge:retrieve-pattern "${enrichedResults[0]?.title}"`);
console.log(`   - Similar searches: Try tags from results above\n`);
```

---

## Execution Examples

### Example 1: General Topic Search

```bash
/knowledge:search "Azure OpenAI"
```

**Output:**
```
🔍 Searching Knowledge Vault: "Azure OpenAI"

✅ Found 4 knowledge entries

╔══════════════════════════════════════════════════════════════════╗
║          KNOWLEDGE VAULT SEARCH RESULTS                         ║
╚══════════════════════════════════════════════════════════════════╝

📚 **Query:** "Azure OpenAI"
📊 **Results:** 4 entries

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. **Azure OpenAI Integration Patterns**
   Type: Pattern | Viability: Highly Viable
   Status: Evergreen | Source: Research
   Tags: Azure, OpenAI, API, Authentication
   Summary: Comprehensive guide to integrating Azure OpenAI with enterprise applications. Covers authentication via Managed Identity, cost optimization through caching, and error...
   🔗 https://www.notion.so/abc123

2. **GPT-4 Cost Optimization Techniques**
   Type: Technical Doc | Viability: Highly Viable
   Status: Evergreen | Source: Build
   Tags: Azure, OpenAI, Cost, Performance
   Summary: Proven techniques to reduce Azure OpenAI costs by 40-60% through prompt engineering, response caching, and intelligent model selection. Includes Python code examples...
   🔗 https://www.notion.so/def456

3. **Azure OpenAI Feasibility Research**
   Type: Case Study | Viability: Highly Viable
   Status: Archived | Source: Research
   Summary: 12-day research investigation into Azure OpenAI capabilities. Key findings: 95% accuracy on domain-specific queries, $650/month cost estimate, strong Microsoft...
   🔗 https://www.notion.so/ghi789

4. **Semantic Search Implementation Post-Mortem**
   Type: Post-Mortem | Viability: Moderately Viable
   Status: Archived | Source: Build
   Tags: Azure, OpenAI, Embeddings, Search
   Summary: Lessons learned from semantic search build using Azure OpenAI embeddings. What worked: Vector similarity. What didn't: Initial index size estimates were 3x too low...
   🔗 https://www.notion.so/jkl012

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Next Steps:**
   - View full entry: Click URL above
   - Retrieve pattern: /knowledge:retrieve-pattern "Azure OpenAI Integration Patterns"
   - Similar searches: Try tags from results above
```

---

### Example 2: Filtered by Content Type

```bash
/knowledge:search "API" --content-type=pattern
```

**Output:**
```
🔍 Searching Knowledge Vault: "API pattern"

✅ Found 3 knowledge entries

[... results filtered to Pattern content type only ...]

1. **RESTful API Design Patterns**
   Type: Pattern | Viability: Highly Viable
   [... details ...]

2. **Azure Function HTTP Trigger Best Practices**
   Type: Pattern | Viability: Highly Viable
   [... details ...]
```

---

### Example 3: Tagged Search

```bash
/knowledge:search "authentication" --tags="azure,security"
```

**Output:**
```
🔍 Searching Knowledge Vault: "authentication azure security"

✅ Found 2 knowledge entries

[... results matching query AND tags ...]
```

---

## Error Handling

### Error 1: No Results Found

```
❌ No knowledge entries found matching: "obscure-technology"

💡 Try:
   - Broader search: "obscure"
   - Different content type: --content-type=pattern
   - Check archived items: /knowledge:search "obscure" --status=archived
```

---

### Error 2: Knowledge Vault Empty

```
⚠️ Knowledge Vault is empty

Add learnings: /knowledge:archive "item-name" [idea|research|build]
```

---

## Success Criteria

- ✅ Search query executed against Knowledge Vault
- ✅ Results filtered by optional parameters
- ✅ Each result includes title, type, viability, tags, summary
- ✅ URLs provided for detailed access
- ✅ Suggested next steps provided

---

## Related Commands

- `/knowledge:retrieve-pattern [name]` - Get full pattern details
- `/knowledge:archive [item]` - Add new learnings
- `/idea:search [criteria]` - Search Ideas Registry instead

---

## Best Practices

1. **Search Before Starting** - Check knowledge before new ideas/research
2. **Use Tags** - Filter by technology tags for precision
3. **Check Evergreen First** - Prioritize --status=evergreen for current best practices
4. **Leverage Patterns** - Pattern content type = reusable solutions

---

## Notes for Claude Code

**When to use:** User asks to search knowledge, find patterns, check if work was done before

**Execution:**
1. Build search query with filters
2. Execute Notion search
3. Enrich results with details
4. Present ranked, filtered results

**Performance:** 5-15 seconds (depends on result count)

---

**Last Updated**: 2025-10-26
**Database**: Knowledge Vault (query programmatically)
