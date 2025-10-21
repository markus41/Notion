# Autonomous Innovation Platform - Technical Specification

**Purpose**: AI-agent-executable technical documentation with zero-ambiguity setup and deployment instructions

**Designed for**: Autonomous deployment by AI agents or human operators without additional context requirements

**Best for**: Organizations requiring rapid deployment, disaster recovery, or knowledge transfer of autonomous innovation infrastructure

---

## Executive Summary

**Purpose**: Transform Notion ideas into production-ready applications autonomously with < 10% human intervention

**Origin**: Brookside BI Innovation Nexus - Notion-First Workflow Automation Initiative

**Status**: Phase 2 Complete (Agent Integration) ✅ | Phase 3 In Progress (Pattern Learning)

**Reusability**: 🔄 Highly Reusable - Pattern-based architecture with modular components adaptable to any Notion-driven automation workflow

**Last Updated**: 2025-01-15

**Lead Builder**: Markus Ahling

---

## System Architecture

### High-Level Overview

The Autonomous Innovation Platform establishes intelligent workflow automation that transforms Notion database changes into fully deployed Azure applications through AI-driven orchestration.

**Value Proposition**: Reduce idea-to-production time from weeks to hours while maintaining systematic knowledge capture and cost transparency.

```
┌──────────────────────────────────────────────────────────────────────┐
│                     Notion Workspace (Source of Truth)               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │ Ideas Registry│→ │ Research Hub │→ │Example Builds│              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ Webhook Events
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│              Azure Function App (Webhook Receiver)                   │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │ Trigger Matrix Evaluation                                    │   │
│  │ • Idea Status = Active + Viability ≥ Medium + Effort ≤ S    │   │
│  │ • Research Status = Active + Next Steps = Build Example      │   │
│  │ • Build Status = Active + Deployment Required                │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ Route to Orchestrator
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│                  Durable Orchestrators                               │
│  ┌──────────────────┐  ┌──────────────────┐                         │
│  │ Research Swarm   │  │ Build Pipeline   │                         │
│  │ (4 AI Agents)    │  │ (6 Stages)       │                         │
│  └──────────────────┘  └──────────────────┘                         │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ Invoke Activity Functions
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│                    Activity Functions (12 Total)                     │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐          │
│  │ AI Agent       │ │ GitHub Ops     │ │ Azure Deploy   │          │
│  │ Invocation     │ │ (Repo Creation)│ │ (Bicep IaC)    │          │
│  └────────────────┘ └────────────────┘ └────────────────┘          │
│  ┌────────────────┐ ┌────────────────┐ ┌────────────────┐          │
│  │ Notion Updates │ │ Research Entry │ │ Escalation     │          │
│  │ (Status Sync)  │ │ Creation       │ │ (Multi-Channel)│          │
│  └────────────────┘ └────────────────┘ └────────────────┘          │
└──────────────────────────┬───────────────────────────────────────────┘
                           │ Pattern Learning
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│              Cosmos DB (Pattern Library + Build History)             │
│  • Atomic Patterns: azure-ad-auth, cosmos-db-storage, rest-api      │
│  • Composite Patterns: authenticated-rest-api, serverless-pipeline  │
│  • Success Rates: (successCount / usageCount) × 100                 │
│  • Similarity Matching: Cosine similarity for recommendations       │
└──────────────────────────────────────────────────────────────────────┘
```

### Data Flow

**Scenario 1: Autonomous Build Trigger**

1. **User Action**: Update Idea Status → "Active", Viability → "High", Effort → "S"
2. **Notion Webhook**: POST to Azure Function webhook endpoint within 1 second
3. **Trigger Evaluation**: Webhook receiver evaluates trigger matrix → "Launch Build Pipeline"
4. **Orchestrator Start**: BuildPipelineOrchestrator begins 6-stage workflow
5. **Stage 1 - Architecture**: AI agent designs system using pattern library
6. **Stage 2 - Code Generation**: Multi-language codebase created (Node.js/Python/.NET)
7. **Stage 3 - GitHub**: Repository created, code pushed, branch protection enabled
8. **Stage 4 - Azure Deploy**: Bicep template generated, resources provisioned
9. **Stage 5 - Validation**: Health checks executed, performance baseline measured
10. **Stage 6 - Knowledge**: Pattern extraction, Knowledge Vault entry created
11. **Completion**: Notion build entry updated with production URL and metrics

**Scenario 2: Research Automation**

1. **User Action**: Update Idea Status → "Active", Viability → "Needs Research"
2. **Notion Webhook**: POST to webhook endpoint
3. **Trigger Evaluation**: → "Launch Research Swarm"
4. **Parallel Execution**: 4 AI agents execute simultaneously (Market, Technical, Cost, Risk)
5. **Viability Calculation**: Weighted composite score = (M×0.30 + T×0.25 + C×0.25 + R×0.20)
6. **Decision Routing**:
   - Score ≥ 85 AND Cost < $500 → Auto-trigger Build Pipeline
   - Score 60-84 OR Cost $500-1000 → Escalate to Human (Notion + Email + Teams)
   - Score < 60 → Archive with learnings preservation
7. **Completion**: Research Hub entry updated with findings and recommendations

### Integration Points

**Notion API**:
- Purpose: Source of truth for innovation tracking, real-time status updates
- Connection Method: REST API with integration token (Key Vault)
- Operations: Database queries, property updates, page creation, comment posting
- Rate Limiting: 3 requests/second (built-in retry with exponential backoff)

**GitHub API**:
- Purpose: Version control, repository management, CI/CD automation
- Connection Method: REST API via @octokit/rest with PAT authentication
- Operations: Repository creation, file uploads, branch protection, PR management
- Authentication: Personal Access Token from Key Vault (`github-personal-access-token`)

