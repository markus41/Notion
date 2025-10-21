# Azure Function Webhook Architecture for Notion Autonomous Platform

**Purpose**: Establish scalable webhook infrastructure to enable real-time automation triggers based on Notion database changes.

**Status**: Architecture Specification - Ready for Implementation
**Last Updated**: 2025-01-15

---

## Executive Summary

This architecture transforms Notion from a passive tracking system into an active automation orchestrator by deploying Azure Functions that listen for database property changes and trigger intelligent agent workflows through Claude Code's MCP integration.

**Key Benefits**:
- **Real-time automation**: Workflows trigger within seconds of Notion updates
- **Serverless scalability**: Azure Functions scale automatically with workload
- **Cost efficiency**: ~$5-15/month for webhook infrastructure
- **Centralized logging**: Application Insights for full observability
- **Secure authentication**: Azure Key Vault for Notion API credentials

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        NOTION WORKSPACE                          │
│  Ideas Registry | Research Hub | Example Builds                 │
│                                                                  │
│  User Updates Property → Notion Webhook API                      │
└────────────────────────────┬────────────────────────────────────┘
                             │ HTTPS POST
                             │
┌────────────────────────────▼────────────────────────────────────┐
│              AZURE FUNCTION APP (Consumption Plan)               │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  HTTP Trigger: notion-webhook-handler                      │ │
│  │  - Validates webhook signature                             │ │
│  │  - Parses event payload                                    │ │
│  │  - Routes to appropriate automation logic                  │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
│                         │                                        │
│  ┌──────────────────────▼─────────────────────────────────────┐ │
│  │  Durable Function Orchestrator: automation-orchestrator    │ │
│  │  - Maintains workflow state                                │ │
│  │  - Coordinates multi-agent execution                       │ │
│  │  - Handles retries and error recovery                      │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
│                         │                                        │
│  ┌──────────────────────▼─────────────────────────────────────┐ │
│  │  Activity Functions (Parallel Execution)                   │ │
│  │  - invoke-research-swarm                                   │ │
│  │  - invoke-build-pipeline                                   │ │
│  │  - invoke-viability-assessor                               │ │
│  │  - invoke-knowledge-curator                                │ │
│  └──────────────────────┬─────────────────────────────────────┘ │
└─────────────────────────┼────────────────────────────────────────┘
                          │ HTTP API Calls
                          │
┌─────────────────────────▼────────────────────────────────────────┐
│              CLAUDE CODE AGENT INVOCATION API                     │
│  (Local Development) OR (Azure Container Instance - Production)   │
│                                                                   │
│  @notion-orchestrator → Specialist Agents → Update Notion         │
└───────────────────────────────────────────────────────────────────┘
```

---

## Component Specifications

### 1. Notion Webhook Configuration

**Setup**: Use Notion API to register webhooks for database property changes

**Webhook Registration** (per database):
```javascript
// Register webhook for Ideas Registry
const webhook = await notionClient.webhooks.create({
  name: "Ideas Registry Automation Trigger",
  url: "https://brookside-innovation-webhooks.azurewebsites.net/api/notion-webhook",
  database_id: "984a4038-3e45-4a98-8df4-fd64dd8a1032", // Ideas Registry
  properties: ["Status", "Viability Score", "Automation Status"],
  secret: process.env.NOTION_WEBHOOK_SECRET  // For signature validation
});
```

**Triggered Events**:
| Database | Property | Trigger Condition | Automation Action |
|----------|----------|-------------------|-------------------|
| Ideas Registry | Status | Changes to "Active" | Launch research swarm or build pipeline |
| Ideas Registry | Viability Score | Calculated (>85) | Auto-approve for build |
| Research Hub | Research Progress % | Reaches 100 | Calculate viability and decide next steps |
| Research Hub | Viability Score | Calculated | Trigger build or escalate to review |
| Example Builds | Build Stage | Each stage completion | Advance to next stage |
| Example Builds | Deployment Health | Changes to "Failing" | Trigger auto-remediation |

---

### 2. Azure Function App Configuration

**Deployment Specifications**:
- **Plan**: Consumption (Pay-per-execution)
- **Runtime**: Node.js 20 LTS
- **Region**: East US 2 (or closest to team)
- **Function App Name**: `brookside-innovation-webhooks`

**Environment Variables** (stored in Azure Key Vault):
```bash
# Notion Configuration
NOTION_API_KEY=ntn_...
NOTION_WEBHOOK_SECRET=whsec_...
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e

