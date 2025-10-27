---
name: style:create
description: Establish new output style registration to expand documentation patterns and support diverse audience communication needs
allowed-tools: mcp__notion__notion-create-pages, mcp__notion__notion-search
argument-hint: [style-name] [audience] [--description=text]
model: claude-sonnet-4-5-20250929
---

# /style:create

**Category**: Documentation Management
**Related Databases**: Output Styles Registry
**Agent Compatibility**: @claude-main

## Purpose

Establish systematic output style registration to expand documentation patterns and support diverse audience communication needs with consistent brand voice and audience-appropriate formatting.

**Best for**: Organizations creating custom documentation styles for specific audiences or content types.

---

## Command Parameters

**Required:**
- `style-name` - Unique style identifier (lowercase-with-hyphens)
- `audience` - Target audience (technical | business | executive | mixed | developer)

**Optional Flags:**
- `--description=text` - Detailed style description
- `--brand-voice=value` - Brand alignment (brookside | neutral | custom)

---

## Workflow

### Step 1: Validate Style Name

```javascript
const styleNamePattern = /^[a-z0-9-]+$/;
if (!styleNamePattern.test(styleName)) {
  console.error(`❌ Invalid style name: ${styleName}`);
  console.log(`Required format: lowercase-with-hyphens`);
  return;
}
```

### Step 2: Check for Duplicates

```javascript
const existing = await notionSearch({
  query: styleName,
  data_source_url: 'collection://199a7a80-224c-470b-9c64-7560ea51b257'
});

if (existing.results.length > 0) {
  console.error(`❌ Style already exists: ${styleName}`);
  return;
}
```

### Step 3: Create Style Entry

```javascript
const audienceMap = {
  'technical': '👨‍💻 Technical',
  'business': '💼 Business',
  'executive': '👔 Executive',
  'mixed': '🎯 Mixed Audience',
  'developer': '⚙️ Developer'
};

await notionCreatePages({
  parent: { data_source_id: '199a7a80-224c-470b-9c64-7560ea51b257' },
  pages: [{
    properties: {
      "Style Name": styleName,
      "Target Audience": audienceMap[audience.toLowerCase()],
      "Description": descriptionFlag || `Custom style for ${audience} audience`,
      "Brand Voice": brandVoiceFlag || 'brookside',
      "Status": '🟢 Active',
      "Created Date": new Date().toISOString().split('T')[0]
    }
  }]
});

console.log(`✅ Style created: ${styleName}`);
console.log(`\n**Style Profile:**`);
console.log(`- Target Audience: ${audienceMap[audience.toLowerCase()]}`);
console.log(`- Brand Voice: ${brandVoiceFlag || 'brookside'}`);
```

### Step 4: Next Steps

```javascript
console.log(`\n**Next Steps:**`);
console.log(`1. Create style file: .claude/styles/${styleName}.md`);
console.log(`2. Test style: /test-agent-style <agent> ${styleName}`);
console.log(`3. Assign to build: /style:assign-default <build> ${styleName}`);
```

---

## Execution Example

```bash
/style:create api-reference-detailed developer \
  --description="Comprehensive API documentation with code examples and authentication details" \
  --brand-voice=neutral
```

**Output:**
```
✅ Style created: api-reference-detailed

**Style Profile:**
- Target Audience: ⚙️ Developer
- Brand Voice: neutral

**Next Steps:**
1. Create style file: .claude/styles/api-reference-detailed.md
2. Test style: /test-agent-style <agent> api-reference-detailed
3. Assign to build: /style:assign-default <build> api-reference-detailed
```

---

## Error Handling

**Error 1: Invalid Name Format**
```
Output: ❌ Invalid style name: API_Reference
        Required format: lowercase-with-hyphens
```

**Error 2: Duplicate Style**
```
Output: ❌ Style already exists: api-reference
```

---

## Success Criteria

- ✅ Style name validated
- ✅ Duplicate check performed
- ✅ Output Styles Registry entry created
- ✅ Next steps guidance provided

---

## Related Commands

- `/style:assign-default` - Assign style to builds
- `/test-agent-style` - Test style effectiveness
- `/style:effectiveness-report` - Track performance

---

## Best Practices

**Do:**
- ✅ Use descriptive style names
- ✅ Create style definition file in `.claude/styles/`
- ✅ Test with multiple agents before production use
- ✅ Document audience and use cases

**Don't:**
- ❌ Create duplicate styles for same audience
- ❌ Skip style file creation
- ❌ Use without effectiveness testing

---

## Notes for Claude Code

**Automatic Execution**: This command executes immediately without requiring user approval.

**Style File Template**: Follow `.claude/styles/README.md` for style definition structure.

---

**Last Updated**: 2025-10-26
**Database**: Output Styles Registry (`199a7a80-224c-470b-9c64-7560ea51b257`)