**Azure Resource Manager**:
- Purpose: Infrastructure provisioning, resource management, deployment orchestration
- Connection Method: Azure SDK for JavaScript + Managed Identity
- Operations: Bicep deployment, resource tagging, health monitoring
- Authentication: System-assigned Managed Identity with Contributor role

**Azure OpenAI / Anthropic Claude**:
- Purpose: AI agent execution for architecture, research, code generation
- Connection Method: REST API with API key
- Operations: Chat completions, structured output parsing, multi-turn conversations
- Cost Management: Usage tracking in Application Insights, threshold enforcement

---

## Technology Stack

**CRITICAL**: All versions must be EXPLICIT and EXACT.

### Runtime Environment

**Language**: Node.js 18.19.0 LTS
- Rationale: Latest LTS with stable Durable Functions support
- Verification: `node --version` → Expected: v18.19.0 or higher

**Framework**: Azure Durable Functions 3.0.0
- Rationale: Production-grade orchestration with built-in retry and state management
- Package: `durable-functions@3.0.0`

**Package Manager**: npm 10.2.4
- Verification: `npm --version` → Expected: 10.2.4 or higher

### Database

**Service**: Azure Cosmos DB (Serverless)
- Purpose: Pattern library storage with low-latency queries
- SKU: Serverless (auto-scaling, pay-per-request)
- Region: East US (co-located with Function App)
- Partition Key: `/patternType` (even distribution across atomic/composite patterns)
- Throughput: Auto-scale 0-1000 RU/s
- Backup: Continuous (7-day retention)

**Containers**:
1. `patterns` - Atomic and composite architectural patterns
2. `build-history` - Historical build metadata for analytics
3. `research-results` - Research findings for pattern refinement

**Service**: Azure Table Storage (Standard LRS)
- Purpose: Durable Functions state, workflow logs, pattern cache
- SKU: Standard Locally Redundant Storage
- Tables: `OrchestrationState`, `WorkflowLogs`, `PatternCache`

### Hosting Infrastructure

**Primary**: Azure Function App (Consumption Plan Y1)
- Purpose: Serverless event-driven execution for webhooks and orchestrators
- SKU: Consumption (Y1) - Pay-per-execution model
- Region: East US
- Runtime Stack: Node.js 18 LTS
- Operating System: Linux
- Always On: Not available (Consumption Plan limitation)
- Managed Identity: System-assigned (enabled)
- Application Settings: 15+ environment variables (all from Key Vault)

**Monitoring**: Azure Application Insights (Basic tier)
- Purpose: Telemetry, custom metrics, distributed tracing
- SKU: Basic (pay-as-you-go)
- Sampling: 100% (development), 10% (production)
- Retention: 90 days

**Logging**: Azure Log Analytics Workspace
- Purpose: Centralized log aggregation, KQL queries
- SKU: Pay-as-you-go
- Data Retention: 30 days (default)
- Ingestion: ~5 GB/month estimated

**Secrets**: Azure Key Vault (Standard)
- Purpose: Centralized secret management for all credentials
- SKU: Standard (no premium HSM required)
- Access Policy: Managed Identity from Function App
- Secrets Stored: 7 (Notion API, GitHub PAT, Azure OpenAI, Cosmos, Logic App, Teams)

### APIs & Dependencies

**Notion API**:
- Version: v1 (2022-06-28 API version)
- Purpose: Database operations, webhook event handling
- Authentication: Integration token
- Rate Limit: 3 requests/second

**GitHub REST API**:
- Package: `@octokit/rest@20.0.2`
- Purpose: Repository creation, file uploads, branch management
- Authentication: Personal Access Token (repo + workflow scopes)
- Rate Limit: 5000 requests/hour (authenticated)

**Azure Cosmos DB Client**:
- Package: `@azure/cosmos@4.0.0`
- Purpose: Pattern library queries, build history storage
- Authentication: Connection string from Key Vault

**Azure Table Storage Client**:
- Package: `@azure/data-tables@13.2.2`
- Purpose: Durable Functions state persistence
- Authentication: Connection string from Storage Account

**Azure Functions Runtime**:
- Package: `@azure/functions@4.0.0`
- Purpose: HTTP triggers, timer triggers, bindings

**Durable Functions Framework**:
- Package: `durable-functions@3.0.0`
- Purpose: Orchestration, activity function execution, state management

**HTTP Client**:
- Package: `axios@1.6.5`
- Purpose: REST API calls to external services (Notion, GitHub, etc.)

**Date Utilities**:
- Package: `date-fns@3.0.6`
- Purpose: Timestamp formatting, duration calculations

### Development Tools

**Azure Functions Core Tools**: 4.0.5455 or higher
- Purpose: Local development, debugging, deployment
- Installation: `npm install -g azure-functions-core-tools@4`
- Verification: `func --version` → Expected: 4.0.5455+

**Azure CLI**: 2.55.0 or higher
- Purpose: Infrastructure deployment, resource management
- Installation: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- Verification: `az --version | grep "azure-cli"` → Expected: 2.55.0+

**PowerShell**: 7.4.0 or higher
- Purpose: Deployment automation scripts
- Installation: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell
- Verification: `pwsh --version` → Expected: 7.4.0+

**Git**: 2.43.0 or higher
- Purpose: Version control
- Verification: `git --version` → Expected: 2.43.0+

**Visual Studio Code**: 1.85.0 or higher (recommended)
- Extensions: Azure Functions, Azure Account, PowerShell

---

## Cost Summary (from Software Tracker Rollup)

**Infrastructure Monthly Costs** (~$103-163/month):

| Service | Monthly Cost | Category | Criticality |
|---------|--------------|----------|-------------|
| Azure Function App (Consumption) | $10 | Infrastructure | Critical |
| Azure Cosmos DB (Serverless) | $25 | Infrastructure | Critical |
| Azure Storage Account (Tables + Blobs) | $5 | Storage | Critical |
| Azure Application Insights | $12 | Analytics | Important |
| Azure Log Analytics | $8 | Analytics | Important |
| Azure Key Vault | $3 | Security | Critical |
| Azure OpenAI / Anthropic Claude | $20-50 | AI/ML | Critical |
| Notion API | $0 | Productivity | Critical |
| GitHub Enterprise | $0 | Development | Critical |
| **Total** | **$83-113 + AI** | | |