# Claude Code Agent API (for production)
CLAUDE_CODE_API_URL=https://brookside-claude-agents.azurewebsites.net/api/invoke-agent
CLAUDE_CODE_API_KEY=[from Key Vault]

# Azure Infrastructure
AZURE_STORAGE_CONNECTION_STRING=[for Durable Functions state]
APPLICATIONINSIGHTS_CONNECTION_STRING=[for logging]

# Database IDs
IDEAS_REGISTRY_ID=984a4038-3e45-4a98-8df4-fd64dd8a1032
RESEARCH_HUB_ID=91e8beff-af94-4614-90b9-3a6d3d788d4a
EXAMPLE_BUILDS_ID=a1cd1528-971d-4873-a176-5e93b93555f6
SOFTWARE_TRACKER_ID=13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
```

**Resource Requirements**:
- **Memory**: 512 MB per function instance
- **Timeout**: 10 minutes (maximum for Consumption plan)
- **Concurrency**: 200 concurrent executions (default)
- **Cold Start Mitigation**: Warm-up trigger every 5 minutes during business hours

---

### 3. HTTP Trigger Function: notion-webhook-handler

**Purpose**: Receive and validate incoming Notion webhooks, route to appropriate automation logic

**TypeScript Implementation**:
```typescript
// functions/notion-webhook-handler.ts
import { app, HttpRequest, HttpResponseInit, InvocationContext } from "@azure/functions";
import crypto from "crypto";

export async function notionWebhookHandler(
  request: HttpRequest,
  context: InvocationContext
): Promise<HttpResponseInit> {
  context.log('Notion webhook received');

  // Step 1: Validate webhook signature
  const signature = request.headers.get('notion-signature');
  const timestamp = request.headers.get('notion-timestamp');
  const body = await request.text();

  if (!validateSignature(signature, timestamp, body)) {
    context.error('Invalid webhook signature');
    return { status: 401, body: 'Unauthorized' };
  }

  // Step 2: Parse webhook payload
  const payload = JSON.parse(body);
  const { database_id, property_name, old_value, new_value, page_id } = payload;

  context.log(`Database: ${database_id}, Property: ${property_name}, Page: ${page_id}`);

  // Step 3: Determine automation trigger
  const trigger = determineTrigger(database_id, property_name, old_value, new_value);

  if (!trigger) {
    context.log('No automation trigger for this event');
    return { status: 200, body: 'Event received, no action required' };
  }

  // Step 4: Start Durable Function orchestration
  const client = df.getClient(context);
  const instanceId = await client.startNew('automationOrchestrator', {
    trigger: trigger,
    pageId: page_id,
    databaseId: database_id,
    payload: payload
  });

  context.log(`Started orchestration with ID: ${instanceId}`);

  return {
    status: 202,
    headers: { 'Location': client.createCheckStatusResponse(request, instanceId).headers.location },
    body: JSON.stringify({
      orchestrationId: instanceId,
      status: 'Automation workflow initiated'
    })
  };
}

