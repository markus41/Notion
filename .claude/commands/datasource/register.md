---
name: datasource:register
description: Establish data source registration for external APIs and databases to maintain integration inventory and connection health
allowed-tools: mcp__notion__notion-create-pages
argument-hint: [name] [type] [--connection-string=value] [--api-endpoint=url]
model: claude-sonnet-4-5-20250929
---

# /datasource:register

**Category**: Integration Management
**Related Databases**: Data Sources
**Agent Compatibility**: @integration-specialist

## Purpose

Establish systematic data source registration for external APIs, databases, and integration endpoints to maintain comprehensive integration inventory and drive connection health monitoring.

**Best for**: Organizations managing multiple external integrations requiring centralized registry of connection strings, API endpoints, and authentication methods.

---

## Command Parameters

**Required:**
- `name` - Data source name
- `type` - Type (api | database | file-storage | message-queue)

**Optional Flags:**
- `--connection-string=value` - Connection string (store in Key Vault, reference only)
- `--api-endpoint=url` - API endpoint URL
- `--auth-method=value` - Authentication method (managed-identity | api-key | oauth)
- `--status=value` - Initial status (active | inactive, default: active)

---

## Workflow

### Step 1: Create Data Source Entry

```javascript
await notionCreatePages({
  parent: { data_source_id: "092940f4-1e6d-4321-b06a-1c0a9ee79445" },
  pages: [{
    properties: {
      "Name": `🔗 ${name}`,
      "Type": typeMap[type],
      "API Endpoint": apiEndpointFlag || null,
      "Connection String Ref": connectionStringFlag || null,
      "Auth Method": authMethodFlag || null,
      "Status": statusMap[statusFlag || 'active'],
      "Registered Date": new Date().toISOString().split('T')[0]
    }
  }]
});

console.log(`✅ Data source registered: ${name}`);
```

### Step 2: Present Security Reminder

```javascript
console.log(`\n⚠️ **Security Reminder:**`);
console.log(`   - Store credentials in Azure Key Vault`);
console.log(`   - Reference secrets via Managed Identity`);
console.log(`   - NEVER hardcode connection strings`);
```

---

## Execution Example

```bash
/datasource:register "Snowflake Analytics" database \
  --connection-string="kv-secret-ref" \
  --auth-method=managed-identity
```

**Output:**
```
✅ Data source registered: Snowflake Analytics

⚠️ **Security Reminder:**
   - Store credentials in Azure Key Vault
   - Reference secrets via Managed Identity
   - NEVER hardcode connection strings
```

---

**Last Updated**: 2025-10-26
**Database**: Data Sources (092940f4-1e6d-4321-b06a-1c0a9ee79445)