**Per Autonomous Build** (~$15-50/month):
- Azure App Service B1: $13
- Application Insights: $2-5
- Optional: Cosmos DB $10-20, SQL Database $5-15, Storage $1-2

**Projected Total for 5 Active Builds**: $125-350/month

**ROI Calculation**:
- Time saved per autonomous build: 40 hours (manual development)
- Value at $150/hour: $6,000 per build
- Monthly value for 5 builds: $30,000
- Infrastructure cost: $350/month
- **Net Monthly Benefit**: $29,650
- **ROI**: 8,471%

---

## API Specification

### Base URL

```
Development: https://func-brookside-innovation-dev.azurewebsites.net
Staging: https://func-brookside-innovation-staging.azurewebsites.net
Production: https://func-brookside-innovation-prod.azurewebsites.net
```

### Authentication

**Method**: Function Key (for webhook endpoints) + Managed Identity (for Azure resources)

**Headers Required for Webhook**:
```http
POST /api/NotionWebhookReceiver
Content-Type: application/json
X-Notion-Signature: <webhook-signature>
```

**Internal Authentication**:
- Function-to-Function: No authentication (same Function App)
- Function-to-Azure: Managed Identity with DefaultAzureCredential
- Function-to-External: API keys from Key Vault

### Endpoints

#### POST /api/NotionWebhookReceiver

**Purpose**: Receive Notion database change events and route to appropriate orchestrators

**Request**:
```http
POST /api/NotionWebhookReceiver
Content-Type: application/json
X-Notion-Signature: sha256=<signature>

{
  "object": "database",
  "id": "984a4038-3e45-4a98-8df4-fd64dd8a1032",
  "properties": {
    "Status": {
      "select": { "name": "Active" }
    },
    "Viability": {
      "select": { "name": "High" }
    },
    "Effort": {
      "select": { "name": "S" }
    }
  }
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "message": "Webhook processed successfully",
  "orchestrationId": "01234567-89ab-cdef-0123-456789abcdef",
  "orchestrationType": "BuildPipelineOrchestrator",
  "triggeredBy": "IdeaActivation"
}
```

**Error Responses**:
- `400 Bad Request`: Invalid webhook payload structure
- `401 Unauthorized`: Webhook signature verification failed
- `429 Too Many Requests`: Rate limit exceeded (>10 webhooks/minute)
- `500 Internal Server Error`: Orchestrator start failure

#### GET /api/BuildPipelineOrchestrator/{instanceId}

**Purpose**: Query orchestration status and execution history

**Request**:
```http
GET /api/BuildPipelineOrchestrator/01234567-89ab-cdef-0123-456789abcdef
```

**Response** (200 OK):
```json
{
  "instanceId": "01234567-89ab-cdef-0123-456789abcdef",
  "runtimeStatus": "Running",
  "input": {
    "ideaPageId": "984a4038-3e45-...",
    "ideaTitle": "AI-Powered Analytics Dashboard"
  },
  "output": null,
  "createdTime": "2025-01-15T10:00:00Z",
  "lastUpdatedTime": "2025-01-15T10:15:00Z",
  "customStatus": {
    "currentStage": "Code Generation",
    "progress": 33,
    "estimatedCompletion": "2025-01-15T11:30:00Z"
  },
  "history": [
    {
      "timestamp": "2025-01-15T10:00:00Z",
      "eventType": "OrchestratorStarted"
    },
    {
      "timestamp": "2025-01-15T10:05:00Z",
      "eventType": "ActivityCompleted",
      "functionName": "ArchitectureGeneration",
      "result": {
        "patterns": ["azure-app-service", "cosmos-db-storage"],
        "estimatedCost": 350
      }
    }
  ]
}
```

**Runtime Status Values**:
- `Running`: Orchestration in progress
- `Completed`: All stages successful
- `Failed`: Unrecoverable error occurred
- `Terminated`: Manual termination by operator

---

## Data Models

### Pattern Model (Cosmos DB)

```typescript
interface Pattern {
  id: string;                    // UUID v4, auto-generated
  patternType: "atomic" | "composite";  // Partition key
  name: string;                  // e.g., "azure-ad-authentication"
  description: string;           // Human-readable explanation
  category: string;              // "Authentication" | "Storage" | "API" | "Compute"
  tags: string[];                // ["azure", "security", "oauth"]
  usageCount: number;            // Incremented on each application
  successCount: number;          // Incremented on successful deployment
  successRate: number;           // (successCount / usageCount) × 100
  avgCost: number;              // Average monthly cost (USD)
  avgBuildTime: number;         // Average build duration (minutes)
  architecture: {
    azureServices: string[];    // ["App Service", "Key Vault"]
    codeStructure: string;      // Directory layout description
    dependencies: string[];     // npm/pip packages
  };
  lastUsed: string;             // ISO 8601 timestamp
  recentImplementations: string[]; // Last 10 build IDs
  _ts: number;                  // Cosmos DB timestamp
}
```

### Build History Model (Cosmos DB)

```typescript
interface BuildHistory {
  id: string;                   // UUID v4, matches Notion build ID
  buildId: string;              // Partition key (same as id)
  ideaId: string;               // Originating idea ID
  title: string;                // Build name
  status: "succeeded" | "failed" | "in_progress";
  patternsApplied: string[];    // Pattern IDs used
  totalCost: number;            // Monthly operational cost
  buildDuration: number;        // Minutes from start to completion
  azureResources: {
    resourceGroup: string;
    resources: Array<{
      type: string;             // "App Service", "Cosmos DB", etc.
      name: string;
      cost: number;
    }>;
  };
  healthChecks: {
    passed: number;
    failed: number;
    skipped: number;
  };
  createdAt: string;            // ISO 8601 timestamp
  completedAt: string | null;   // ISO 8601 timestamp or null
  _ts: number;
}
```