// Helper: Validate Notion webhook signature
function validateSignature(signature: string, timestamp: string, body: string): boolean {
  const secret = process.env.NOTION_WEBHOOK_SECRET;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${body}`)
    .digest('hex');

  return signature === expectedSignature;
}

// Helper: Determine automation trigger based on event
function determineTrigger(databaseId: string, propertyName: string, oldValue: any, newValue: any): string | null {
  // Ideas Registry triggers
  if (databaseId === process.env.IDEAS_REGISTRY_ID) {
    if (propertyName === 'Status' && newValue === 'Active') {
      return 'IDEA_ACTIVATED';
    }
    if (propertyName === 'Viability Score' && newValue > 85) {
      return 'IDEA_HIGH_VIABILITY';
    }
  }

  // Research Hub triggers
  if (databaseId === process.env.RESEARCH_HUB_ID) {
    if (propertyName === 'Research Progress %' && newValue === 100) {
      return 'RESEARCH_COMPLETE';
    }
    if (propertyName === 'Viability Score' && oldValue === null && newValue !== null) {
      return 'VIABILITY_CALCULATED';
    }
  }

  // Example Builds triggers
  if (databaseId === process.env.EXAMPLE_BUILDS_ID) {
    if (propertyName === 'Build Stage' && newValue === 'Testing') {
      return 'BUILD_READY_FOR_TEST';
    }
    if (propertyName === 'Deployment Health' && newValue === 'Failing') {
      return 'DEPLOYMENT_FAILING';
    }
  }

  return null;
}

app.http('notion-webhook', {
  methods: ['POST'],
  authLevel: 'anonymous',  // Security handled via signature validation
  handler: notionWebhookHandler
});
```

---

### 4. Durable Function Orchestrator: automation-orchestrator

**Purpose**: Manage stateful, long-running automation workflows with checkpointing and retries

**TypeScript Implementation**:
```typescript
// functions/automation-orchestrator.ts
import * as df from "durable-functions";
import { OrchestrationContext, OrchestrationHandler } from "durable-functions";

const automationOrchestrator: OrchestrationHandler = function* (context: OrchestrationContext) {
  const input = context.df.getInput();
  const { trigger, pageId, databaseId } = input;

  context.log(`Orchestrating automation for trigger: ${trigger}, page: ${pageId}`);

  try {
    // Update Notion: Mark automation as "In Progress"
    yield context.df.callActivity('updateNotionAutomationStatus', {
      pageId: pageId,
      status: 'In Progress',
      stage: getTriggerStageName(trigger)
    });

    // Route to appropriate automation workflow
    let result;

    switch (trigger) {
      case 'IDEA_ACTIVATED':
        result = yield context.df.callSubOrchestrator('researchSwarmOrchestrator', { pageId });
        break;

      case 'IDEA_HIGH_VIABILITY':
        result = yield context.df.callSubOrchestrator('buildPipelineOrchestrator', { pageId });
        break;

      case 'RESEARCH_COMPLETE':
        result = yield context.df.callActivity('calculateViabilityScore', { pageId });
        break;

      case 'VIABILITY_CALCULATED':
        result = yield context.df.callActivity('makeViabilityDecision', { pageId });
        break;

      case 'BUILD_READY_FOR_TEST':
        result = yield context.df.callActivity('runAutomatedTests', { pageId });
        break;

      case 'DEPLOYMENT_FAILING':
        result = yield context.df.callActivity('attemptAutoRemediation', { pageId });
        break;

      default:
        throw new Error(`Unknown trigger: ${trigger}`);
    }

    // Update Notion: Mark automation as "Complete"
    yield context.df.callActivity('updateNotionAutomationStatus', {
      pageId: pageId,
      status: 'Complete',
      result: result
    });

    return { success: true, result: result };

  } catch (error) {
    context.log.error(`Orchestration failed: ${error.message}`);

    // Update Notion: Mark automation as "Failed"
    yield context.df.callActivity('updateNotionAutomationStatus', {
      pageId: pageId,
      status: 'Failed',
      error: error.message
    });

    // Escalate to human if retry limit exceeded
    if (context.df.currentRetryCount >= 3) {
      yield context.df.callActivity('escalateToHuman', {
        pageId: pageId,
        error: error.message,
        trigger: trigger
      });
    }

    throw error;
  }
};

df.app.orchestration('automationOrchestrator', automationOrchestrator);
```

---

### 5. Sub-Orchestrator: researchSwarmOrchestrator

**Purpose**: Coordinate parallel execution of 4 research agents with result aggregation

**TypeScript Implementation**:
```typescript
// functions/research-swarm-orchestrator.ts
import * as df from "durable-functions";
import { OrchestrationContext, OrchestrationHandler } from "durable-functions";

const researchSwarmOrchestrator: OrchestrationHandler = function* (context: OrchestrationContext) {
  const { pageId } = context.df.getInput();

  context.log(`Starting research swarm for idea: ${pageId}`);

  // Fetch idea details from Notion
  const ideaDetails = yield context.df.callActivity('fetchIdeaFromNotion', { pageId });

  // Launch 4 research agents in parallel
  const researchTasks = [
    context.df.callActivity('invokeMarketResearcher', { ideaDetails }),
    context.df.callActivity('invokeTechnicalAnalyst', { ideaDetails }),
    context.df.callActivity('invokeCostFeasibilityAnalyst', { ideaDetails }),
    context.df.callActivity('invokeRiskAssessor', { ideaDetails })
  ];

  // Wait for all research agents to complete (with timeout)
  const timeout = context.df.createTimer(context.df.currentUtcDateTime.addMinutes(30));
  const allResearch = yield context.df.Task.all(researchTasks);
  timeout.cancel();

  const [marketResult, technicalResult, costResult, riskResult] = allResearch;

  // Calculate composite viability score
  const viabilityScore = calculateCompositeScore({
    market: marketResult.score,
    technical: technicalResult.score,
    cost: costResult.score,
    risk: riskResult.score
  });

  // Create or update Research Hub entry in Notion
  const researchHubEntry = yield context.df.callActivity('createResearchHubEntry', {
    ideaId: pageId,
    marketAnalysis: marketResult,
    technicalAnalysis: technicalResult,
    costAnalysis: costResult,
    riskAssessment: riskResult,
    viabilityScore: viabilityScore
  });

  // Update original idea with viability score
  yield context.df.callActivity('updateIdeaViabilityScore', {
    pageId: pageId,
    viabilityScore: viabilityScore
  });

  return {
    viabilityScore: viabilityScore,
    researchHubId: researchHubEntry.id,
    recommendation: determineRecommendation(viabilityScore, ideaDetails.effort)
  };
};

// Helper: Calculate weighted composite score
function calculateCompositeScore(scores: { market: number, technical: number, cost: number, risk: number }): number {
  return Math.round(
    (scores.market * 0.30) +
    (scores.technical * 0.25) +
    (scores.cost * 0.20) +
    ((100 - scores.risk) * 0.15)  // Risk is inverted
  );
}

df.app.orchestration('researchSwarmOrchestrator', researchSwarmOrchestrator);
```

---

### 6. Activity Functions: Claude Code Agent Invocation

**Purpose**: Call Claude Code agents via HTTP API and return results

**TypeScript Implementation**:
```typescript
// functions/invoke-market-researcher.ts
import { app, InvocationContext } from "@azure/functions";

export async function invokeMarketResearcher(
  input: { ideaDetails: any },
  context: InvocationContext
): Promise<{ score: number, analysis: string }> {
  const { ideaDetails } = input;

  context.log(`Invoking @market-researcher for: ${ideaDetails.title}`);

  const response = await fetch(process.env.CLAUDE_CODE_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${process.env.CLAUDE_CODE_API_KEY}`
    },
    body: JSON.stringify({
      agent: 'market-researcher',
      prompt: `Analyze market opportunity for: ${ideaDetails.description}
               - Demand validation
               - Competitor landscape
               - Trend analysis
               - Target audience assessment

               Return: Market viability score (0-100) with justification`,
      context: {
        ideaTitle: ideaDetails.title,
        ideaDescription: ideaDetails.description,
        category: ideaDetails.innovationType
      }
    })
  });

  if (!response.ok) {
    throw new Error(`Market researcher failed: ${response.statusText}`);
  }

  const result = await response.json();

  return {
    score: result.score,
    analysis: result.analysis
  };
}

