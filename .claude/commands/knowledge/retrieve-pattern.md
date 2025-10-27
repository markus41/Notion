---
name: knowledge:retrieve-pattern
description: Establish detailed pattern retrieval from Knowledge Vault to accelerate implementation through proven, reusable solution templates
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch
argument-hint: [pattern-name]
model: claude-sonnet-4-5-20250929
---

# /knowledge:retrieve-pattern

**Category**: Knowledge Management
**Related Databases**: Knowledge Vault
**Agent Compatibility**: @knowledge-curator

## Purpose

Establish comprehensive pattern retrieval workflow that fetches detailed implementation guidance, code examples, and lessons learned from archived patterns to accelerate development through proven, reusable solution templates—designed for organizations building institutional knowledge where pattern reuse drives consistency and reduces time-to-delivery.

**Best for**: Developers starting new builds who need detailed implementation guidance, architects evaluating solution approaches, or teams seeking to replicate successful patterns from previous projects.

---

## Command Parameters

**Required:**
- `pattern-name` - Name or partial match of pattern in Knowledge Vault

---

## Workflow

### Step 1: Search for Pattern

```javascript
const patternResults = await notionSearch({
  query: `${patternName} pattern`,
  data_source_url: "collection://[KNOWLEDGE_VAULT_ID]"
});

// Filter to Pattern content type
const patterns = patternResults.results.filter(result => {
  return result.properties["Content Type"]?.select?.name === "Pattern";
});

if (patterns.length === 0) {
  console.error(`❌ No pattern found: "${patternName}"`);
  console.log(`\nSearch all knowledge: /knowledge:search "${patternName}"`);
  return;
}

const selectedPattern = patterns[0]; // Use first match or prompt if multiple
```

### Step 2: Fetch Complete Pattern Details

```javascript
const patternDetails = await notionFetch({ id: selectedPattern.id });

const pattern = {
  title: patternDetails.properties.Title?.title?.[0]?.plain_text,
  summary: patternDetails.properties.Summary?.rich_text?.[0]?.plain_text,
  content: patternDetails.content, // Full Notion markdown content
  viability: patternDetails.properties["Viability Assessment"]?.select?.name,
  tags: patternDetails.properties.Tags?.multi_select?.map(t => t.name) || [],
  originSource: patternDetails.properties["Origin Source"]?.select?.name,
  relatedWork: patternDetails.properties["Related Work"]?.relation || [],
  lastUpdated: patternDetails.properties["Last Updated"]?.last_edited_time,
  url: patternDetails.url
};

console.log(`✅ Retrieved pattern: ${pattern.title}\n`);
```

### Step 3: Present Pattern Details

```javascript
console.log(`╔══════════════════════════════════════════════════════════════════╗`);
console.log(`║              PATTERN RETRIEVAL                                   ║`);
console.log(`╚══════════════════════════════════════════════════════════════════╝\n`);

console.log(`📐 **Pattern:** ${pattern.title}\n`);

console.log(`**Summary:**`);
console.log(`${pattern.summary}\n`);

console.log(`**Viability:** ${pattern.viability}`);
console.log(`**Tags:** ${pattern.tags.join(', ')}`);
console.log(`**Origin:** ${pattern.originSource}`);
console.log(`**Last Updated:** ${new Date(pattern.lastUpdated).toLocaleDateString()}\n`);

console.log(`━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

console.log(`**Full Pattern Content:**\n`);
console.log(pattern.content); // Display full Notion markdown
console.log(`\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n`);

if (pattern.relatedWork.length > 0) {
  console.log(`**Related Work:**`);
  console.log(`   ${pattern.relatedWork.length} linked items (view in Notion)\n`);
}

console.log(`🔗 **View in Notion:** ${pattern.url}\n`);

console.log(`**Next Steps:**`);
console.log(`   1. Review full pattern in Notion (click URL)`);
console.log(`   2. Adapt pattern to current context`);
console.log(`   3. Document implementation: /build:create "name" --related-research="pattern"`);
```

---

## Execution Examples

### Example 1: Retrieve Integration Pattern

```bash
/knowledge:retrieve-pattern "Azure OpenAI Integration"
```

**Output:**
```
✅ Retrieved pattern: Azure OpenAI Integration Patterns

╔══════════════════════════════════════════════════════════════════╗
║              PATTERN RETRIEVAL                                   ║
╚══════════════════════════════════════════════════════════════════╝

📐 **Pattern:** Azure OpenAI Integration Patterns

**Summary:**
Comprehensive guide to integrating Azure OpenAI with enterprise applications. Covers authentication via Managed Identity, cost optimization through caching, and error handling patterns. Includes Python and TypeScript examples.

**Viability:** Highly Viable
**Tags:** Azure, OpenAI, API, Authentication, Caching
**Origin:** Research
**Last Updated:** 10/15/2025

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Full Pattern Content:**

# Azure OpenAI Integration Patterns

## Authentication Pattern

**Best Practice:** Use Azure Managed Identity for production

```python
from azure.identity import DefaultAzureCredential
from openai import AzureOpenAI

credential = DefaultAzureCredential()
client = AzureOpenAI(
    azure_endpoint="https://your-resource.openai.azure.com",
    api_version="2024-02-01",
    azure_ad_token_provider=credential.get_token
)
```

## Cost Optimization Pattern

**Cache Responses:** Reduce API calls by 40-60%

[... continues with detailed pattern content, code examples, lessons learned ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Related Work:**
   3 linked items (view in Notion)

🔗 **View in Notion:** https://www.notion.so/abc123

**Next Steps:**
   1. Review full pattern in Notion (click URL)
   2. Adapt pattern to current context
   3. Document implementation: /build:create "name" --related-research="pattern"
```

---

### Example 2: Pattern Not Found

```bash
/knowledge:retrieve-pattern "Unknown Pattern"
```

**Output:**
```
❌ No pattern found: "Unknown Pattern"

Search all knowledge: /knowledge:search "Unknown Pattern"
```

---

## Error Handling

### Error 1: Pattern Not Found

```
❌ No pattern found: "name"

Search all knowledge: /knowledge:search "name"
```

---

## Success Criteria

- ✅ Pattern located in Knowledge Vault
- ✅ Complete pattern content retrieved
- ✅ Summary, tags, viability displayed
- ✅ Full implementation guidance presented
- ✅ Related work identified

---

## Related Commands

- `/knowledge:search [query]` - Find patterns first
- `/build:create [name]` - Start build using pattern
- `/knowledge:archive [item]` - Add new patterns

---

## Best Practices

1. **Search First** - Use `/knowledge:search` to find relevant patterns
2. **Adapt, Don't Copy** - Customize patterns to current context
3. **Link to Builds** - Reference patterns when creating builds
4. **Update Patterns** - Improve patterns based on new learnings

---

## Notes for Claude Code

**When to use:** User asks to retrieve pattern, get implementation details, or access archived solutions

**Execution:**
1. Search for pattern by name
2. Fetch complete details
3. Present full content with metadata
4. Suggest implementation next steps

**Performance:** 3-5 seconds

---

**Last Updated**: 2025-10-26
**Database**: Knowledge Vault (query programmatically)