### Orchestration Input Model

```typescript
interface BuildPipelineInput {
  ideaPageId: string;           // Notion page ID (UUID format)
  ideaData: {
    title: string;
    description: string;
    category: string;           // "Internal Tool" | "Customer Feature" | etc.
    effort: string;             // "XS" | "S" | "M" | "L" | "XL"
    viability: string;          // "High" | "Medium" | "Low"
  };
  costThreshold?: number;       // Default: 500 (USD/month)
  autoApprove?: boolean;        // Default: false (requires escalation)
}
```

### Research Result Model

```typescript
interface ResearchResult {
  agent: "market" | "technical" | "cost" | "risk";
  score: number;                // 0-100
  summary: string;              // 2-3 sentence executive summary
  details: string;              // Full analysis
  recommendations: string[];    // Actionable next steps
  estimatedCost?: number;       // Monthly operational cost (cost agent only)
  estimatedEffort?: string;     // "XS" | "S" | "M" | "L" | "XL"
  confidence: "low" | "medium" | "high";
}
```

---

## Configuration

### Environment Variables

**CRITICAL**: All secrets must reference Azure Key Vault or secure storage. NEVER hardcode.

**Required Variables**:
```bash
# Azure Configuration
AZURE_TENANT_ID=2930489e-9d8a-456b-9de9-e4787faeab9c
AZURE_SUBSCRIPTION_ID=cfacbbe8-a2a3-445f-a188-68b3b35f0c84
AZURE_REGION=eastus

# Function App Configuration
FUNCTIONS_WORKER_RUNTIME=node
WEBSITE_NODE_DEFAULT_VERSION=18
WEBSITE_RUN_FROM_PACKAGE=1

# Notion Integration
NOTION_API_KEY=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/NOTION-API-KEY/)
NOTION_WORKSPACE_ID=81686779-099a-8195-b49e-00037e25c23e
NOTION_DATABASE_ID_IDEAS=984a4038-3e45-4a98-8df4-fd64dd8a1032
NOTION_DATABASE_ID_RESEARCH=91e8beff-af94-4614-90b9-3a6d3d788d4a
NOTION_DATABASE_ID_BUILDS=a1cd1528-971d-4873-a176-5e93b93555f6
NOTION_DATABASE_ID_SOFTWARE=13b5e9de-2dd1-45ec-839a-4f3d50cd8d06
NOTION_DATABASE_ID_KNOWLEDGE=<TO_BE_CONFIGURED>

# GitHub Integration
GITHUB_PERSONAL_ACCESS_TOKEN=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/GITHUB-PERSONAL-ACCESS-TOKEN/)
GITHUB_ORG=brookside-bi

# AI Integration (choose one or both)
AZURE_OPENAI_API_KEY=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/AZURE-OPENAI-API-KEY/)
AZURE_OPENAI_ENDPOINT=https://<resource-name>.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

# OR Anthropic Direct
ANTHROPIC_API_KEY=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/ANTHROPIC-API-KEY/)
ANTHROPIC_MODEL=claude-3-sonnet-20240229

# Cosmos DB
COSMOS_ENDPOINT=https://cosmos-brookside-innovation-dev.documents.azure.com:443/
COSMOS_KEY=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/COSMOS-KEY/)
COSMOS_DATABASE_NAME=innovation-platform
COSMOS_CONTAINER_PATTERNS=patterns
COSMOS_CONTAINER_BUILDS=build-history

# Storage Account
AZURE_STORAGE_CONNECTION_STRING=<Auto-configured by Function App>
PATTERN_CACHE_TABLE_NAME=PatternCache
WORKFLOW_LOGS_TABLE_NAME=WorkflowLogs

# Application Insights
APPINSIGHTS_INSTRUMENTATIONKEY=<Auto-configured>
APPLICATIONINSIGHTS_CONNECTION_STRING=<Auto-configured>

# Escalation Configuration (Optional)
LOGIC_APP_EMAIL_WEBHOOK_URL=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/LOGIC-APP-EMAIL-WEBHOOK-URL/)
TEAMS_WEBHOOK_URL=@Microsoft.KeyVault(SecretUri=https://kv-brookside-inn-dev.vault.azure.net/secrets/TEAMS-WEBHOOK-URL/)
ESCALATION_EMAIL_FROM=no-reply@brooksidebi.com
ESCALATION_EMAIL_SUBJECT_PREFIX=[Autonomous Platform]
```

**Optional Variables**:
```bash
# Cost Thresholds
AUTO_APPROVE_COST_THRESHOLD=500          # USD/month, default: 500
ESCALATION_COST_THRESHOLD=1000           # USD/month, default: 1000

# Timeout Configuration
AGENT_INVOCATION_TIMEOUT_MS=900000       # 15 minutes, default: 900000
DEPLOYMENT_TIMEOUT_MS=1800000            # 30 minutes, default: 1800000
HEALTH_CHECK_RETRY_COUNT=5               # Retries, default: 5
HEALTH_CHECK_RETRY_INTERVAL_MS=60000     # 1 minute, default: 60000

# Feature Flags
ENABLE_WEBHOOK_SIGNATURE_VERIFICATION=false    # Phase 4, default: false
ENABLE_AUTO_REMEDIATION=false                  # Phase 3, default: false
ENABLE_PATTERN_VISUALIZATION=false             # Phase 3, default: false
ENABLE_COST_OPTIMIZATION_ENGINE=false          # Phase 3, default: false

# Logging
LOG_LEVEL=info                           # debug | info | warn | error, default: info
LOG_SAMPLING_PERCENTAGE=100              # 0-100, default: 100 (dev), 10 (prod)
```