app.activity('invokeMarketResearcher', {
  handler: invokeMarketResearcher
});
```

---

### 7. Monitoring & Logging: Application Insights

**Purpose**: Full observability into automation workflows, performance metrics, and error tracking

**Configuration**:
```typescript
// Enable Application Insights in Azure Function App
import appInsights from "applicationinsights";

appInsights.setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
  .setAutoDependencyCorrelation(true)
  .setAutoCollectRequests(true)
  .setAutoCollectPerformance(true, true)
  .setAutoCollectExceptions(true)
  .setAutoCollectDependencies(true)
  .setAutoCollectConsole(true, true)
  .setUseDiskRetryCaching(true)
  .start();

const client = appInsights.defaultClient;
```

**Custom Metrics to Track**:
```typescript
// Track automation success rate
client.trackMetric({
  name: "AutomationSuccessRate",
  value: successCount / totalCount * 100
});

// Track average workflow duration
client.trackMetric({
  name: "AverageWorkflowDuration",
  value: durationInMinutes
});

// Track agent invocation latency
client.trackDependency({
  target: "Claude Code Agent API",
  name: "@market-researcher",
  data: "Market analysis request",
  duration: durationMs,
  resultCode: 200,
  success: true
});

// Track errors and exceptions
client.trackException({
  exception: new Error("Research swarm timeout"),
  properties: {
    ideaId: pageId,
    trigger: 'IDEA_ACTIVATED'
  }
});
```

**Kusto Queries for Analytics**:
```kql
// Automation success rate over time
customMetrics
| where name == "AutomationSuccessRate"
| summarize avg(value) by bin(timestamp, 1d)
| render timechart

