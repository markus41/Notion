# Webhook Architecture - Real-time Agent Activity Synchronization

**Status**: Phase 1 Implemented (October 26, 2025)
**Purpose**: Establish real-time bidirectional integration between Innovation Nexus local environment and Notion Agent Activity Hub through Azure Function webhook endpoints with queue-based resilience.

**Best for**: Organizations scaling agent activity monitoring requiring <30 second sync latency with zero data loss guarantees and minimal operational overhead.

---

## Executive Summary

The webhook enhancement transforms agent activity logging from batch-processed (1-5 minute delay) to real-time synchronized (<30 seconds) while maintaining 100% resilience through dual-path architecture. Azure Function webhook serves as professional, scalable endpoint requiring zero infrastructure management at $0-5/month operational cost.

**Key Benefits**:
- ⚡ **Real-time Visibility**: <30 second latency from agent completion to Notion page creation
- 🛡️ **Zero Data Loss**: Queue fallback ensures activities logged even during Azure outages
- 💰 **Cost Efficient**: $0.20-$2.00/month within Azure free tier (Consumption plan)
- 🔒 **Enterprise Security**: HMAC-SHA256 signature verification + Managed Identity + Key Vault
- 📊 **Observability**: Application Insights monitoring with 30-day retention
- 🔄 **Phase 2 Foundation**: Bidirectional workflow infrastructure for Notion → Local triggers

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    LOCAL ENVIRONMENT (.claude/)                     │
│                                                                      │
│  ┌──────────────────────────┐                                       │
│  │   Task Tool Invocation   │ User delegates work to agent          │
│  │   (@cost-analyst, etc.)  │                                       │
│  └──────────┬───────────────┘                                       │
│             │                                                        │
│             v                                                        │
│  ┌──────────────────────────┐                                       │
│  │ auto-log-agent-activity  │ Hook triggered on agent completion    │
│  │        .ps1 Hook         │                                       │
│  └──────────┬───────────────┘                                       │
│             │                                                        │
│  ┌──────────v─────────────────────────────────────┐                 │
│  │      DUAL-PATH SYNCHRONIZATION FLOW            │                 │
│  │                                                 │                 │
│  │  1. ALWAYS Write to Queue (JSONL)              │                 │
│  │     └─> .claude/data/notion-sync-queue.jsonl   │                 │
│  │         (Resilience backup)                     │                 │
│  │                                                 │                 │
│  │  2. TRY Webhook POST (Fast path)               │                 │
│  │     └─> HTTPS → Azure Function Endpoint        │                 │
│  │         (Real-time synchronization)             │                 │
│  │                                                 │                 │
│  │  3. Mark Queue Entry                           │                 │
│  │     └─> webhookSynced: true/false              │                 │
│  └─────────┬────────────────────────┬─────────────┘                 │
│            │                        │                                │
│            │ Webhook Success        │ Webhook Failed                │
│            v                        v                                │
│  ┌─────────────────┐    ┌──────────────────────┐                   │
│  │ Queue Processor │    │  Queue Processor     │                   │
│  │ (Every 5-15min) │    │  (Every 5-15min)     │                   │
│  │                 │    │                      │                   │
│  │ ✓ Skip entry    │    │ → Retry via Notion   │                   │
│  │   (already      │    │   MCP API            │                   │
│  │    synced)      │    │                      │                   │
│  └─────────────────┘    └──────────────────────┘                   │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS POST
                           │ Header: Notion-Signature
                           │ Body: AgentActivityEvent JSON
                           v