### Azure Resources

**Resource Group**: `rg-brookside-innovation-automation-dev`
**Region**: `eastus` (or specify)

**Resources**:
- **Function App**: `func-brookside-innovation-dev`
  - SKU: Consumption (Y1)
  - Runtime: Node.js 18 LTS
  - Operating System: Linux
  - Always On: Not available (Consumption limitation)
  - Managed Identity: System-assigned enabled

- **Key Vault**: `kv-brookside-inn-dev`
  - SKU: Standard
  - Access Policy: Function App Managed Identity with Get/List Secrets
  - Soft Delete: Enabled (90-day retention)
  - Purge Protection: Disabled (development only)

- **Cosmos DB Account**: `cosmos-brookside-innovation-dev`
  - SKU: Serverless
  - Consistency: Session (default, optimal for single-region)
  - Backup: Continuous (7-day retention)
  - Multi-Region: Disabled (development only)

- **Storage Account**: `stbrooksideautodev`
  - SKU: Standard_LRS
  - Kind: StorageV2
  - Access Tier: Hot
  - HTTPS Only: Enabled
  - Tables: `OrchestrationState`, `WorkflowLogs`, `PatternCache`

- **Application Insights**: `appi-brookside-innovation-dev`
  - SKU: Basic (pay-as-you-go)
  - Sampling: 100% (development), 10% (production)
  - Retention: 90 days

- **Log Analytics Workspace**: `log-brookside-innovation-dev`
  - SKU: Pay-as-you-go
  - Retention: 30 days
  - Daily Cap: 5 GB (cost protection)

- **Managed Identity**: System-assigned for Function App
  - Permissions:
    - Key Vault: Get/List Secrets
    - Cosmos DB: Data Contributor
    - Storage Account: Storage Blob Data Contributor
    - Resource Group: Contributor (for deployment)

---

## Setup Instructions (AI Agent Executable)

### Prerequisites Verification

**BEFORE proceeding, verify all tools are installed with correct versions**:

```bash
# Check Node.js version (must be >= 18.0.0)
node --version
# Expected output: v18.19.0 or higher

# Check npm version (must be >= 10.0.0)
npm --version
# Expected output: 10.2.4 or higher

# Check Azure CLI (must be >= 2.50.0)
az --version | grep "azure-cli"
# Expected output: azure-cli 2.55.0 or higher

# Check Azure Functions Core Tools (must be >= 4.0.5455)
func --version
# Expected output: 4.0.5455 or higher

# Check PowerShell (must be >= 7.0.0)
pwsh --version
# Expected output: 7.4.0 or higher

# Check Git (must be >= 2.40.0)
git --version
# Expected output: git version 2.43.0 or higher
```

**If any version check fails**:
- Node.js: Download from https://nodejs.org/en/download/ (LTS version 18.x)
- npm: Bundled with Node.js, upgrade with `npm install -g npm@latest`
- Azure CLI: https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- Azure Functions Core Tools: `npm install -g azure-functions-core-tools@4`
- PowerShell: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell
- Git: https://git-scm.com/downloads

### Step 1: Repository Clone

```bash
# Clone the repository (if not already cloned)
git clone https://github.com/brookside-bi/autonomous-innovation-platform.git
cd autonomous-innovation-platform

# Verify you're on the correct branch
git branch --show-current
# Expected output: main (or specify branch)

# Verify repository structure
ls -la
# Expected output: Should show functions/, infrastructure/, docs/, README.md
```

### Step 2: Azure Authentication

```bash
# Login to Azure (opens browser for authentication)
az login

# Verify successful authentication
az account show
# Expected output: JSON with subscription details

# Set active subscription
az account set --subscription "cfacbbe8-a2a3-445f-a188-68b3b35f0c84"

# Verify subscription selection
az account show --query name
# Expected output: "Azure subscription 1"

# Verify Key Vault access
az keyvault secret list --vault-name kv-brookside-secrets
# Expected output: List of secrets (or empty if none created yet)
```

**If authentication fails**:
- Ensure Azure account has access to subscription `cfacbbe8-a2a3-445f-a188-68b3b35f0c84`
- Contact Azure administrator for access if needed
- Verify firewall/proxy settings allow Azure CLI authentication

### Step 3: Infrastructure Deployment

```powershell
# Navigate to infrastructure directory
cd infrastructure

# Verify Bicep file exists
Test-Path ./main.bicep
# Expected output: True

# Review deployment parameters
Get-Content ./parameters.json | ConvertFrom-Json
# Expected output: Environment-specific configuration

# Deploy infrastructure (PowerShell required)
pwsh ./deploy.ps1 -Environment dev

# Expected output:
# [INFO] Starting deployment for environment: dev
# [INFO] Deploying resource group: rg-brookside-innovation-automation-dev
# [INFO] Deploying Bicep template...
# [SUCCESS] Deployment completed successfully
# [INFO] Function App URL: https://func-brookside-innovation-dev.azurewebsites.net
# [INFO] Cosmos DB Endpoint: https://cosmos-brookside-innovation-dev.documents.azure.com:443/
# [INFO] Key Vault URI: https://kv-brookside-inn-dev.vault.azure.net/

# Verify resources deployed
az resource list --resource-group rg-brookside-innovation-automation-dev --query "[].{name:name, type:type, location:location}" --output table
# Expected output: Table with Function App, Cosmos DB, Storage, Key Vault, App Insights
```

**Deployment Duration**: Approximately 5-10 minutes

**If deployment fails**:
- Check Azure CLI authentication status: `az account show`
- Verify subscription has quota for required resources
- Review deployment logs: `az deployment group show --name <deployment-name> --resource-group rg-brookside-innovation-automation-dev`
- Check for naming conflicts (resource names must be globally unique)

### Step 4: Key Vault Secret Configuration

