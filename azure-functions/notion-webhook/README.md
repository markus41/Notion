# Notion Webhook - Agent Activity Logging

Real-time webhook listener for Brookside BI Innovation Nexus agent activity tracking. Establishes reliable bidirectional integration between local agent hooks and Notion Agent Activity Hub with queue-based fallback resilience.

**Best for**: Organizations scaling agent activity monitoring requiring <30 second sync latency with zero data loss.

---

## Architecture

```
Agent Hook Triggers
    ↓
1. Write to Queue (JSONL) ← Always (resilience)
2. HTTP POST to Azure Function ← Real-time attempt
    ↓
    Azure Function validates signature
    ↓
    Creates Notion page in Agent Activity Hub
    ↓
    Returns 200 OK (webhook_synced=true)
    ↓
Queue Processor (every 5-15 min)
    └─ Processes only webhook_synced=false entries
```

**Key Features**:
- ✅ HMAC-SHA256 signature verification (security)
- ✅ Azure Managed Identity (no hardcoded secrets)
- ✅ Application Insights monitoring
- ✅ Queue fallback (never lose data)
- ✅ Consumption plan ($0-5/month)

---

## Prerequisites

1. **Azure Subscription** - Active subscription with resource group
2. **Azure CLI** - `az login` authenticated
3. **Node.js 20 LTS** - For local development
4. **Azure Functions Core Tools** - `npm install -g azure-functions-core-tools@4`
5. **Azure Key Vault** - `kv-brookside-secrets` with secrets:
   - `notion-api-key` - Notion integration token
   - `notion-webhook-secret` - Webhook signing secret (generate: `openssl rand -hex 32`)

---

## Local Development

### 1. Install Dependencies

```bash
cd azure-functions/notion-webhook
npm install
```

### 2. Configure Local Settings

```bash
cp local.settings.json.template local.settings.json
# Edit local.settings.json with your Notion credentials
```

### 3. Build TypeScript

```bash
npm run build
```

### 4. Start Function Locally

```bash
npm start

# Output:
# Http Functions:
#   NotionWebhook: http://localhost:7071/api/NotionWebhook
```

### 5. Test Webhook

```bash
# Test payload
curl -X POST http://localhost:7071/api/NotionWebhook \
  -H "Content-Type: application/json" \
  -H "Notion-Signature: v1=<generated-signature>" \
  -d '{
    "sessionId": "test-session-20251026",
    "agentName": "@cost-analyst",
    "status": "completed",
    "workDescription": "Test webhook integration",
    "startTime": "2025-10-26T10:00:00Z",
    "queuedAt": "2025-10-26T10:00:00Z",
    "syncStatus": "pending",
    "retryCount": 0
  }'
```

---

## Azure Deployment

### 1. Deploy Infrastructure (Bicep)

```bash
cd ../../infrastructure

# Deploy resources
az deployment group create \
  --resource-group rg-brookside-innovation \
  --template-file notion-webhook-function.bicep \
  --parameters environment=prod keyVaultName=kv-brookside-secrets

# Capture outputs
FUNCTION_APP_NAME=$(az deployment group show \
  --resource-group rg-brookside-innovation \
  --name notion-webhook-function \
  --query properties.outputs.functionAppName.value -o tsv)

WEBHOOK_ENDPOINT=$(az deployment group show \
  --resource-group rg-brookside-innovation \
  --name notion-webhook-function \
  --query properties.outputs.webhookEndpoint.value -o tsv)

echo "Function App: $FUNCTION_APP_NAME"
echo "Webhook Endpoint: $WEBHOOK_ENDPOINT"
```

### 2. Deploy Function Code

```bash
cd ../azure-functions/notion-webhook

# Build production bundle
npm run build

# Deploy to Azure
func azure functionapp publish $FUNCTION_APP_NAME
```

### 3. Verify Deployment

```bash
# Check function status
az functionapp show \
  --name $FUNCTION_APP_NAME \
  --resource-group rg-brookside-innovation \
  --query state

# Test webhook endpoint
curl -X POST $WEBHOOK_ENDPOINT \
  -H "Content-Type: application/json" \
  -d '{"sessionId":"test","agentName":"@test","status":"completed","startTime":"2025-01-01T00:00:00Z","queuedAt":"2025-01-01T00:00:00Z","syncStatus":"pending","retryCount":0}'
```

---

## Monitoring

### Application Insights

```bash
# View recent logs
az monitor app-insights query \
  --app ai-notion-webhook-prod \
  --analytics-query "traces | where timestamp > ago(1h) | order by timestamp desc | limit 50"

# View errors
az monitor app-insights query \
  --app ai-notion-webhook-prod \
  --analytics-query "exceptions | where timestamp > ago(24h) | order by timestamp desc"
```