┌─────────────────────────────────────────────────────────────────────┐
│                      AZURE CLOUD (Serverless)                       │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │         Azure Function (Consumption Plan - Linux)             │  │
│  │               Node.js 20 LTS Runtime                          │  │
│  │                                                               │  │
│  │  ┌────────────────────────────────────────────────────────┐  │  │
│  │  │ NotionWebhook HTTP Trigger (POST /api/NotionWebhook)   │  │  │
│  │  │                                                         │  │  │
│  │  │  1. Retrieve Secrets (Cached)                          │  │  │
│  │  │     └─> Azure Key Vault (Managed Identity)             │  │  │
│  │  │         - notion-api-key                               │  │  │
│  │  │         - notion-webhook-secret                        │  │  │
│  │  │                                                         │  │  │
│  │  │  2. Verify Signature                                   │  │  │
│  │  │     └─> HMAC-SHA256 with timing-safe comparison        │  │  │
│  │  │         (Security: Prevent unauthorized requests)       │  │  │
│  │  │                                                         │  │  │
│  │  │  3. Validate Payload                                   │  │  │
│  │  │     └─> Check required fields                          │  │  │
│  │  │         (sessionId, agentName, status)                 │  │  │
│  │  │                                                         │  │  │
│  │  │  4. Create Notion Page                                 │  │  │
│  │  │     └─> POST to Notion API                             │  │  │
│  │  │         /v1/pages (Agent Activity Hub)                 │  │  │
│  │  │                                                         │  │  │
│  │  │  5. Return Response                                    │  │  │
│  │  │     └─> 200 OK: { success, pageId, pageUrl }          │  │  │
│  │  │     └─> 401: Invalid signature                         │  │  │
│  │  │     └─> 500: Notion API error                          │  │  │
│  │  └────────────────────────────────────────────────────────┘  │  │
│  │                                                               │  │
│  │  Application Insights: Logs, metrics, errors (30-day)        │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
                           │
                           │ HTTPS POST
                           │ Notion API: /v1/pages
                           v
┌─────────────────────────────────────────────────────────────────────┐
│                        NOTION WORKSPACE                              │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │           Agent Activity Hub Database                         │  │
│  │       (Data Source: 7163aa38-f3d9-444b-9674-bde61868bd2b)    │  │
│  │                                                               │  │
│  │  Properties:                                                  │  │
│  │  - Session ID (Title)                                         │  │
│  │  - Agent Name (Select)                                        │  │
│  │  - Status (Select: In Progress, Completed, Blocked, ...)     │  │
│  │  - Start Time / End Time (Date)                              │  │
│  │  - Duration (Minutes) (Number)                               │  │
│  │  - Work Description (Text)                                    │  │
│  │  - Files Created / Updated (Number)                          │  │
│  │  - Lines Generated (Number)                                   │  │
│  │  - Deliverables (Text)                                        │  │
│  │  - Next Steps (Text)                                          │  │
│  │  - Performance Metrics (Text)                                 │  │
│  │  - Related Notion Items (Relation)                           │  │
│  │                                                               │  │
│  │  Real-time visibility: <30 seconds from hook to page creation│  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Sequence

### Happy Path: Webhook Success

```
1. User delegates work to agent (@cost-analyst)
   └─> Task tool invocation in Claude Code

2. Agent completes work (creates files, generates analysis)
   └─> Hook detects completion (duration >2min or files changed)

3. Hook executes dual-path sync
   ├─> STEP A: Write to queue (JSONL)
   │   └─> Entry includes webhookSynced=false initially
   │
   └─> STEP B: HTTP POST to Azure Function
       ├─> Build AgentActivityEvent JSON payload
       ├─> Generate HMAC-SHA256 signature with webhook secret
       ├─> POST to https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionWebhook
       └─> Timeout: 10 seconds

4. Azure Function processes request
   ├─> Retrieve secrets from Key Vault (cached)
   ├─> Verify signature (timing-safe comparison)
   ├─> Parse and validate payload
   ├─> Create Notion page via API
   └─> Return 200 OK with pageId and pageUrl

5. Hook receives response
   ├─> Update queue entry: webhookSynced=true
   └─> Log success: "Successfully synced via webhook + queued as backup"

6. Queue processor runs (every 5-15 min)
   ├─> Read queue entries
   ├─> Filter where webhookSynced=false (skip this entry)
   └─> No action needed - already synced
```

**Result**: Agent activity visible in Notion within <30 seconds, queue entry preserved as backup.

---

### Fallback Path: Webhook Failure