```bash
# Set required secrets in Key Vault

# Notion API Key (retrieve from Notion integration settings)
az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "NOTION-API-KEY" \
  --value "<YOUR_NOTION_API_KEY>"

# Verify secret created
az keyvault secret show \
  --vault-name kv-brookside-inn-dev \
  --name "NOTION-API-KEY" \
  --query id
# Expected output: Secret ID URI

# GitHub Personal Access Token (retrieve from GitHub settings)
az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "GITHUB-PERSONAL-ACCESS-TOKEN" \
  --value "<YOUR_GITHUB_PAT>"

# Azure OpenAI API Key (retrieve from Azure Portal)
az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "AZURE-OPENAI-API-KEY" \
  --value "<YOUR_AZURE_OPENAI_KEY>"

# Cosmos DB Key (auto-retrieved from deployment)
COSMOS_KEY=$(az cosmosdb keys list \
  --resource-group rg-brookside-innovation-automation-dev \
  --name cosmos-brookside-innovation-dev \
  --query primaryMasterKey -o tsv)

az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "COSMOS-KEY" \
  --value "$COSMOS_KEY"

# Optional: Teams Webhook URL
az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "TEAMS-WEBHOOK-URL" \
  --value "<YOUR_TEAMS_WEBHOOK_URL>"

# Optional: Logic App Email Webhook
az keyvault secret set \
  --vault-name kv-brookside-inn-dev \
  --name "LOGIC-APP-EMAIL-WEBHOOK-URL" \
  --value "<YOUR_LOGIC_APP_URL>"

# Verify all secrets created
az keyvault secret list --vault-name kv-brookside-inn-dev --query "[].name" --output table
# Expected output: List including NOTION-API-KEY, GITHUB-PERSONAL-ACCESS-TOKEN, AZURE-OPENAI-API-KEY, COSMOS-KEY
```

### Step 5: Function Code Deployment

```bash
# Navigate to functions directory
cd ../functions

# Install dependencies
npm install

# Verify installation succeeded
echo $?
# Expected output: 0 (success)

# Verify critical packages installed
npm list durable-functions @azure/cosmos @azure/data-tables @octokit/rest
# Expected output: Package tree with correct versions

# Build Function App (if TypeScript - skip if pure JavaScript)
# npm run build

# Publish to Azure Function App
func azure functionapp publish func-brookside-innovation-dev

# Expected output:
# Getting site publishing info...
# Uploading package...
# Upload completed successfully.
# Deployment completed successfully.
# Functions in func-brookside-innovation-dev:
#   NotionWebhookReceiver - [httpTrigger]
#     Invoke url: https://func-brookside-innovation-dev.azurewebsites.net/api/NotionWebhookReceiver
#   BuildPipelineOrchestrator - [orchestrationTrigger]
#   ResearchSwarmOrchestrator - [orchestrationTrigger]
#   (... 12 activity functions listed)

# Verify deployment status
func azure functionapp list-functions func-brookside-innovation-dev

# Expected output: List of all deployed functions with their triggers
```

**Deployment Duration**: Approximately 2-5 minutes

**If deployment fails**:
- Verify Function App exists: `az functionapp show --name func-brookside-innovation-dev --resource-group rg-brookside-innovation-automation-dev`
- Check npm dependencies: `npm list` for errors
- Review Function App logs: `func azure functionapp logstream func-brookside-innovation-dev`
- Ensure publish profile credentials: `az functionapp deployment list-publishing-credentials`

### Step 6: Cosmos DB Initialization

```bash
# Navigate to root directory
cd ..

# Create database (if not auto-created by deployment)
az cosmosdb sql database create \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --name innovation-platform

# Verify database created
az cosmosdb sql database show \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --name innovation-platform \
  --query id
# Expected output: Database resource ID

# Create containers
az cosmosdb sql container create \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --database-name innovation-platform \
  --name patterns \
  --partition-key-path "/patternType" \
  --throughput "autoscale" \
  --max-throughput 1000

az cosmosdb sql container create \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --database-name innovation-platform \
  --name build-history \
  --partition-key-path "/buildId" \
  --throughput "autoscale" \
  --max-throughput 1000

# Verify containers created
az cosmosdb sql container list \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --database-name innovation-platform \
  --query "[].name" --output table
# Expected output: patterns, build-history
```

### Step 7: Notion Webhook Configuration

**MANUAL STEP**: Configure Notion webhooks via Notion API

```bash
# Get Function App webhook URL
WEBHOOK_URL=$(az functionapp show \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --query "defaultHostName" -o tsv)

echo "Webhook URL: https://${WEBHOOK_URL}/api/NotionWebhookReceiver"

# Follow Notion webhook registration guide:
# https://developers.notion.com/docs/webhooks
# 1. Navigate to Notion Integrations: https://www.notion.so/my-integrations
# 2. Select integration created for this platform
# 3. Add webhook subscription:
#    - URL: https://${WEBHOOK_URL}/api/NotionWebhookReceiver
#    - Database ID: 984a4038-3e45-4a98-8df4-fd64dd8a1032 (Ideas Registry)
#    - Events: database.page.updated
# 4. Repeat for other databases (Research Hub, Example Builds)
```

### Step 8: Local Testing (Optional)

```bash
# Navigate to functions directory
cd functions

# Start local Function App
func start

# Expected output:
# Azure Functions Core Tools
# Core Tools Version:       4.0.5455
# Function Runtime Version: 4.x
#
# Functions:
#   NotionWebhookReceiver: [POST] http://localhost:7071/api/NotionWebhookReceiver
#   (... other functions listed)

# Test webhook endpoint (in new terminal)
curl -X POST http://localhost:7071/api/NotionWebhookReceiver \
  -H "Content-Type: application/json" \
  -d '{
    "object": "database",
    "id": "984a4038-3e45-4a98-8df4-fd64dd8a1032",
    "properties": {
      "Status": {"select": {"name": "Active"}},
      "Viability": {"select": {"name": "High"}},
      "Effort": {"select": {"name": "S"}}
    }
  }'

# Expected output:
# {
#   "success": true,
#   "message": "Webhook processed successfully",
#   "orchestrationId": "...",
#   "orchestrationType": "BuildPipelineOrchestrator"
# }

# Check Function logs for orchestration execution
# Look for: "BuildPipelineOrchestrator started with ID: ..."
```

