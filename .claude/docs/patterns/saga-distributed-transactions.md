# Saga Pattern for Distributed Transactions

**Best for**: Organizations scaling multi-system workflows across Notion, GitHub, and Azure that require data consistency without distributed transactions to ensure reliable operations.

## Problem Statement

Innovation Nexus workflows span multiple platforms (Notion databases, GitHub repositories, Azure resources). Traditional ACID transactions don't exist across these systems. Partial failures leave inconsistent state: Notion entry created but GitHub repo failed, or Azure resources provisioned but cost tracking incomplete.

**Business Impact**:
- Orphaned resources increase Azure costs
- Incomplete build entries create confusion
- Manual cleanup wastes team time
- Lost audit trail for compliance

## When to Use

- **Multi-system workflows**: Operations spanning Notion + GitHub + Azure
- **No ACID support**: External APIs don't support distributed transactions
- **Compensation possible**: Each step has clear rollback action
- **Eventual consistency acceptable**: Don't need immediate consistency

## Saga Types

### Orchestration Saga (Recommended for Innovation Nexus)

**Central coordinator** manages the workflow, explicitly controls execution order.

**Advantages**:
- Clear visibility into workflow state
- Easier debugging and monitoring
- Centralized error handling
- Better for complex workflows with branches

**Innovation Nexus Use Case**: Build creation workflow with multiple Azure services

### Choreography Saga

**Event-driven**, each service knows what to do when events occur.

**Advantages**:
- Loosely coupled services
- Natural event-driven architecture
- Scales well for simple workflows

**Innovation Nexus Use Case**: Research completion triggering Knowledge Vault entry

## How It Works

### Forward Transactions

Each step in saga executes forward transaction:

```
Step 1: Create Notion Build entry
Step 2: Create GitHub repository
Step 3: Provision Azure App Service
Step 4: Link Software & Cost Tracker
Step 5: Create Integration Registry entry
```

### Compensation Transactions

If any step fails, execute compensations in **reverse order**:

```
Step 5 failed → Compensate Steps 4, 3, 2, 1
Step 3 failed → Compensate Steps 2, 1
Step 1 failed → No compensation needed
```

### Compensation Design Principles

**Idempotent**: Can run multiple times safely
```typescript
// Good: Check existence before deleting
async compensate() {
  const repo = await github.repos.get(repoName);
  if (repo) await github.repos.delete(repoName);
}

// Bad: Assumes repo exists
async compensate() {
  await github.repos.delete(repoName); // Fails if already deleted
}
```

**Compensating**: Undoes the effect (not just reverses action)
```typescript
// Good: Semantic compensation
async compensate() {
  // Forward: CreateBuild(status='Active')
  // Compensate: UpdateBuild(status='Cancelled', reason='Saga rollback')
  await notion.pages.update({
    page_id: buildId,
    properties: {
      Status: { status: { name: 'Cancelled' } },
      Notes: { rich_text: [{ text: { content: 'Rollback due to GitHub creation failure' } }] }
    }
  });
}

// Bad: Just deletes (loses audit trail)
async compensate() {
  await notion.pages.delete(buildId);
}
```

**Retryable**: Can be retried if compensation fails
```typescript
async compensate() {
  // Use retry-with-backoff for compensation
  return await retryWithBackoff(
    async () => {
      await azureClient.resourceGroups.beginDelete(resourceGroupName);
    },
    { maxRetries: 5, baseDelay: 2000 }
  );
}
```

## Innovation Nexus Applications

### Example 1: Build Creation Saga

**Workflow**: Create Example Build with full ecosystem setup