```
1-3. Same as Happy Path (user → agent → hook dual-path sync)

4. Azure Function request fails
   ├─> Possible causes:
   │   - Cold start timeout (>10 sec)
   │   - Azure outage
   │   - Network connectivity issue
   │   - Signature mismatch (401)
   │   - Notion API error (500)
   │
   └─> Hook catches exception

5. Hook handles failure
   ├─> Queue entry remains: webhookSynced=false
   ├─> Log warning: "Webhook failed - Queued for processor retry"
   └─> No data loss - entry safely queued

6. Queue processor runs (every 5-15 min)
   ├─> Read queue entries
   ├─> Filter where webhookSynced=false (include this entry)
   ├─> Process via Notion MCP API
   │   └─> Create page using notion-mcp-specialist
   │
   └─> Mark entry as synced, remove from queue

7. Manual verification (if needed)
   └─> Check .claude/logs/notion-queue-processor.log for sync confirmation
```

**Result**: Activity logged via queue processor within 5-15 minutes, zero data loss guaranteed.

---

## Security Architecture

### 1. Signature Verification (HMAC-SHA256)

**Purpose**: Prevent unauthorized webhook requests from external actors.

**Implementation**:
```typescript
// Hook generates signature
const hmac = crypto.createHmac('sha256', webhookSecret);
hmac.update(payloadJSON);
const signature = `v1=${hmac.digest('hex')}`;

// Azure Function verifies signature
const providedSignature = request.headers.get('notion-signature');
const isValid = timingSafeEqual(
  Buffer.from(providedSignature.split('=')[1], 'hex'),
  Buffer.from(expectedSignature, 'hex')
);

if (!isValid) {
  return { status: 401, message: 'Invalid signature' };
}
```

**Key Security Features**:
- Timing-safe comparison prevents timing attacks
- Secret rotates independently of code deployments
- Signature format: `v1=<hmac_hex>` allows future algorithm upgrades

---

### 2. Managed Identity + Key Vault

**Purpose**: Eliminate hardcoded credentials, enforce least-privilege access.

**Architecture**:
```
Azure Function (System-assigned Managed Identity)
    ↓ (AAD authentication)
Azure Key Vault (kv-brookside-secrets)
    ├─> notion-api-key (Get permission)
    └─> notion-webhook-secret (Get permission)
```

**Benefits**:
- No credentials in code, environment variables, or Git repository
- Automatic credential rotation without code changes
- Audit trail via Key Vault access logs
- Scoped permissions (Get/List secrets only, no Set/Delete)

---

### 3. HTTPS-Only Communication

All webhook traffic encrypted via TLS 1.2+:
- Hook → Azure Function: HTTPS with certificate validation
- Azure Function → Notion API: HTTPS (Notion enforces)
- Azure Function → Key Vault: HTTPS (Azure internal network)

**Certificate Management**: Handled automatically by Azure App Service (auto-renewal).

---

## Performance Characteristics

### Latency Breakdown (Happy Path)

| Stage | Duration | Notes |
|-------|----------|-------|
| Hook signature generation | 1-5ms | HMAC-SHA256 computation |
| HTTP POST to Azure | 50-200ms | Network latency (depends on region) |
| Azure Function cold start | 2-5 sec | First request after idle (rare) |
| Azure Function warm start | 100-500ms | Subsequent requests (common) |
| Key Vault secret retrieval | 50-100ms | First call, then cached |
| Signature verification | 1-2ms | Timing-safe comparison |
| Notion API page creation | 200-800ms | Notion API latency |
| **Total (cold start)** | **3-7 sec** | Worst case, rare |
| **Total (warm start)** | **400-1500ms** | Typical case |

**Service Level Objective (SLO)**: <30 seconds end-to-end (exceeds target 95% of time).

---

### Scalability

**Azure Function (Consumption Plan)**:
- Auto-scales: 0 → 200 instances based on load
- Per-instance throughput: ~100 concurrent requests
- Maximum throughput: 20,000 requests/minute (theoretical)
- Expected load: 200 agent activities/month (0.005 req/min avg)

**Headroom**: 4,000,000x capacity buffer for future growth.