### Step 9: End-to-End Validation

**Test Scenario: Autonomous Build Trigger**

1. **Create Test Idea in Notion**:
   - Open Notion Ideas Registry
   - Create new entry: "Test Build - API Service"
   - Set Status: "Active"
   - Set Viability: "High"
   - Set Effort: "S"
   - Save

2. **Monitor Webhook Trigger**:
   ```bash
   # Stream Function App logs
   func azure functionapp logstream func-brookside-innovation-dev

   # Look for:
   # [NotionWebhookReceiver] Webhook received for database: 984a4038-3e45-...
   # [NotionWebhookReceiver] Trigger evaluation: Launch Build Pipeline
   # [BuildPipelineOrchestrator] Orchestration started with ID: ...
   ```

3. **Track Build Pipeline Progress**:
   - Open Azure Portal → Function App → Monitor
   - Navigate to Durable Functions → Instances
   - Find orchestration instance by ID
   - Verify stages execute sequentially:
     - Stage 1: Architecture Generation (5-15 min)
     - Stage 2: Code Generation (10-30 min)
     - Stage 3: GitHub Repository Creation (2-5 min)
     - Stage 4: Azure Deployment (15-45 min)
     - Stage 5: Health Validation (5-10 min)
     - Stage 6: Knowledge Capture (10-20 min)

4. **Verify Notion Updates**:
   - Return to Notion Example Builds database
   - Verify new entry created: "🛠️ Test Build - API Service"
   - Check Status updates throughout pipeline execution
   - Confirm production URL populated on completion

5. **Validate Deployed Application**:
   ```bash
   # Get deployed app URL from Notion or Application Insights
   DEPLOYED_URL="https://<app-name>.azurewebsites.net"

   # Test health endpoint
   curl ${DEPLOYED_URL}/health
   # Expected output: {"status":"healthy","timestamp":"..."}
   ```

**Success Criteria**:
- ✅ Webhook received and processed within 5 seconds
- ✅ Orchestration completes all 6 stages without errors
- ✅ GitHub repository created with initial commit
- ✅ Azure resources provisioned correctly
- ✅ Health checks pass (5/5 retries)
- ✅ Notion build entry updated with production URL
- ✅ Knowledge Vault entry created
- ✅ Total duration < 2 hours

---

## Rollback Procedures

### Function App Rollback

```bash
# List recent deployments
az functionapp deployment list \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --query "[].{id:id, status:status, start:start_time}" \
  --output table

# Get previous deployment ID
PREVIOUS_DEPLOYMENT_ID="<deployment-id-from-list>"

# Rollback to previous deployment
func azure functionapp publish func-brookside-innovation-dev \
  --slot staging

# Or redeploy from Git commit
git checkout <previous-commit-hash>
cd functions
npm install
func azure functionapp publish func-brookside-innovation-dev

# Verify rollback
curl https://func-brookside-innovation-dev.azurewebsites.net/api/NotionWebhookReceiver -I
# Expected: HTTP 200 OK
```

### Infrastructure Rollback

```powershell
# Revert to previous Bicep template
cd infrastructure
git log --oneline --decorate --graph
git checkout <previous-commit-hash>

# Redeploy infrastructure
pwsh ./deploy.ps1 -Environment dev

# Verify resource states
az resource list --resource-group rg-brookside-innovation-automation-dev
```

### Cosmos DB Rollback

**Continuous Backup Enabled - Point-in-Time Restore**:

```bash
# List available restore timestamps
az cosmosdb sql restorable-database list \
  --location eastus \
  --instance-id <cosmos-instance-id>

# Restore to specific point in time
az cosmosdb restore \
  --target-database-account-name cosmos-brookside-innovation-dev-restored \
  --account-name cosmos-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --restore-timestamp "2025-01-15T10:00:00Z" \
  --location eastus

# Update Function App connection to restored database
az functionapp config appsettings set \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --settings COSMOS_ENDPOINT=https://cosmos-brookside-innovation-dev-restored.documents.azure.com:443/
```

**CRITICAL**: Always backup before major schema changes or data migrations.

---

## Known Issues & Workarounds

### Issue 1: Webhook Signature Verification Not Implemented

**Symptom**: Notion webhooks accepted without cryptographic signature validation

**Risk**: Unauthorized parties could send spoofed webhook payloads

**Workaround**:
```bash
# Restrict Function App to Notion IP addresses only
az functionapp config access-restriction add \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --rule-name AllowNotionWebhooks \
  --action Allow \
  --ip-address <NOTION_WEBHOOK_IP>/32 \
  --priority 100

# Verify restriction applied
az functionapp config access-restriction show \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev
```

**Permanent Fix**: Phase 4 - Implement `X-Notion-Signature` header verification per https://developers.notion.com/docs/webhooks#verifying-webhook-signatures

---

### Issue 2: Cold Start Latency (Consumption Plan)

**Symptom**: First webhook after 20+ minutes idle takes 10-30 seconds to respond, causing Notion webhook timeout

**Impact**: Notion retries webhook automatically (safe), but delays automation start

**Workaround**:
```bash
# Option 1: Upgrade to Premium Plan (always-on instances)
az functionapp update \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --plan <premium-plan-name>

# Option 2: Implement pre-warm via Timer Trigger (every 15 minutes)
# See: functions/PreWarmFunction/index.js

# Option 3: Accept initial latency (recommended for development)
# Notion webhooks automatically retry on timeout
```

**Permanent Fix**: Production deployment uses Premium Plan (EP1) with 1 always-on instance (~$150/month).

