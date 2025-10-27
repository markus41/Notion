---
name: style:assign-default
description: Establish default output style for builds to drive consistent documentation patterns and brand alignment across development workflows
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, mcp__notion__notion-update-page
argument-hint: [build-name] [style-name]
model: claude-sonnet-4-5-20250929
---

# /style:assign-default

**Category**: Documentation Management
**Related Databases**: Example Builds, Output Styles Registry
**Agent Compatibility**: @style-orchestrator

## Purpose

Establish default output style assignment for builds to drive consistent documentation patterns, brand alignment, and audience-appropriate communication across development workflows.

**Best for**: Organizations requiring standardized documentation quality across multiple builds with varying audience types (technical, business, executive).

---

## Command Parameters

**Required:**
- `build-name` - Build to configure
- `style-name` - Output style to assign (brookside-professional | technical-deep-dive | executive-brief | tutorial-friendly | api-reference)

---

## Workflow

### Step 1: Fetch Build

```javascript
const buildResults = await notionSearch({
  query: buildName,
  data_source_url: 'collection://a1cd1528-971d-4873-a176-5e93b93555f6'
});

if (buildResults.results.length === 0) {
  console.error(`❌ Build not found: "${buildName}"`);
  return;
}

const build = await notionFetch({ id: buildResults.results[0].id });
```

### Step 2: Validate Style

```javascript
const styleRegistry = await notionSearch({
  query: styleName,
  data_source_url: 'collection://199a7a80-224c-470b-9c64-7560ea51b257'
});

if (styleRegistry.results.length === 0) {
  console.error(`❌ Output style not found: "${styleName}"`);
  console.log(`\nAvailable styles: Use /style:list to see registered styles`);
  return;
}

const style = await notionFetch({ id: styleRegistry.results[0].id });
const styleDetails = {
  name: style.properties["Style Name"]?.title?.[0]?.plain_text,
  audience: style.properties["Target Audience"]?.select?.name,
  description: style.properties["Description"]?.rich_text?.[0]?.plain_text
};
```

### Step 3: Update Build

```javascript
await notionUpdatePage({
  page_id: build.id,
  data: {
    command: 'update_properties',
    properties: {
      "Default Output Style": styleName,
      "Style Updated": new Date().toISOString().split('T')[0]
    }
  }
});

console.log(`✅ Default style assigned: ${styleName}`);
console.log(`\n**Style Details:**`);
console.log(`- Target Audience: ${styleDetails.audience}`);
console.log(`- Description: ${styleDetails.description}`);
```

### Step 4: Documentation Guidance

```javascript
console.log(`\n**Documentation Impact:**`);
console.log(`All future documentation for "${buildName}" will use ${styleName} style:`);
console.log(`- README.md generation`);
console.log(`- API documentation`);
console.log(`- Technical specifications`);
console.log(`- Deployment guides`);

console.log(`\n**Override for Specific Documents:**`);
console.log(`Use --style flag: /docs:generate "${buildName}" --style=api-reference`);
```

---

## Execution Example

```bash
/style:assign-default "Customer Analytics Platform" brookside-professional
```

**Output:**
```
✅ Default style assigned: brookside-professional

**Style Details:**
- Target Audience: Business & Technical Mixed
- Description: Professional corporate tone with outcome-focused language, suitable for stakeholder presentations and technical documentation

**Documentation Impact:**
All future documentation for "Customer Analytics Platform" will use brookside-professional style:
- README.md generation
- API documentation
- Technical specifications
- Deployment guides

**Override for Specific Documents:**
Use --style flag: /docs:generate "Customer Analytics Platform" --style=api-reference
```

---

## Error Handling

**Error 1: Build Not Found**
```
Input: /style:assign-default "Nonexistent Build" brookside-professional
Output: ❌ Build not found: "Nonexistent Build"
```

**Error 2: Style Not Found**
```
Input: /style:assign-default "Customer Platform" custom-style
Output: ❌ Output style not found: "custom-style"

        Available styles: Use /style:list to see registered styles
```

---

## Success Criteria

- ✅ Build located in Example Builds
- ✅ Output style validated in registry
- ✅ Build property updated
- ✅ Documentation guidance provided

---

## Related Commands

- `/style:create` - Register new output style
- `/style:effectiveness-report` - Analyze style performance
- `/docs:generate` - Generate documentation with assigned style

---

## Best Practices

**Do:**
- ✅ Match style to primary audience (technical vs business)
- ✅ Review style description before assignment
- ✅ Test style on sample documentation
- ✅ Update style as audience needs evolve

**Don't:**
- ❌ Use executive-brief for technical API docs
- ❌ Assign styles without understanding audience
- ❌ Override without checking default first

---

## Notes for Claude Code

**Automatic Execution**: This command executes immediately without requiring user approval for Notion MCP operations.

**Style Enforcement**: Default style is used by documentation generation commands unless explicitly overridden with `--style` flag.

---

**Last Updated**: 2025-10-26
**Databases**:
- Example Builds: `a1cd1528-971d-4873-a176-5e93b93555f6`
- Output Styles Registry: `199a7a80-224c-470b-9c64-7560ea51b257`
