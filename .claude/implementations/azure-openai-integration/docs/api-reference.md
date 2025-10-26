# Azure OpenAI API Reference

Comprehensive API documentation for Azure OpenAI Service integration with Brookside BI Innovation Nexus, establishing clear specifications for authentication, request/response formats, rate limits, and error handling.

**Best for**: Developers implementing Azure OpenAI API calls, troubleshooting integration issues, and optimizing API usage for cost efficiency.

**Version**: 1.0.0
**Last Updated**: 2025-10-26
**API Version**: 2024-02-15-preview

---

## Table of Contents

1. [Authentication](#authentication)
2. [Endpoints](#endpoints)
3. [Request/Response Formats](#requestresponse-formats)
4. [Rate Limits](#rate-limits)
5. [Error Codes](#error-codes)
6. [Cost Tracking](#cost-tracking)

---

## Authentication

### Overview

Azure OpenAI Service supports two authentication methods:
1. **Azure AD (Managed Identity)** - Recommended for production
2. **API Key** - Deprecated, disabled by default in our deployment

**Security Principle**: All Innovation Nexus deployments use **Azure AD-only authentication** with `disableLocalAuth: true`.

---

### Managed Identity Configuration

**Resource Configuration**:
```json
{
  "identity": {
    "type": "UserAssigned",
    "userAssignedIdentities": {
      "/subscriptions/cfacbbe8-a2a3-445f-a188-68b3b35f0c84/resourceGroups/rg-brookside-aoai-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-brookside-aoai-dev": {}
    }
  },
  "properties": {
    "disableLocalAuth": true
  }
}
```

**RBAC Role Assignment**:
```bash
# Assign Cognitive Services OpenAI User role
az role assignment create \
  --assignee <managed-identity-principal-id> \
  --role "Cognitive Services OpenAI User" \
  --scope <azure-openai-resource-id>

# Verify assignment
az role assignment list \
  --assignee <managed-identity-principal-id> \
  --scope <azure-openai-resource-id> \
  --query "[].roleDefinitionName"
```

---

### Code Examples

#### TypeScript (Azure SDK)

```typescript
import { OpenAIClient } from '@azure/openai';
import { DefaultAzureCredential, ManagedIdentityCredential } from '@azure/identity';

/**
 * Establish Azure OpenAI client with Managed Identity authentication.
 * Supports both local development (Azure CLI) and Azure-hosted apps.
 */
export function createOpenAIClient(
  endpoint: string,
  useLocalAuth: boolean = false
): OpenAIClient {
  let credential;

  if (useLocalAuth) {
    // Local development: Azure CLI credential
    credential = new DefaultAzureCredential();
  } else {
    // Azure-hosted app: Managed Identity
    const clientId = process.env.AZURE_CLIENT_ID;
    credential = new ManagedIdentityCredential({ clientId });
  }

  return new OpenAIClient(endpoint, credential);
}

// Usage
const endpoint = process.env.AZURE_OPENAI_ENDPOINT!;
const client = createOpenAIClient(endpoint);
```

#### Python (OpenAI SDK)

```python
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
import os

def create_openai_client(endpoint: str, use_local_auth: bool = False) -> AzureOpenAI:
    """
    Establish Azure OpenAI client with Managed Identity authentication.
    Supports both local development (Azure CLI) and Azure-hosted apps.
    """
    if use_local_auth:
        # Local development: Azure CLI credential
        credential = DefaultAzureCredential()
    else:
        # Azure-hosted app: Managed Identity
        client_id = os.environ.get('AZURE_CLIENT_ID')
        credential = ManagedIdentityCredential(client_id=client_id)

    # Get access token
    token = credential.get_token("https://cognitiveservices.azure.com/.default")

    return AzureOpenAI(
        azure_endpoint=endpoint,
        azure_ad_token=token.token,
        api_version="2024-02-15-preview"
    )

# Usage
endpoint = os.environ['AZURE_OPENAI_ENDPOINT']
client = create_openai_client(endpoint)
```

#### PowerShell (REST API)

```powershell
# Get access token via Azure CLI
$token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv

# Construct headers
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# Execute API call
$endpoint = $env:AZURE_OPENAI_ENDPOINT
$deploymentName = "gpt-4-turbo"

$body = @{
    messages = @(
        @{ role = "system"; content = "You are a helpful assistant." },
        @{ role = "user"; content = "Hello!" }
    )
    max_tokens = 100
} | ConvertTo-Json -Depth 10

$response = Invoke-RestMethod `
    -Uri "$endpoint/openai/deployments/$deploymentName/chat/completions?api-version=2024-02-15-preview" `
    -Method POST `
    -Headers $headers `
    -Body $body
```

---

### Token Validation

**JWT Token Structure**:
```json
{
  "aud": "https://cognitiveservices.azure.com",
  "iss": "https://sts.windows.net/2930489e-9d8a-456b-9de9-e4787faeab9c/",
  "iat": 1730000000,
  "exp": 1730003600,
  "sub": "<user-object-id>",
  "tid": "2930489e-9d8a-456b-9de9-e4787faeab9c",
  "roles": ["Cognitive Services OpenAI User"]
}
```

**Validation Steps**:
1. Verify `aud` claim matches `https://cognitiveservices.azure.com`
2. Check `exp` (expiration) is in the future
3. Confirm `roles` includes `Cognitive Services OpenAI User`
4. Validate `tid` (tenant ID) matches your Azure AD tenant

**PowerShell Token Inspection**:
```powershell
$token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv

# Decode JWT (requires jq)
$token -split '\.' | Select-Object -Index 1 | ForEach-Object {
    $padding = '=' * ((4 - ($_.Length % 4)) % 4)
    [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_ + $padding))
} | ConvertFrom-Json
```

---

## Endpoints

### Base URL Structure

```
https://<resource-name>.openai.azure.com/
```

**Environment-Specific Endpoints**:

| Environment | Endpoint | Deployment |
|-------------|----------|------------|
| **Development** | `https://aoai-brookside-dev-eastus.openai.azure.com/` | `gpt-4-turbo` |
| **Staging** | `https://aoai-brookside-staging-eastus.openai.azure.com/` | `gpt-4-turbo` |
| **Production** | `https://aoai-brookside-prod-eastus.openai.azure.com/` | `gpt-4-turbo` |

---

### API Endpoints

#### Chat Completions

**Endpoint**: `/openai/deployments/{deployment-name}/chat/completions`
**Method**: POST
**API Version**: `2024-02-15-preview`

**Full URL**:
```
https://aoai-brookside-dev-eastus.openai.azure.com/openai/deployments/gpt-4-turbo/chat/completions?api-version=2024-02-15-preview
```

**Headers**:
```http
Authorization: Bearer <azure-ad-token>
Content-Type: application/json
```

**Request Body**:
```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant."
    },
    {
      "role": "user",
      "content": "What is Azure OpenAI?"
    }
  ],
  "max_tokens": 500,
  "temperature": 0.7,
  "top_p": 1.0,
  "frequency_penalty": 0.0,
  "presence_penalty": 0.0,
  "stop": null,
  "stream": false
}
```

**Response**:
```json
{
  "id": "chatcmpl-8xYzABCDEFG",
  "object": "chat.completion",
  "created": 1730000000,
  "model": "gpt-4-turbo",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Azure OpenAI Service is a managed service that provides REST API access to OpenAI's powerful language models, including GPT-4 and GPT-3.5, hosted on Microsoft Azure infrastructure."
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 25,
    "completion_tokens": 45,
    "total_tokens": 70
  }
}
```

---

#### Embeddings

**Endpoint**: `/openai/deployments/{deployment-name}/embeddings`
**Method**: POST
**API Version**: `2024-02-15-preview`

**Full URL**:
```
https://aoai-brookside-dev-eastus.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2024-02-15-preview
```

**Request Body**:
```json
{
  "input": "Azure OpenAI Service enables intelligent automation",
  "user": "innovation-nexus"
}
```

**Response**:
```json
{
  "object": "list",
  "data": [
    {
      "object": "embedding",
      "index": 0,
      "embedding": [
        0.012345,
        -0.023456,
        0.034567,
        // ... (1536 dimensions for ada-002)
      ]
    }
  ],
  "model": "text-embedding-ada-002",
  "usage": {
    "prompt_tokens": 8,
    "total_tokens": 8
  }
}
```

---

#### Streaming Responses

**Purpose**: Reduce perceived latency for long-running completions.

**Request Parameter**:
```json
{
  "stream": true
}
```

**Response Format** (Server-Sent Events):
```
data: {"id":"chatcmpl-123","choices":[{"delta":{"content":"Azure"},"index":0}]}

data: {"id":"chatcmpl-123","choices":[{"delta":{"content":" OpenAI"},"index":0}]}

data: {"id":"chatcmpl-123","choices":[{"delta":{"content":" Service"},"index":0}]}

data: [DONE]
```

**TypeScript Example**:
```typescript
import { OpenAIClient } from '@azure/openai';

const result = await client.streamChatCompletions(deploymentName, messages, {
  maxTokens: 500
});

for await (const chunk of result) {
  const delta = chunk.choices[0]?.delta?.content;
  if (delta) {
    process.stdout.write(delta);
  }
}
```

---

## Request/Response Formats

### Message Roles

| Role | Purpose | Example |
|------|---------|---------|
| **system** | Sets assistant behavior and context | `"You are a Brookside BI innovation analyst."` |
| **user** | User input or prompt | `"Assess this idea's viability"` |
| **assistant** | Previous AI responses (for conversation history) | `"Based on market analysis..."` |

---

### Parameters Reference

#### Chat Completions Parameters

| Parameter | Type | Default | Range/Options | Description |
|-----------|------|---------|---------------|-------------|
| **messages** | array | Required | - | Array of message objects with `role` and `content` |
| **max_tokens** | integer | 4096 | 1-32768 | Maximum tokens to generate |
| **temperature** | number | 1.0 | 0.0-2.0 | Sampling temperature (higher = more random) |
| **top_p** | number | 1.0 | 0.0-1.0 | Nucleus sampling (alternative to temperature) |
| **frequency_penalty** | number | 0.0 | -2.0 to 2.0 | Penalize new tokens based on frequency |
| **presence_penalty** | number | 0.0 | -2.0 to 2.0 | Penalize new tokens based on presence |
| **stop** | string/array | null | - | Sequences where API will stop generating |
| **stream** | boolean | false | true/false | Enable streaming responses |
| **response_format** | object | - | `{"type": "json_object"}` | Force JSON output |
| **seed** | integer | null | - | Deterministic sampling (reproducible outputs) |
| **user** | string | - | - | Unique user identifier for abuse monitoring |

---

#### Parameter Optimization Guidelines

**Temperature Selection**:
- **0.0-0.3**: Deterministic, consistent outputs (viability scoring, classifications)
- **0.4-0.7**: Balanced creativity (research synthesis, recommendations)
- **0.8-2.0**: High variability (brainstorming, creative content)

**Token Management**:
```typescript
// Estimate tokens (rough: 1 token ≈ 4 characters)
function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

// Reserve buffer for response
const contextTokens = estimateTokens(systemPrompt + userPrompt);
const maxTokens = 4096 - contextTokens - 100; // 100 token buffer
```

**Stop Sequences**:
```json
{
  "stop": ["\n\n", "###", "User:", "Assistant:"]
}
```

---

### JSON Mode (Structured Outputs)

**Purpose**: Force model to return valid JSON for programmatic parsing.

**Request**:
```json
{
  "messages": [
    {
      "role": "system",
      "content": "You are a JSON-only API. Always return valid JSON."
    },
    {
      "role": "user",
      "content": "Assess idea viability and return JSON with fields: marketDemand, technicalFeasibility, costEffectiveness, overall, reasoning, recommendation"
    }
  ],
  "response_format": { "type": "json_object" },
  "temperature": 0.3
}
```

**Response** (guaranteed valid JSON):
```json
{
  "choices": [
    {
      "message": {
        "content": "{\"marketDemand\":85,\"technicalFeasibility\":78,\"costEffectiveness\":90,\"overall\":84,\"reasoning\":\"Strong market need with proven technology stack and favorable cost structure.\",\"recommendation\":\"High\"}"
      }
    }
  ]
}
```

**TypeScript Parsing**:
```typescript
const response = await client.getChatCompletions(deploymentName, messages, {
  responseFormat: { type: 'json_object' },
  temperature: 0.3
});

const content = response.choices[0].message?.content || '{}';
const result = JSON.parse(content);

console.log(`Viability Score: ${result.overall}/100`);
console.log(`Recommendation: ${result.recommendation}`);
```

---

## Rate Limits

### Quota Types

Azure OpenAI enforces rate limits at multiple levels:

1. **Tokens Per Minute (TPM)**: Total tokens (prompt + completion) per minute
2. **Requests Per Minute (RPM)**: Total API requests per minute
3. **Tokens Per Day (TPD)**: Total tokens per 24-hour period

---

### Environment-Specific Limits

| Environment | Model | TPM | RPM | TPD |
|-------------|-------|-----|-----|-----|
| **Development** | GPT-4 Turbo | 10,000 | 60 | 500,000 |
| **Staging** | GPT-4 Turbo | 20,000 | 120 | 1,000,000 |
| **Production** | GPT-4 Turbo | 30,000 | 180 | 2,000,000 |

**Note**: Limits are per deployment, not per subscription.

---

### Rate Limit Headers

**Response Headers**:
```http
x-ratelimit-limit-requests: 180
x-ratelimit-limit-tokens: 30000
x-ratelimit-remaining-requests: 175
x-ratelimit-remaining-tokens: 28456
x-ratelimit-reset-requests: 60s
x-ratelimit-reset-tokens: 60s
```

**Monitoring Script**:
```typescript
async function checkRateLimits(response: Response): Promise<void> {
  const remainingRequests = response.headers.get('x-ratelimit-remaining-requests');
  const remainingTokens = response.headers.get('x-ratelimit-remaining-tokens');

  console.log(`Remaining: ${remainingRequests} requests, ${remainingTokens} tokens`);

  // Alert if approaching limit (90% threshold)
  if (parseInt(remainingTokens || '0') < 3000) {
    console.warn('⚠️ Approaching token rate limit - consider throttling requests');
  }
}
```

---

### Exponential Backoff Strategy

**Implementation**:
```typescript
interface RetryConfig {
  maxAttempts: number;
  baseDelay: number;
  maxDelay: number;
  jitterMax: number;
}

/**
 * Execute OpenAI request with exponential backoff on rate limits.
 * Implements jittered retry delays to prevent thundering herd.
 */
async function executeWithBackoff<T>(
  operation: () => Promise<T>,
  config: RetryConfig = {
    maxAttempts: 3,
    baseDelay: 1000,
    maxDelay: 32000,
    jitterMax: 1000
  }
): Promise<T> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < config.maxAttempts; attempt++) {
    try {
      return await operation();

    } catch (error: any) {
      lastError = error;

      // Only retry on rate limit errors
      if (error.statusCode !== 429) {
        throw error;
      }

      // Extract retry-after header (seconds)
      const retryAfter = parseInt(error.response?.headers['retry-after'] || '0');

      // Calculate delay: max(retry-after, exponential backoff) + jitter
      const exponentialDelay = config.baseDelay * Math.pow(2, attempt);
      const baseDelay = retryAfter > 0 ? retryAfter * 1000 : exponentialDelay;
      const jitter = Math.random() * config.jitterMax;
      const delay = Math.min(baseDelay + jitter, config.maxDelay);

      console.log(`[Attempt ${attempt + 1}/${config.maxAttempts}] Rate limited. Retrying in ${delay}ms...`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error(`Max retry attempts exceeded: ${lastError?.message}`);
}

// Usage
const result = await executeWithBackoff(() =>
  client.getChatCompletions(deploymentName, messages)
);
```

---

### Request Prioritization

**Priority Queue Implementation**:
```typescript
enum Priority {
  Critical = 0,
  High = 1,
  Medium = 2,
  Low = 3
}

interface QueuedRequest {
  priority: Priority;
  operation: () => Promise<any>;
  timestamp: Date;
}

/**
 * Manage OpenAI request queue with priority-based execution.
 * Ensures critical workflows bypass rate limits when possible.
 */
class RequestQueue {
  private queue: QueuedRequest[] = [];
  private executing: number = 0;
  private readonly concurrencyLimit: number;

  constructor(concurrencyLimit: number = 5) {
    this.concurrencyLimit = concurrencyLimit;
  }

  async enqueue<T>(
    operation: () => Promise<T>,
    priority: Priority = Priority.Medium
  ): Promise<T> {
    return new Promise((resolve, reject) => {
      const request: QueuedRequest = {
        priority,
        operation: async () => {
          try {
            const result = await operation();
            resolve(result);
          } catch (error) {
            reject(error);
          }
        },
        timestamp: new Date()
      };

      // Insert based on priority (lower number = higher priority)
      const insertIndex = this.queue.findIndex(r => r.priority > priority);
      if (insertIndex === -1) {
        this.queue.push(request);
      } else {
        this.queue.splice(insertIndex, 0, request);
      }

      this.processQueue();
    });
  }

  private async processQueue(): Promise<void> {
    while (this.executing < this.concurrencyLimit && this.queue.length > 0) {
      const request = this.queue.shift()!;
      this.executing++;

      request.operation().finally(() => {
        this.executing--;
        this.processQueue();
      });
    }
  }
}

// Usage
const queue = new RequestQueue(5);

// Critical workflow (viability assessment) bypasses queue
const viabilityScore = await queue.enqueue(
  () => assessIdeaViability(idea),
  Priority.Critical
);

// Low-priority workflow (knowledge extraction) waits
const knowledgeDoc = await queue.enqueue(
  () => extractKnowledge(build),
  Priority.Low
);
```

---

## Error Codes

### HTTP Status Codes

| Status Code | Error Type | Meaning | Retry Strategy |
|-------------|------------|---------|----------------|
| **200** | Success | Request completed successfully | N/A |
| **400** | Bad Request | Invalid request format or parameters | Fix request, do not retry |
| **401** | Unauthorized | Authentication failed (invalid/expired token) | Refresh token, retry once |
| **403** | Forbidden | Insufficient permissions (RBAC role missing) | Fix RBAC, do not retry |
| **404** | Not Found | Deployment or resource not found | Fix endpoint/deployment, do not retry |
| **429** | Too Many Requests | Rate limit exceeded | Exponential backoff, retry |
| **500** | Internal Server Error | Azure OpenAI service error | Retry with backoff |
| **502** | Bad Gateway | Gateway timeout or error | Retry with backoff |
| **503** | Service Unavailable | Service temporarily unavailable | Retry with backoff |
| **504** | Gateway Timeout | Request timeout | Reduce context size, retry |

---

### Error Response Format

**Standard Error Response**:
```json
{
  "error": {
    "message": "The model deployment 'gpt-4-turbo' was not found.",
    "type": "invalid_request_error",
    "param": "deployment",
    "code": "DeploymentNotFound"
  }
}
```

**Rate Limit Error**:
```json
{
  "error": {
    "message": "Requests to the ChatCompletions_Create Operation have exceeded token rate limit. Please retry after 42 seconds.",
    "type": "rate_limit_exceeded",
    "param": null,
    "code": "429"
  }
}
```

---

### Error Handling Implementation

**TypeScript Error Handler**:
```typescript
class OpenAIError extends Error {
  constructor(
    public statusCode: number,
    public errorType: string,
    public errorCode: string,
    message: string
  ) {
    super(message);
    this.name = 'OpenAIError';
  }

  /**
   * Determine if error is retryable.
   */
  isRetryable(): boolean {
    const retryableCodes = [429, 500, 502, 503, 504];
    return retryableCodes.includes(this.statusCode);
  }

  /**
   * Get user-friendly error message.
   */
  getUserMessage(): string {
    const messages: { [key: number]: string } = {
      400: 'Invalid request. Please check your input parameters.',
      401: 'Authentication failed. Please verify your credentials.',
      403: 'Access denied. You do not have permission to access this resource.',
      404: 'Model deployment not found. Please verify the deployment name.',
      429: 'Rate limit exceeded. Your request has been queued and will be retried automatically.',
      500: 'Azure OpenAI service error. Please try again in a few moments.',
      503: 'Service temporarily unavailable. Please try again later.'
    };

    return messages[this.statusCode] || 'An unexpected error occurred.';
  }
}

/**
 * Parse OpenAI API error response into structured error object.
 */
function parseOpenAIError(error: any): OpenAIError {
  const statusCode = error.response?.status || error.statusCode || 500;
  const errorData = error.response?.data?.error || {};

  return new OpenAIError(
    statusCode,
    errorData.type || 'unknown_error',
    errorData.code || 'UNKNOWN',
    errorData.message || error.message || 'Unknown error'
  );
}

// Usage
try {
  const result = await client.getChatCompletions(deploymentName, messages);
} catch (error) {
  const openAIError = parseOpenAIError(error);

  console.error(`Error ${openAIError.statusCode}: ${openAIError.getUserMessage()}`);

  if (openAIError.isRetryable()) {
    console.log('Retrying with exponential backoff...');
    // Implement retry logic
  } else {
    console.error('Non-retryable error. Please fix the request.');
    throw openAIError;
  }
}
```

---

### Common Error Scenarios

#### Scenario 1: Deployment Not Found (404)

**Error**:
```json
{
  "error": {
    "code": "DeploymentNotFound",
    "message": "The model deployment 'gpt-4-32k' was not found."
  }
}
```

**Resolution**:
```typescript
// Verify deployment name matches Azure configuration
const availableDeployments = await client.listDeployments();
console.log('Available deployments:', availableDeployments.map(d => d.deploymentId));

// Update deployment name
const deploymentName = 'gpt-4-turbo'; // Correct deployment name
```

#### Scenario 2: Token Context Length Exceeded (400)

**Error**:
```json
{
  "error": {
    "code": "context_length_exceeded",
    "message": "This model's maximum context length is 8192 tokens. However, you requested 9500 tokens."
  }
}
```

**Resolution**:
```typescript
// Truncate conversation history
function truncateMessages(messages: any[], maxTokens: number): any[] {
  const systemMessage = messages.find(m => m.role === 'system');
  const recentMessages = messages.filter(m => m.role !== 'system').slice(-5);

  return systemMessage ? [systemMessage, ...recentMessages] : recentMessages;
}

const truncated = truncateMessages(messages, 6000);
const result = await client.getChatCompletions(deploymentName, truncated, {
  maxTokens: 2000 // Reserve tokens for response
});
```

#### Scenario 3: Content Filter Triggered (400)

**Error**:
```json
{
  "error": {
    "code": "content_filter",
    "message": "The response was filtered due to the content management policy."
  }
}
```

**Resolution**:
```typescript
// Check finish_reason for content filter
const result = await client.getChatCompletions(deploymentName, messages);

if (result.choices[0].finishReason === 'content_filter') {
  console.warn('Response filtered by Azure content management policy');
  // Rephrase prompt or adjust content
}
```

---

## Cost Tracking

### Pricing Model

**GPT-4 Turbo Pricing** (as of 2025-10-26):

| Model | Input Tokens | Output Tokens | Embedding Tokens |
|-------|--------------|---------------|------------------|
| **GPT-4 Turbo (128K)** | $0.01 per 1K | $0.03 per 1K | N/A |
| **GPT-3.5 Turbo (16K)** | $0.0005 per 1K | $0.0015 per 1K | N/A |
| **text-embedding-ada-002** | N/A | N/A | $0.0001 per 1K |

---

### Token Calculation

**Estimating Token Count**:
```typescript
/**
 * Estimate token count for text (rough approximation).
 * Rule of thumb: 1 token ≈ 4 characters or ¾ word.
 */
function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

// More accurate: Use tiktoken library
import { encoding_for_model } from '@dqbd/tiktoken';

function countTokens(text: string, model: string = 'gpt-4'): number {
  const encoder = encoding_for_model(model);
  const tokens = encoder.encode(text);
  encoder.free(); // Free memory
  return tokens.length;
}
```

---

### Cost Calculation

**Per-Request Cost**:
```typescript
interface TokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
}

/**
 * Calculate cost for single OpenAI API call.
 * Returns cost breakdown and total in USD.
 */
function calculateCost(
  usage: TokenUsage,
  model: 'gpt-4-turbo' | 'gpt-35-turbo' = 'gpt-4-turbo'
): { promptCost: number; completionCost: number; totalCost: number } {
  const pricing = {
    'gpt-4-turbo': { prompt: 0.01, completion: 0.03 },
    'gpt-35-turbo': { prompt: 0.0005, completion: 0.0015 }
  };

  const rates = pricing[model];
  const promptCost = (usage.promptTokens / 1000) * rates.prompt;
  const completionCost = (usage.completionTokens / 1000) * rates.completion;

  return {
    promptCost,
    completionCost,
    totalCost: promptCost + completionCost
  };
}

// Usage
const result = await client.getChatCompletions(deploymentName, messages);
const usage = {
  promptTokens: result.usage?.promptTokens || 0,
  completionTokens: result.usage?.completionTokens || 0,
  totalTokens: result.usage?.totalTokens || 0
};

const cost = calculateCost(usage);
console.log(`Cost: $${cost.totalCost.toFixed(4)} (prompt: $${cost.promptCost.toFixed(4)}, completion: $${cost.completionCost.toFixed(4)})`);
```

---

### Budget Monitoring

**Daily Cost Tracking**:
```typescript
interface DailyCostTracker {
  date: string;
  requests: number;
  promptTokens: number;
  completionTokens: number;
  totalCost: number;
}

class CostMonitor {
  private dailyCosts: Map<string, DailyCostTracker> = new Map();

  /**
   * Track API call cost for budget monitoring.
   */
  trackRequest(usage: TokenUsage, model: string = 'gpt-4-turbo'): void {
    const today = new Date().toISOString().split('T')[0];
    const cost = calculateCost(usage, model as any);

    const existing = this.dailyCosts.get(today) || {
      date: today,
      requests: 0,
      promptTokens: 0,
      completionTokens: 0,
      totalCost: 0
    };

    existing.requests++;
    existing.promptTokens += usage.promptTokens;
    existing.completionTokens += usage.completionTokens;
    existing.totalCost += cost.totalCost;

    this.dailyCosts.set(today, existing);

    // Check budget thresholds
    this.checkBudgetAlerts(existing);
  }

  /**
   * Alert if daily spending exceeds thresholds.
   */
  private checkBudgetAlerts(tracker: DailyCostTracker): void {
    const dailyBudget = 50; // $50 per day

    const percentUsed = (tracker.totalCost / dailyBudget) * 100;

    if (percentUsed >= 90) {
      console.error(`🚨 CRITICAL: 90% of daily budget consumed ($${tracker.totalCost.toFixed(2)}/$${dailyBudget})`);
    } else if (percentUsed >= 75) {
      console.warn(`⚠️ WARNING: 75% of daily budget consumed ($${tracker.totalCost.toFixed(2)}/$${dailyBudget})`);
    } else if (percentUsed >= 50) {
      console.log(`ℹ️ INFO: 50% of daily budget consumed ($${tracker.totalCost.toFixed(2)}/$${dailyBudget})`);
    }
  }

  /**
   * Get cost summary for date range.
   */
  getSummary(days: number = 7): {
    totalCost: number;
    totalRequests: number;
    avgCostPerRequest: number;
    avgDailyCost: number;
  } {
    const entries = Array.from(this.dailyCosts.values()).slice(-days);

    const totalCost = entries.reduce((sum, e) => sum + e.totalCost, 0);
    const totalRequests = entries.reduce((sum, e) => sum + e.requests, 0);

    return {
      totalCost,
      totalRequests,
      avgCostPerRequest: totalRequests > 0 ? totalCost / totalRequests : 0,
      avgDailyCost: entries.length > 0 ? totalCost / entries.length : 0
    };
  }
}

// Usage
const monitor = new CostMonitor();

const result = await client.getChatCompletions(deploymentName, messages);
monitor.trackRequest(result.usage!);

// Weekly summary
const summary = monitor.getSummary(7);
console.log(`Weekly cost: $${summary.totalCost.toFixed(2)}`);
console.log(`Avg cost per request: $${summary.avgCostPerRequest.toFixed(4)}`);
```

---

### Cost Optimization Metrics

**Key Performance Indicators**:
```typescript
interface CostMetrics {
  cacheHitRate: number; // 0-1 (target: >0.4)
  avgTokensPerRequest: number; // Lower is better
  avgCostPerWorkflow: number; // USD
  monthlyProjection: number; // USD
}

/**
 * Calculate cost optimization metrics for reporting.
 */
function calculateOptimizationMetrics(
  totalRequests: number,
  cachedRequests: number,
  totalCost: number,
  totalTokens: number
): CostMetrics {
  const cacheHitRate = totalRequests > 0 ? cachedRequests / totalRequests : 0;
  const avgTokensPerRequest = totalRequests > 0 ? totalTokens / totalRequests : 0;
  const avgCostPerWorkflow = totalRequests > 0 ? totalCost / totalRequests : 0;

  // Project monthly cost (assume 30 days)
  const dailyAvgCost = totalCost / 7; // 7-day average
  const monthlyProjection = dailyAvgCost * 30;

  return {
    cacheHitRate,
    avgTokensPerRequest,
    avgCostPerWorkflow,
    monthlyProjection
  };
}
```

---

## Additional Resources

### Official Documentation
- [Azure OpenAI REST API Reference](https://learn.microsoft.com/en-us/azure/ai-services/openai/reference)
- [Azure OpenAI Quotas and Limits](https://learn.microsoft.com/en-us/azure/ai-services/openai/quotas-limits)
- [Azure OpenAI Models](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models)

### Brookside BI Resources
- **Integration Guide**: [integration-guide.md](./integration-guide.md)
- **Security & Compliance**: [security-compliance.md](./security-compliance.md)
- **Cost Optimization**: [cost-optimization.md](./cost-optimization.md)
- **Operations Runbook**: [operations.md](./operations.md)

### Support
- **Email**: consultations@brooksidebi.com
- **Phone**: +1 209 487 2047
- **GitHub Issues**: https://github.com/brookside-bi/innovation-nexus/issues

---

**Document Version**: 1.0.0
**API Version**: 2024-02-15-preview
**Last Reviewed**: 2025-10-26
**Owner**: Brookside BI Engineering Team

*This API reference establishes comprehensive technical specifications for Azure OpenAI integration, enabling developers to implement robust, cost-optimized API interactions with enterprise-grade error handling and monitoring.*