---

### Issue 3: Cost Estimation Accuracy ±20%

**Symptom**: AI-generated cost estimates differ from actual Azure costs by up to 20%

**Cause**: AI agents lack real-time Azure pricing API access, use cached/approximate pricing

**Workaround**:
```bash
# Use conservative cost threshold with escalation buffer
# Set AUTO_APPROVE_COST_THRESHOLD to 80% of acceptable cost
# Example: $500 acceptable → set threshold to $400

az functionapp config appsettings set \
  --name func-brookside-innovation-dev \
  --resource-group rg-brookside-innovation-automation-dev \
  --settings AUTO_APPROVE_COST_THRESHOLD=400

# Enable cost escalation for gray-zone estimates
# Escalates $400-500 builds to human review
```

**Permanent Fix**: Phase 3 - Integrate Azure Pricing API for real-time cost calculations.

---

### Issue 4: GitHub Rate Limiting During Bulk Operations

**Symptom**: Repository creation fails with `403 Rate Limit Exceeded` when creating 10+ repos/hour

**Impact**: Build Pipeline fails at Stage 3 (GitHub Repository Creation)

**Workaround**:
```javascript
// Implement exponential backoff retry in CreateGitHubRepository function
// Located in: functions/CreateGitHubRepository/index.js

const retryGitHubOperation = async (operation, maxRetries = 5) => {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await operation();
    } catch (error) {
      if (error.status === 403 && attempt < maxRetries) {
        const waitTime = Math.pow(2, attempt) * 1000; // Exponential backoff
        await new Promise(resolve => setTimeout(resolve, waitTime));
      } else {
        throw error;
      }
    }
  }
};
```

**Permanent Fix**: Already implemented in Phase 2. Verify `@octokit/rest` version ≥ 20.0.2.

---

## Cost Optimization Opportunities

**Current Monthly Cost**: $103-163/month (infrastructure + AI)

**Optimization Recommendations**:

1. **Cosmos DB Reserved Capacity**:
   - **Current**: Serverless pay-per-request (~$25/month)
   - **Alternative**: Reserved 400 RU/s capacity ($24/month flat)
   - **Savings**: $1-5/month + predictable billing
   - **When**: After establishing baseline usage (3-6 months)

2. **Application Insights Sampling**:
   - **Current**: 100% sampling (development)
   - **Production**: Reduce to 10% sampling
   - **Savings**: ~$8/month (80% reduction in telemetry)
   - **When**: After identifying critical telemetry events

3. **Function App Premium Plan (Production Only)**:
   - **Current**: Consumption Plan ($10/month) with cold starts
   - **Alternative**: Premium EP1 ($150/month) with always-on instances
   - **Benefit**: Eliminates cold starts, SLA guarantees
   - **When**: Production deployment only (not development)

4. **Azure OpenAI vs. Anthropic Direct**:
   - **Azure OpenAI**: Higher cost (~$40-60/month), Azure ecosystem integration
   - **Anthropic Direct**: Lower cost (~$20-30/month), faster response times
   - **Recommendation**: Use Anthropic for development, Azure OpenAI for production compliance

5. **Consolidated Key Vault**:
   - **Current**: Dedicated Key Vault for this project ($3/month)
   - **Alternative**: Share with existing Brookside BI Key Vault ($0 incremental)
   - **Savings**: $3/month
   - **When**: After security review confirms no isolation requirements

**Total Potential Savings**: $15-20/month (~15% reduction)

---

## Maintenance & Updates

### Dependency Updates

```bash
# Check for outdated packages
cd functions
npm outdated

# Update dependencies (with testing)
npm update

# Verify tests still pass (when implemented)
npm test

# Redeploy Function App
func azure functionapp publish func-brookside-innovation-dev
```

### Security Patches

```bash
# Check for security vulnerabilities
cd functions
npm audit

# Apply security fixes (automatic)
npm audit fix

# For breaking changes requiring manual intervention
npm audit fix --force

# CRITICAL: Run full end-to-end test after forced fixes
# Test webhook trigger → Build Pipeline → Deployment → Health Check
```

### Azure Resource Updates

```powershell
# Update infrastructure with new Bicep template changes
cd infrastructure
git pull origin main
pwsh ./deploy.ps1 -Environment dev

# Verify deployment succeeded
az deployment group show \
  --name InnovationPlatformDeployment \
  --resource-group rg-brookside-innovation-automation-dev \
  --query properties.provisioningState
# Expected output: "Succeeded"
```

---

## Related Resources

**Origin**:
- Notion Ideas Registry: [To be linked after Idea entry created]

**Research**:
- Notion Research Hub: [To be linked if research entry exists]

**GitHub Repository**:
- https://github.com/brookside-bi/autonomous-innovation-platform (to be created)

**Azure Resources**:
- Function App: https://portal.azure.com/#resource/subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-innovation-automation-dev/providers/Microsoft.Web/sites/func-brookside-innovation-dev
- Cosmos DB: https://portal.azure.com/#resource/subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-innovation-automation-dev/providers/Microsoft.DocumentDB/databaseAccounts/cosmos-brookside-innovation-dev

**Teams Channel**:
- [To be created - #autonomous-innovation]

**SharePoint Documentation**:
- [To be created - Autonomous Platform Documentation folder]

**Knowledge Vault Articles**:
- Phase 1 Completion: Foundation Infrastructure
- Phase 2 Completion: Agent Integration & Activity Functions

---

**Document Version**: 1.0
**Last Reviewed**: 2025-01-15
**Next Review**: 2025-02-15 (monthly during active development)
**Prepared By**: Claude AI (Build Architect Agent)
**In Collaboration With**: Brookside BI

---

**🎯 This technical specification establishes zero-ambiguity deployment infrastructure that enables autonomous replication by AI agents or human operators, driving measurable outcomes through systematic knowledge preservation and cost transparency.**