---

### Cost Analysis

**Monthly Cost Estimate** (200 agent activities/month):

| Resource | Pricing | Usage | Cost |
|----------|---------|-------|------|
| Function Executions | First 1M free | 200 | $0.00 |
| Function GB-seconds | First 400k free | ~100 GB-s | $0.00 |
| Storage (queue + logs) | $0.02/GB | <1 GB | $0.02 |
| Application Insights | $2.30/GB | ~0.1 GB | $0.23 |
| Key Vault transactions | $0.03/10k | ~400 | $0.00 |
| **Total** | | | **$0.25/month** |

**Scale Scenario** (2,000 activities/month, 10x growth):

| Resource | Cost |
|----------|------|
| Function Executions | $0.40 (2k × $0.20/million) |
| Function GB-seconds | $0.80 (1,000 GB-s × $0.000016) |
| Storage | $0.02 |
| Application Insights | $0.46 (0.2 GB × $2.30) |
| **Total** | **$1.68/month** |

**Cost ceiling**: <$5/month even with 100x activity growth due to Consumption plan auto-scaling.

---

## Operational Monitoring

### Application Insights Queries

**Success Rate (Last 24 Hours)**:
```kusto
requests
| where timestamp > ago(24h)
| where name == "NotionWebhook"
| summarize
    Total = count(),
    Success = countif(success == true),
    Failed = countif(success == false),
    SuccessRate = 100.0 * countif(success == true) / count()
| project SuccessRate, Total, Success, Failed
```

**Average Latency by Outcome**:
```kusto
requests
| where timestamp > ago(24h)
| where name == "NotionWebhook"
| summarize
    AvgDuration_Success = avgif(duration, success == true),
    AvgDuration_Failed = avgif(duration, success == false),
    P95_Duration = percentile(duration, 95)
| project AvgDuration_Success, AvgDuration_Failed, P95_Duration
```

**Error Analysis**:
```kusto
exceptions
| where timestamp > ago(24h)
| where cloud_RoleName == "notion-webhook-brookside-prod"
| summarize Count = count() by problemId, outerMessage
| order by Count desc
```

**Cold Start Frequency**:
```kusto
requests
| where timestamp > ago(7d)
| where name == "NotionWebhook"
| extend IsColdStart = duration > 2000 // >2 seconds indicates cold start
| summarize
    TotalRequests = count(),
    ColdStarts = countif(IsColdStart),
    ColdStartRate = 100.0 * countif(IsColdStart) / count()
```

---

### Health Check Automation

Use `.claude/utils/webhook-utilities.ps1` for operational validation:

```powershell
# Daily health check (schedule via Task Scheduler or cron)
.\webhook-utilities.ps1 -Operation HealthCheck -WebhookSecret $(az keyvault secret show --vault-name kv-brookside-secrets --name notion-webhook-secret --query value -o tsv)
```

**Alerts** (recommended via Azure Monitor):
- Webhook success rate <90% (15-minute window)
- Average latency >3 seconds (sustained 30 minutes)
- Exception count >5 per hour
- Cold start rate >50% (indicates insufficient traffic to keep warm)

---

## Phase 2: Bidirectional Workflows (Planned)

**Current State**: Local → Azure Function → Notion (one-way sync)

**Phase 2 Enhancements**:

### 1. Notion Webhook Subscriptions

Register for Notion database events:
```json
{
  "url": "https://notion-webhook-brookside-prod.azurewebsites.net/api/NotionEvents",
  "event_types": ["page.created", "page.updated"],
  "filter": {
    "database_id": "72b879f213bd4edb9c59b43089dbef21"
  }
}
```

**Triggers**:
- Status changed to "Blocked" → Escalate to Teams channel
- Viability changed to "Needs Research" → Auto-start research agent
- Build completed → Archive to Knowledge Vault

---

### 2. Event-Driven Automation

