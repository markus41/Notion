---
name: datasource:validate
description: Establish data source connection validation to verify integration health and drive proactive issue detection
allowed-tools: mcp__notion__notion-search, mcp__notion__notion-fetch, Bash
argument-hint: [name]
model: claude-sonnet-4-5-20250929
---

# /datasource:validate

**Category**: Integration Management
**Related Databases**: Data Sources
**Agent Compatibility**: @integration-specialist

## Purpose

Establish systematic data source connection validation to verify integration health, detect connectivity issues, and drive proactive remediation before production impacts.

**Best for**: Health checks before deployments, troubleshooting integration failures, or routine validation of external dependencies.

---

## Command Parameters

**Required:**
- `name` - Data source name to validate

---

## Workflow

### Step 1: Fetch Data Source

```javascript
const dsResults = await notionSearch({
  query: name,
  data_source_url: "collection://092940f4-1e6d-4321-b06a-1c0a9ee79445"
});

const ds = await notionFetch({ id: dsResults.results[0].id });
const endpoint = ds.properties["API Endpoint"]?.url;
```

### Step 2: Test Connection

```javascript
// Example: HTTP endpoint validation
const testResult = await Bash({
  command: `curl -s -o /dev/null -w "%{http_code}" ${endpoint}`,
  timeout: 10000
});

const isHealthy = testResult.stdout === "200";

console.log(isHealthy
  ? `✅ Data source healthy: ${name}`
  : `❌ Data source failed: ${name} (HTTP ${testResult.stdout})`
);
```

---

## Execution Example

```bash
/datasource:validate "Snowflake Analytics"
```

**Output:**
```
✅ Data source healthy: Snowflake Analytics
```

---

**Last Updated**: 2025-10-26
**Database**: Data Sources (092940f4-1e6d-4321-b06a-1c0a9ee79445)