**Steps**:
```typescript
const buildCreationSaga = {
  steps: [
    {
      name: 'Create Notion Build Entry',
      execute: async () => {
        const page = await notion.pages.create({
          parent: { database_id: BUILDS_DB_ID },
          properties: {
            Name: { title: [{ text: { content: buildName } }] },
            Status: { status: { name: 'Concept' } },
            'Build Type': { select: { name: buildType } }
          }
        });
        return { buildId: page.id };
      },
      compensate: async (context) => {
        await notion.pages.update({
          page_id: context.buildId,
          properties: {
            Status: { status: { name: 'Cancelled' } },
            Notes: { rich_text: [{ text: { content: 'Saga rollback' } }] }
          }
        });
      }
    },
    {
      name: 'Create GitHub Repository',
      execute: async (context) => {
        const repo = await github.repos.create({
          name: repoName,
          description: buildDescription,
          private: true
        });
        return { ...context, repoUrl: repo.html_url };
      },
      compensate: async (context) => {
        await github.repos.delete({ repo: repoName });
      }
    },
    {
      name: 'Provision Azure Resources',
      execute: async (context) => {
        // Create Resource Group
        await azure.resourceGroups.createOrUpdate(rgName, { location });

        // Create App Service Plan
        await azure.appServicePlans.createOrUpdate(planName, { ... });

        // Create Web App
        const app = await azure.webApps.createOrUpdate(appName, { ... });

        return { ...context, azureResourceGroup: rgName, appUrl: app.defaultHostName };
      },
      compensate: async (context) => {
        // Delete entire resource group (cascades to all resources)
        await azure.resourceGroups.beginDelete(context.azureResourceGroup);
      }
    },
    {
      name: 'Link Software & Costs',
      execute: async (context) => {
        // Query Software Tracker for linked tools
        const software = await querySoftwareForBuild(buildRequirements);

        // Create relations
        await notion.pages.update({
          page_id: context.buildId,
          properties: {
            'Software & Tools': {
              relation: software.map(s => ({ id: s.id }))
            }
          }
        });

        return { ...context, linkedSoftware: software };
      },
      compensate: async (context) => {
        // Remove relations
        await notion.pages.update({
          page_id: context.buildId,
          properties: {
            'Software & Tools': { relation: [] }
          }
        });
      }
    },
    {
      name: 'Create Integration Registry Entry',
      execute: async (context) => {
        const integration = await notion.pages.create({
          parent: { database_id: INTEGRATION_REGISTRY_DB_ID },
          properties: {
            Name: { title: [{ text: { content: `${buildName} Integration` } }] },
            'Integration Type': { select: { name: 'Azure Deployment' } },
            'Authentication Method': { select: { name: 'Managed Identity' } },
            'Related Builds': { relation: [{ id: context.buildId }] }
          }
        });

        return { ...context, integrationId: integration.id };
      },
      compensate: async (context) => {
        await notion.pages.update({
          page_id: context.integrationId,
          archived: true
        });
      }
    }
  ]
};
```

**Execution**:
```typescript
async function executeBuildCreationSaga() {
  const sagaState = { completedSteps: [], context: {} };

  try {
    for (const step of buildCreationSaga.steps) {
      console.log(`Executing: ${step.name}`);

      // Execute forward transaction
      sagaState.context = await step.execute(sagaState.context);
      sagaState.completedSteps.push(step);

      console.log(`✓ ${step.name} completed`);
    }

    return { success: true, context: sagaState.context };

  } catch (error) {
    console.error(`✗ Saga failed at: ${sagaState.completedSteps.length + 1}`);
    console.log('Starting compensation...');

    // Execute compensations in reverse order
    for (const step of sagaState.completedSteps.reverse()) {
      try {
        await step.compensate(sagaState.context);
        console.log(`↺ Compensated: ${step.name}`);
      } catch (compError) {
        console.error(`Failed to compensate ${step.name}:`, compError);
        // Log for manual intervention
        await logManualCompensationRequired(step.name, sagaState.context);
      }
    }

    return { success: false, error, context: sagaState.context };
  }
}
```

**Failure Scenarios**:

**Scenario A: GitHub creation fails (Step 2)**
```
✓ Step 1: Create Notion Build Entry → buildId=123
✗ Step 2: Create GitHub Repository → FAILED (rate limit exceeded)
↺ Compensate Step 1 → Update buildId=123 status='Cancelled'
Result: Clean state, no orphaned resources
```

**Scenario B: Azure provisioning fails (Step 3)**
```
✓ Step 1: Create Notion Build Entry → buildId=123
✓ Step 2: Create GitHub Repository → repoUrl=github.com/org/repo
✗ Step 3: Provision Azure Resources → FAILED (quota exceeded)
↺ Compensate Step 2 → Delete GitHub repository
↺ Compensate Step 1 → Update buildId=123 status='Cancelled'
Result: Clean state, GitHub repo deleted, Notion entry marked cancelled
```

### Example 2: Research to Build Transition Saga

**Workflow**: Complete research and transition to build phase

**Steps**:
1. Update Research status → 'Completed'
2. Create Example Build from research findings
3. Link research to build (bidirectional relation)
4. Copy software relations from research to build
5. Create Knowledge Vault entry with research findings
6. Archive research thread

**Compensation Strategy**:
- If Step 4 fails → Remove build-research link, delete build, revert research status
- Preserves research findings even if build creation fails
- Maintains audit trail of transition attempt