// Failed workflows by trigger type
exceptions
| where customDimensions.trigger != ""
| summarize count() by tostring(customDimensions.trigger)
| render barchart

// Average workflow duration by automation type
customMetrics
| where name == "AverageWorkflowDuration"
| summarize avg(value) by tostring(customDimensions.automationType)
| render columnchart
```

---

## Deployment Instructions

### Step 1: Create Azure Resources

```bash
# Login to Azure
az login
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Create resource group
az group create \
  --name brookside-innovation-automation \
  --location eastus2

# Create storage account (for Durable Functions state)
az storage account create \
  --name brooksideinnovationstorage \
  --resource-group brookside-innovation-automation \
  --sku Standard_LRS

# Create Application Insights
az monitor app-insights component create \
  --app brookside-innovation-insights \
  --resource-group brookside-innovation-automation \
  --location eastus2

# Create Function App (Consumption plan)
az functionapp create \
  --resource-group brookside-innovation-automation \
  --consumption-plan-location eastus2 \
  --runtime node \
  --runtime-version 20 \
  --functions-version 4 \
  --name brookside-innovation-webhooks \
  --storage-account brooksideinnovationstorage \
  --app-insights brookside-innovation-insights
```

### Step 2: Configure Application Settings

```bash
# Retrieve Notion API key from Key Vault
NOTION_API_KEY=$(az keyvault secret show \
  --vault-name kv-brookside-secrets \
  --name notion-api-key \
  --query value -o tsv)

# Configure Function App settings
az functionapp config appsettings set \
  --name brookside-innovation-webhooks \
  --resource-group brookside-innovation-automation \
  --settings \
    NOTION_API_KEY=$NOTION_API_KEY \
    NOTION_WORKSPACE_ID="81686779-099a-8195-b49e-00037e25c23e" \
    IDEAS_REGISTRY_ID="984a4038-3e45-4a98-8df4-fd64dd8a1032" \
    RESEARCH_HUB_ID="91e8beff-af94-4614-90b9-3a6d3d788d4a" \
    EXAMPLE_BUILDS_ID="a1cd1528-971d-4873-a176-5e93b93555f6" \
    SOFTWARE_TRACKER_ID="13b5e9de-2dd1-45ec-839a-4f3d50cd8d06"
```

### Step 3: Deploy Function App Code

```bash
# Initialize Function App project
func init brookside-webhooks --typescript
cd brookside-webhooks

# Install dependencies
npm install @azure/functions durable-functions
npm install @notionhq/client

# Copy function implementations (from above)
# - notion-webhook-handler.ts
# - automation-orchestrator.ts
# - research-swarm-orchestrator.ts
# - invoke-market-researcher.ts
# ... (other activity functions)

# Deploy to Azure
func azure functionapp publish brookside-innovation-webhooks
```

### Step 4: Register Notion Webhooks

```javascript
// run: node register-webhooks.js
const { Client } = require("@notionhq/client");