### Metrics Dashboard

- **Success Rate**: `requests | summarize successRate=100.0*countif(success==true)/count() by bin(timestamp, 5m)`
- **Average Latency**: `requests | summarize avg(duration) by bin(timestamp, 5m)`
- **Error Rate**: `exceptions | summarize count() by bin(timestamp, 1h)`

---

## Configuration

### Environment Variables (Azure Function App Settings)

| Variable | Description | Example |
|----------|-------------|---------|
| `KEY_VAULT_NAME` | Azure Key Vault name | `kv-brookside-secrets` |
| `AGENT_ACTIVITY_HUB_ID` | Notion database ID | `72b879f213bd4edb9c59b43089dbef21` |
| `APPINSIGHTS_INSTRUMENTATIONKEY` | Application Insights key | Auto-configured by Bicep |

### Key Vault Secrets

| Secret Name | Purpose | How to Generate |
|-------------|---------|-----------------|
| `notion-api-key` | Notion integration token | Notion Settings → Integrations |
| `notion-webhook-secret` | Webhook signing key | `openssl rand -hex 32` |

---

## Testing

### Unit Tests

```bash
npm test

# Watch mode
npm run test:watch
```

### Integration Tests

```bash
# Test signature verification
npm run test -- signatureVerification.spec.ts

# Test Notion client
npm run test -- notionClient.spec.ts
```

### End-to-End Test

1. Trigger agent via Task tool
2. Hook posts to webhook
3. Verify page created in Notion within 30 seconds
4. Check Application Insights for successful request

---

## Troubleshooting

### Webhook Returns 401 (Invalid Signature)

**Cause**: Signature mismatch between hook and function

**Fix**:
```bash
# Verify webhook secret matches in both locations
az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret

# Ensure hook uses same secret when generating signature
```

### Function Returns 500 (Database Not Found)

**Cause**: Notion integration not shared with Agent Activity Hub database

**Fix**:
1. Open [Agent Activity Hub](https://www.notion.so/72b879f213bd4edb9c59b43089dbef21)
2. Click "..." → "Connections" → "Add connection"
3. Select your Notion integration
4. Retry webhook

### Cold Start Latency >5 Seconds

**Cause**: Consumption plan has cold starts

**Solutions**:
- ✅ **Acceptable**: <30 second latency requirement met
- ⚙️ **Upgrade**: Premium plan ($150/month) for always-on
- 📊 **Monitor**: Application Insights tracks cold start frequency

---

## Cost Optimization

**Current Configuration (Consumption Plan)**:
- Executions: ~200 agent activities/month
- Duration: ~500ms average execution
- Storage: <1 GB
- **Total**: $0.20 - $2.00/month (within free tier)

**Cost Breakdown**:
- First 1M executions/month: Free
- First 400k GB-seconds/month: Free
- Application Insights: $2.30/GB (minimal data)
- Storage: $0.02/GB/month

**Optimization Tips**:
- ✅ Secret caching reduces Key Vault API calls
- ✅ Warm starts reuse function instances
- ✅ Consumption plan scales to zero when idle

---

## Security

### Signature Verification

All webhook requests MUST include valid `Notion-Signature` header:

```
Notion-Signature: v1=<hmac-sha256-hex>
```

**Calculation**:
```bash
echo -n "$REQUEST_BODY" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" -hex
```

### Managed Identity

Function uses System-assigned Managed Identity for Key Vault access (no credentials in code).

**Permissions**:
- Key Vault: `Get` and `List` secrets
- No other Azure permissions required

---

## Phase 2: Bidirectional Workflows (Future)

**Planned Capabilities**:
- ✅ Notion → Local event handling
- ✅ Status change triggers (Completed → Notify Teams)
- ✅ Auto-start research when idea viability = "Needs Research"
- ✅ Blocker detection → Escalation workflow

**Implementation**: After Phase 1 validated (1 week monitoring)

---

## Support

**Documentation**:
- [Webhook Architecture](.claude/docs/webhook-architecture.md)
- [Troubleshooting Guide](.claude/docs/webhook-troubleshooting.md)
- [Notion API Reference](https://developers.notion.com/reference/webhooks)

**Monitoring**:
- Application Insights: https://portal.azure.com
- Queue Status: `.claude/data/notion-sync-queue.jsonl`
- Processor Logs: `.claude/logs/notion-queue-processor.log`

---

**Brookside BI Innovation Nexus** - Sustainable agent activity tracking at scale.