### Example 3: Cost Optimization Saga

**Workflow**: Cancel unused software and update all relations

**Steps**:
1. Identify unused software (no active relations)
2. Create cancellation request in Software Tracker
3. Remove all historical relations to software
4. Update status → 'Cancelled'
5. Calculate realized savings
6. Create Knowledge Vault entry documenting savings

**Compensation Strategy**:
- If Step 3 fails → Restore relations, revert cancellation request
- Preserves cost history if cancellation incomplete
- Prevents data loss during optimization

## Benefits

- **Data consistency**: Eventual consistency across distributed systems
- **Automatic recovery**: No manual cleanup required
- **Audit trail**: Complete history of saga execution and compensations
- **Resilience**: Failures don't leave orphaned resources
- **Cost control**: Prevents runaway Azure spending from partial deployments

## Tradeoffs

- **Eventual consistency**: Not immediate (compensations take time)
- **Complexity**: More code than simple try/catch
- **Compensation design**: Requires careful thought about rollback logic
- **Partial visibility**: Temporary inconsistent state during execution
- **No isolation**: Other operations may see intermediate state

## Microsoft Azure Implementation

### Azure Durable Functions (Recommended)

```csharp
[FunctionName("BuildCreationSaga")]
public static async Task<bool> RunSaga(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var buildRequest = context.GetInput<BuildRequest>();
    var sagaState = new SagaState();

    try
    {
        // Step 1: Create Notion entry
        sagaState.BuildId = await context.CallActivityAsync<string>(
            "CreateNotionBuild", buildRequest);

        // Step 2: Create GitHub repo
        sagaState.RepoUrl = await context.CallActivityAsync<string>(
            "CreateGitHubRepo", buildRequest);

        // Step 3: Provision Azure resources
        sagaState.ResourceGroup = await context.CallActivityAsync<string>(
            "ProvisionAzureResources", buildRequest);

        // Step 4: Link costs
        await context.CallActivityAsync(
            "LinkSoftwareCosts", sagaState);

        return true;
    }
    catch (Exception ex)
    {
        // Compensate in reverse order
        if (sagaState.ResourceGroup != null)
            await context.CallActivityAsync("DeleteResourceGroup", sagaState.ResourceGroup);

        if (sagaState.RepoUrl != null)
            await context.CallActivityAsync("DeleteGitHubRepo", sagaState.RepoUrl);

        if (sagaState.BuildId != null)
            await context.CallActivityAsync("CancelNotionBuild", sagaState.BuildId);

        return false;
    }
}
```

### Azure Logic Apps (Low-Code Alternative)

- Use "Scope" actions for each saga step
- Configure "Configure run after" for compensation logic
- Built-in retry and error handling
- Visual saga design for non-developers

## Monitoring & Observability

### Metrics to Track (Application Insights)

- **Saga completion rate**: % sagas that complete successfully
- **Compensation frequency**: How often rollbacks occur
- **Step failure distribution**: Which steps fail most often
- **Mean time to compensate**: How long rollbacks take
- **Manual intervention rate**: Compensations that require human help

### Saga State Persistence

Store saga execution state for recovery after crashes:

```typescript
interface SagaState {
  sagaId: string;
  status: 'running' | 'completed' | 'compensating' | 'failed';
  currentStep: number;
  completedSteps: string[];
  context: Record<string, any>;
  startTime: Date;
  endTime?: Date;
  error?: string;
}

// Persist to Cosmos DB or Azure Table Storage
await cosmosClient.container('saga-state').items.create(sagaState);
```

## Related Patterns

- **Event Sourcing**: Saga execution as events for complete audit trail
- **CQRS**: Separate read/write models for saga state
- **Retry with Backoff**: Use for transient failures within saga steps
- **Circuit-Breaker**: Prevent saga execution when dependencies unavailable
- **Outbox Pattern**: Ensure reliable event publishing from saga steps

## References

- [Azure Architecture Center: Saga Pattern](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga)
- [Azure Durable Functions: Saga Pattern](https://learn.microsoft.com/en-us/azure/azure-functions/durable/durable-functions-overview)
- [Microservices.io: Saga Pattern](https://microservices.io/patterns/data/saga.html)

---

**Status**: Reference Documentation
**Content Type**: Technical Pattern
**Evergreen**: Yes (timeless distributed systems pattern)
**Reusability**: Highly Reusable for all multi-system Innovation Nexus workflows