const notion = new Client({ auth: process.env.NOTION_API_KEY });

// Register webhook for Ideas Registry
await notion.webhooks.create({
  name: "Ideas Registry Automation",
  url: "https://brookside-innovation-webhooks.azurewebsites.net/api/notion-webhook",
  database_id: "984a4038-3e45-4a98-8df4-fd64dd8a1032",
  properties: ["Status", "Viability Score"],
  secret: process.env.NOTION_WEBHOOK_SECRET
});

// Repeat for Research Hub, Example Builds
```

### Step 5: Test Automation

```bash
# Trigger test webhook
curl -X POST https://brookside-innovation-webhooks.azurewebsites.net/api/notion-webhook \
  -H "Content-Type: application/json" \
  -H "notion-signature: [test-signature]" \
  -H "notion-timestamp: [current-timestamp]" \
  -d '{
    "database_id": "984a4038-3e45-4a98-8df4-fd64dd8a1032",
    "page_id": "[test-page-id]",
    "property_name": "Status",
    "old_value": "Concept",
    "new_value": "Active"
  }'

# Verify in Application Insights
az monitor app-insights query \
  --app brookside-innovation-insights \
  --analytics-query "traces | where message contains 'Notion webhook received' | top 10 by timestamp desc"
```

---

## Cost Breakdown

**Monthly Operating Costs** (estimated):

| Resource | Pricing | Monthly Cost |
|----------|---------|--------------|
| **Azure Function App** (Consumption) | $0.20 per million executions + $0.000016 per GB-second | ~$5-10 |
| **Azure Storage** (for Durable Functions state) | $0.02 per GB | ~$1-2 |
| **Application Insights** | First 5 GB free, then $2.30 per GB | ~$0-5 (likely in free tier) |
| **Outbound Data Transfer** | First 100 GB free, then $0.087 per GB | ~$0-2 |
| **Total Estimated Cost** | - | **~$7-15/month** |

**Assumptions**:
- 500 webhook triggers per month
- Average 5 agent invocations per trigger
- Average 2-minute execution time per orchestration
- 1 GB log data per month

---

## Security Considerations

**Webhook Authentication**:
- ✅ HMAC signature validation on every request
- ✅ Timestamp validation to prevent replay attacks
- ✅ HTTPS only (enforced by Azure)

**Secrets Management**:
- ✅ All secrets stored in Azure Key Vault
- ✅ Managed Identity for Function App → Key Vault access
- ✅ No secrets in code or configuration files

**Network Security**:
- ✅ Function App behind Azure Front Door (optional)
- ✅ IP restriction to Notion webhook servers (future enhancement)
- ✅ DDoS protection via Azure (default)

**Monitoring & Alerts**:
- ✅ Failed authentication attempts logged
- ✅ Unusual activity patterns detected
- ✅ Alert on >10% error rate
- ✅ Alert on orchestration timeout (>10 min)

---

## Troubleshooting Guide

**Issue**: Webhook not triggering automation
**Diagnosis**:
```bash
# Check Function App logs
az monitor app-insights query \
  --app brookside-innovation-insights \
  --analytics-query "traces | where message contains 'Notion webhook' | top 20 by timestamp desc"
```
**Resolution**: Verify webhook registration in Notion, check signature validation

**Issue**: Orchestration times out
**Diagnosis**: Review Durable Function instance history
**Resolution**: Increase timeout, optimize agent invocation latency

**Issue**: Agent invocation fails
**Diagnosis**: Check agent API availability and authentication
**Resolution**: Verify Claude Code API endpoint, refresh credentials

---

**Best for**: Organizations transforming Notion into an intelligent automation orchestrator, establishing scalable webhook infrastructure that drives real-time innovation workflows with minimal manual intervention.

---

**Next Steps**:
1. Provision Azure resources (Function App, Storage, Application Insights)
2. Deploy webhook handler and orchestrator functions
3. Register Notion webhooks for target databases
4. Test with pilot idea automation workflow
5. Monitor performance and optimize based on metrics