```
Notion Change (Agent Activity Hub)
    ↓
Webhook Event → Azure Function
    ↓
Local Event Handler (.claude/utils/notion-event-handler.ps1)
    ↓
Conditional Actions:
    ├─> @research-coordinator (if idea.viability = "Needs Research")
    ├─> @archive-manager (if build.status = "Completed")
    ├─> Teams notification (if status = "Blocked")
    └─> Update related databases (cascade status changes)
```

**Benefits**:
- Autonomous workflow progression
- Reduce manual coordination overhead
- Enforce governance policies automatically

---

### 3. Two-Way Status Sync

Keep local agent state and Notion in sync:
- Local agent starts → Notion status = "In Progress" (current)
- Notion status updated → Local state updated (Phase 2)
- Conflict resolution via "last write wins" with timestamp comparison

---

## Deployment Checklist

### Pre-Deployment

- [ ] Azure subscription active with resource group created
- [ ] Azure CLI authenticated (`az login`)
- [ ] Notion integration created with Agent Activity Hub access
- [ ] Key Vault secrets configured:
  - [ ] `notion-api-key` (Notion integration token)
  - [ ] `notion-webhook-secret` (generate via webhook-utilities.ps1)

### Deployment

- [ ] Deploy Bicep infrastructure: `az deployment group create --template-file infrastructure/notion-webhook-function.bicep`
- [ ] Build TypeScript code: `cd azure-functions/notion-webhook && npm run build`
- [ ] Deploy function code: `func azure functionapp publish notion-webhook-brookside-prod`
- [ ] Verify Managed Identity access to Key Vault (check Bicep outputs)

### Post-Deployment Validation

- [ ] Test endpoint accessibility: `.\webhook-utilities.ps1 -Operation TestEndpoint`
- [ ] Send test payload: `.\webhook-utilities.ps1 -Operation SendTestPayload -WebhookSecret $(az keyvault secret show ...)`
- [ ] Verify page created in Agent Activity Hub
- [ ] Check Application Insights logs for successful execution
- [ ] Monitor queue processor logs for webhook-synced entry skip

### Operational Handoff

- [ ] Schedule daily health checks (Task Scheduler / cron)
- [ ] Configure Application Insights alerts (success rate, latency, errors)
- [ ] Document webhook secret rotation procedure
- [ ] Train team on `.claude/logs/` analysis for troubleshooting

---

## FAQ

**Q: What happens if Azure Function is down during agent activity?**
A: Activity is safely queued in `.claude/data/notion-sync-queue.jsonl` with `webhookSynced=false`. Queue processor retries within 5-15 minutes via Notion MCP API. Zero data loss.

**Q: Can I disable webhook and use queue-only?**
A: Yes. Set `WebhookEnabled = $false` in `.claude/hooks/auto-log-agent-activity.ps1` line 55. Queue processor handles all syncs.

**Q: How do I rotate the webhook secret?**
A: Generate new secret with `.\webhook-utilities.ps1 -Operation GenerateSecret`, update Key Vault, restart Azure Function (auto-picks up new secret on next cold start).

**Q: Why use Azure Function instead of local webhook listener?**
A: Azure Function provides professional infrastructure (auto-scaling, monitoring, high availability) without operational overhead. Local listener requires port forwarding, public IP, uptime management.

**Q: What's the difference between webhook-synced entries and regular queue entries?**
A: Webhook-synced entries have `webhookSynced=true` flag and are skipped by queue processor (already synced in real-time). Regular entries have `webhookSynced=false` and are processed via Notion MCP.

**Q: Can I use this architecture for other databases (Ideas, Research, Builds)?**
A: Yes, in Phase 2. Extend Azure Function with additional endpoints for each database, update hook to route based on database type.

---

## Related Documentation

- [Webhook README](../azure-functions/notion-webhook/README.md) - Deployment guide and local development
- [Webhook Troubleshooting Guide](webhook-troubleshooting.md) - Common issues and solutions
- [Queue Processor Documentation](../utils/process-notion-queue.ps1) - Fallback sync mechanism
- [Agent Activity Center](agent-activity-center.md) - 3-tier logging architecture overview

---

**Brookside BI Innovation Nexus** - Establishing scalable, resilient agent activity tracking at enterprise scale.
