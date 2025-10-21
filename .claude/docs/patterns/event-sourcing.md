# Event Sourcing Pattern

**Best for**: Organizations requiring comprehensive audit trails for compliance, governance, and temporal analysis to support regulatory requirements and enable data-driven decision making.

## Problem Statement

Traditional CRUD operations lose historical context. When Software Tracker status changes from "Active" to "Cancelled", the previous state vanishes. Compliance auditors ask "when did this happen?" and "who approved it?" but the data is gone.

**Business Impact**:
- Cannot prove GDPR compliance (right to deletion timeline)
- No audit trail for cost optimization decisions
- Lost innovation velocity metrics (idea-to-build time)
- Impossible to reconstruct system state for incident analysis

## When to Use

✅ **Use Event Sourcing When:**
- **Compliance requirements**: GDPR, SOC2, CCPA demand complete audit trails
- **Financial auditing**: Software spend tracking with change history
- **Temporal queries**: "Show costs in Q1 2024" or "Ideas created last month"
- **Complex state machines**: Idea lifecycle with multiple status transitions
- **Event-driven architecture**: Already using events for integration

❌ **Don't Use Event Sourcing When:**
- **Simple CRUD**: Basic contact management with no audit requirements
- **No temporal queries**: Never need historical state reconstruction
- **Storage-constrained**: Event log growth prohibitive
- **Team lacks expertise**: Learning curve slows delivery
- **Read-heavy workload**: Projections add complexity without benefit

## How It Works

### Traditional CRUD (State-Oriented)

```sql
-- Current state only
UPDATE software_tracker
SET status = 'Cancelled',
    cancelled_date = '2025-01-15'
WHERE id = 123;

-- Previous status LOST FOREVER
-- Can't answer: When was it Active? Who cancelled it? Why?
```

### Event Sourcing (Event-Oriented)

```typescript
// Immutable event log
const events = [
  { type: 'SoftwareAdded', timestamp: '2024-06-01', data: { name: 'GitHub Enterprise', cost: 21, status: 'Trial' } },
  { type: 'StatusChanged', timestamp: '2024-07-01', data: { from: 'Trial', to: 'Active', approvedBy: 'Markus' } },
  { type: 'CostUpdated', timestamp: '2024-09-15', data: { from: 21, to: 18, reason: 'Negotiated discount' } },
  { type: 'LicenseCountChanged', timestamp: '2024-11-20', data: { from: 5, to: 8, reason: 'Team growth' } },
  { type: 'StatusChanged', timestamp: '2025-01-15', data: { from: 'Active', to: 'Cancelled', approvedBy: 'Brad', reason: 'Migrating to Microsoft alternatives' } }
];

// Current state = replay all events
const currentState = events.reduce((state, event) => applyEvent(state, event), {});
// Result: { name: 'GitHub Enterprise', cost: 18, licenseCount: 8, status: 'Cancelled' }

// Historical state = replay events up to timestamp
const stateOn20241001 = events
  .filter(e => e.timestamp <= '2024-10-01')
  .reduce((state, event) => applyEvent(state, event), {});
// Result: { name: 'GitHub Enterprise', cost: 18, licenseCount: 5, status: 'Active' }
```

## Core Concepts

### Event Store (Append-Only Log)

**Properties**:
- **Immutable**: Events never updated or deleted (audit integrity)
- **Chronological**: Ordered by timestamp for replay
- **Complete history**: Every state change recorded
- **Source of truth**: Current state derived from events

**Azure Implementation Options**:
- Cosmos DB with change feed (native event sourcing)
- Azure Event Hubs (high-throughput event ingestion)
- Azure SQL temporal tables (lightweight alternative)
- Azure Table Storage (cost-effective for moderate scale)

### Event Replay (State Reconstruction)

Rebuild current state by applying events in order:

```typescript
function rebuildState(events: Event[]): SoftwareState {
  return events.reduce((state, event) => {
    switch (event.type) {
      case 'SoftwareAdded':
        return { ...event.data };

      case 'StatusChanged':
        return { ...state, status: event.data.to };

      case 'CostUpdated':
        return { ...state, cost: event.data.to };

      case 'LicenseCountChanged':
        return { ...state, licenseCount: event.data.to };

      default:
        return state;
    }
  }, {} as SoftwareState);
}
```

### Projections (Read Models)

Denormalized views optimized for queries:

```typescript
// Projection: Current software list (fast reads)
const currentSoftware = events
  .filter(e => e.type === 'SoftwareAdded')
  .map(e => rebuildState(eventsForSoftware(e.data.id)));

// Projection: Monthly cost trend (analytics)
const monthlyCosts = groupBy(
  events.filter(e => e.type === 'CostUpdated'),
  e => e.timestamp.substring(0, 7) // YYYY-MM
);

// Projection: Audit trail (compliance)
const auditLog = events.map(e => ({
  timestamp: e.timestamp,
  action: e.type,
  user: e.data.approvedBy || 'system',
  details: JSON.stringify(e.data)
}));
```

### Snapshots (Performance Optimization)

Periodic checkpoints to avoid replaying thousands of events:

```typescript
// Snapshot every 100 events
const snapshot = {
  softwareId: 123,
  eventSequence: 500,
  state: { /* current state at event 500 */ },
  timestamp: '2024-12-31'
};

// Rebuild state = Load snapshot + replay events since snapshot
const currentState = applyEvents(
  snapshot.state,
  events.filter(e => e.sequence > 500)
);
```

## Innovation Nexus Applications

### Application 1: Idea Lifecycle Tracking

**Events**:
```typescript
[
  { type: 'IdeaCaptured', timestamp: '2024-08-01', data: { title: 'AI Cost Optimizer', champion: 'Markus', viability: 'Needs Research' } },
  { type: 'ChampionReassigned', timestamp: '2024-08-05', data: { from: 'Markus', to: 'Alec', reason: 'AI/ML specialization' } },
  { type: 'ViabilityAssessed', timestamp: '2024-08-20', data: { from: 'Needs Research', to: 'High', assessedBy: 'Stephan' } },
  { type: 'ResearchStarted', timestamp: '2024-08-22', data: { researchId: 456, researchers: ['Alec', 'Mitch'] } },
  { type: 'ViabilityUpdated', timestamp: '2024-09-15', data: { from: 'High', to: 'Highly Viable', findings: 'Azure OpenAI API supports use case' } },
  { type: 'BuildCreated', timestamp: '2024-09-20', data: { buildId: 789, buildType: 'Prototype' } },
  { type: 'IdeaArchived', timestamp: '2024-11-01', data: { reason: 'Successful build completed', outcome: 'Production Ready' } }
]
```

**Business Value Queries**:

```typescript
// Time from idea to build
const ideaToBuildTime = events.find(e => e.type === 'BuildCreated').timestamp -
                         events.find(e => e.type === 'IdeaCaptured').timestamp;
// Result: 50 days → Identify bottlenecks

// Viability assessment accuracy
const initialViability = events.find(e => e.type === 'IdeaCaptured').data.viability;
const finalViability = events.find(e => e.type === 'IdeaArchived').data.outcome;
// Track: Did "Needs Research" ideas become "Production Ready"?

// Champion effectiveness
const ideasByChampion = groupBy(events.filter(e => e.type === 'IdeaCaptured'), e => e.data.champion);
const successRateByChampion = calculateSuccessRate(ideasByChampion);
// Identify: Which champions drive most successful outcomes?
```

### Application 2: Software Cost History & Forecasting

**Events**:
```typescript
[
  { type: 'SoftwareAdded', timestamp: '2024-01-15', data: { name: 'Azure OpenAI', cost: 100, licenseCount: 1 } },
  { type: 'CostIncreased', timestamp: '2024-03-01', data: { from: 100, to: 250, reason: 'Increased API usage' } },
  { type: 'LicenseCountIncreased', timestamp: '2024-05-15', data: { from: 1, to: 3, reason: 'Team expansion' } },
  { type: 'CostDecreased', timestamp: '2024-08-01', data: { from: 250, to: 180, reason: 'Committed use discount' } },
  { type: 'BuildLinked', timestamp: '2024-09-10', data: { buildId: 789, buildName: 'AI Cost Optimizer' } },
  { type: 'UsageIncreased', timestamp: '2024-10-15', data: { tokens: '5M → 15M', reason: 'Production deployment' } }
]
```

**Business Value Queries**:

```typescript
// Monthly cost trend
const monthlyCosts = events
  .filter(e => ['CostIncreased', 'CostDecreased'].includes(e.type))
  .reduce((trend, event) => {
    const month = event.timestamp.substring(0, 7);
    trend[month] = event.data.to * licenseCountAt(event.timestamp);
    return trend;
  }, {});
// Result: { '2024-01': 100, '2024-03': 250, '2024-05': 750, '2024-08': 540 }

// Cost forecast (linear regression on historical events)
const forecastedCost = linearRegression(monthlyCosts);
// Predict: Next quarter's Azure OpenAI spend

// ROI calculation
const totalSpend = sumCosts(events);
const buildsUsingService = events.filter(e => e.type === 'BuildLinked').length;
const costPerBuild = totalSpend / buildsUsingService;
// Result: Azure OpenAI cost $X per build → Justify continued investment

// Contract renewal optimization
const costChanges = events.filter(e => e.type.includes('Cost'));
const avgMonthlyChange = calculateAvgChange(costChanges);
// Negotiate: "Usage decreased 30% after committed use discount"
```

### Application 3: Compliance Audit Trail (GDPR, SOC2)

**Events for Data Classification Changes**:
```typescript
[
  { type: 'KnowledgeVaultEntryCreated', timestamp: '2024-06-01', data: { title: 'Customer Insights Analysis', dataClassification: 'Internal' } },
  { type: 'DataClassificationChanged', timestamp: '2024-06-15', data: { from: 'Internal', to: 'Confidential', reason: 'Contains PII', approvedBy: 'Brad' } },
  { type: 'AccessGranted', timestamp: '2024-06-20', data: { user: 'Stephan', role: 'Viewer', approvedBy: 'Markus' } },
  { type: 'DataExported', timestamp: '2024-07-10', data: { exportedBy: 'Stephan', destination: 'sharepoint://research-docs', purpose: 'Analysis' } },
  { type: 'AccessRevoked', timestamp: '2024-08-01', data: { user: 'Stephan', reason: 'Project completed', revokedBy: 'Markus' } },
  { type: 'DataRetentionPolicyApplied', timestamp: '2024-12-01', data: { retentionPeriod: '7 years', reason: 'Regulatory requirement' } }
]
```

**Compliance Queries**:

```typescript
// GDPR Article 30: Record of processing activities
const processingActivities = events
  .filter(e => ['DataExported', 'AccessGranted', 'DataClassificationChanged'].includes(e.type))
  .map(e => ({
    timestamp: e.timestamp,
    activity: e.type,
    personalData: e.data.dataClassification === 'Confidential',
    legalBasis: determineLegalBasis(e),
    dataSubjects: extractDataSubjects(e)
  }));

// GDPR Article 17: Right to deletion timeline
const deletionTimeline = events
  .filter(e => e.type === 'DataDeletionRequested')
  .map(e => {
    const deletedEvent = events.find(
      ev => ev.type === 'DataDeleted' && ev.data.requestId === e.data.requestId
    );
    return {
      requested: e.timestamp,
      completed: deletedEvent?.timestamp,
      withinCompliance: (deletedEvent.timestamp - e.timestamp) <= 30 * 24 * 60 * 60 * 1000 // 30 days
    };
  });
// Prove: All deletion requests processed within 30 days

// SOC2: Access control changes
const accessAuditLog = events
  .filter(e => ['AccessGranted', 'AccessRevoked', 'PermissionChanged'].includes(e.type))
  .map(e => ({
    timestamp: e.timestamp,
    user: e.data.user,
    action: e.type,
    approver: e.data.approvedBy || e.data.revokedBy,
    justification: e.data.reason
  }));
// Demonstrate: All access changes require approval and justification
```

## Benefits

- **Complete audit trail**: Every state change recorded with timestamp and actor
- **Temporal queries**: Answer "what was state on date X?" instantly
- **Compliance proof**: Meet GDPR, SOC2, CCPA audit requirements
- **Debugging**: Reproduce bugs by replaying events to failure point
- **Business intelligence**: Analyze trends (idea velocity, cost trends, viability accuracy)
- **Event-driven architecture**: Natural fit for reactive systems

## Tradeoffs

- **Storage cost**: Events accumulate indefinitely (mitigation: retention policies, archival)
- **Complexity**: More complex than traditional CRUD
- **Learning curve**: Team needs event-driven mindset
- **Eventual consistency**: Projections updated asynchronously
- **Query performance**: Replaying many events slower than direct reads (mitigation: snapshots, projections)

## Microsoft Azure Implementation

### Cosmos DB with Change Feed (Recommended)

```csharp
// Event store container
var events = cosmosClient.GetContainer("innovation-nexus", "event-store");

// Append event (immutable)
await events.CreateItemAsync(new Event
{
    Id = Guid.NewGuid().ToString(),
    AggregateId = "software-123",
    Type = "CostUpdated",
    Timestamp = DateTime.UtcNow,
    Data = new { From = 100, To = 120, Reason = "License increase" },
    Actor = "Markus"
});

// Rebuild state from events
var softwareEvents = events
    .GetItemLinqQueryable<Event>()
    .Where(e => e.AggregateId == "software-123")
    .OrderBy(e => e.Timestamp);

var currentState = await RebuildState(softwareEvents);

// Change feed for projections
var processor = events.GetChangeFeedProcessorBuilder<Event>(
    "projection-processor",
    (changes, cancellationToken) =>
    {
        foreach (var e in changes)
        {
            await UpdateProjection(e); // Update read model
        }
    })
    .Build();

await processor.StartAsync();
```

### Azure SQL Temporal Tables (Lightweight Alternative)

```sql
-- Create temporal table (automatic history tracking)
CREATE TABLE SoftwareTracker (
    Id INT PRIMARY KEY,
    Name NVARCHAR(100),
    Cost DECIMAL(10,2),
    Status NVARCHAR(50),
    ValidFrom DATETIME2 GENERATED ALWAYS AS ROW START,
    ValidTo DATETIME2 GENERATED ALWAYS AS ROW END,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON);

-- Query current state
SELECT * FROM SoftwareTracker WHERE Id = 123;

-- Query historical state (point-in-time)
SELECT * FROM SoftwareTracker
FOR SYSTEM_TIME AS OF '2024-10-01'
WHERE Id = 123;

-- Query all changes over time range
SELECT * FROM SoftwareTracker
FOR SYSTEM_TIME BETWEEN '2024-01-01' AND '2024-12-31'
WHERE Id = 123;
```

### Azure Event Hubs (High-Throughput Event Ingestion)

For high-volume event sourcing (thousands of events/second):

```csharp
var eventHubClient = new EventHubProducerClient(connectionString, eventHubName);

// Publish event
var eventData = new EventData(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(new
{
    Type = "CostUpdated",
    AggregateId = "software-123",
    Data = new { From = 100, To = 120 }
})));

await eventHubClient.SendAsync(new[] { eventData });

// Process events with Azure Stream Analytics or Azure Functions
```

## When to Use vs. Alternatives

| Requirement | Event Sourcing | Alternative |
|-------------|----------------|-------------|
| **Audit trail required** | ✅ Perfect fit | Change Data Capture (CDC) |
| **Temporal queries** | ✅ Native support | SQL temporal tables (simpler) |
| **Compliance (GDPR, SOC2)** | ✅ Meets requirements | Audit log table |
| **Event-driven architecture** | ✅ Natural fit | Traditional CRUD with events |
| **Simple CRUD app** | ❌ Overkill | Traditional database |
| **Read-heavy workload** | ⚠️ Use projections | CQRS with read models |
| **Storage-constrained** | ❌ Events accumulate | Soft deletes with snapshots |

## Monitoring & Observability

### Metrics to Track

- **Event ingestion rate**: Events/second written to store
- **Projection lag**: Time between event and projection update
- **Replay performance**: Time to rebuild state from events
- **Storage growth**: Event store size over time
- **Snapshot frequency**: How often snapshots created

### Retention Policies

```typescript
// Archive old events to Azure Blob Storage
const retentionPolicy = {
  hotTier: '1 year',     // Cosmos DB (fast access)
  coolTier: '3 years',   // Azure Blob Storage (audit access)
  archiveTier: '7 years' // Azure Archive Storage (compliance)
};

// Automated archival
async function archiveOldEvents() {
  const cutoffDate = new Date();
  cutoffDate.setFullYear(cutoffDate.getFullYear() - 1);

  const oldEvents = await eventsContainer
    .query({ query: 'SELECT * FROM c WHERE c.timestamp < @cutoff', parameters: [{ name: '@cutoff', value: cutoffDate }] })
    .fetchAll();

  // Move to Blob Storage
  await blobClient.uploadBatch(oldEvents);

  // Delete from Cosmos DB (cost optimization)
  await eventsContainer.deleteBatch(oldEvents.map(e => e.id));
}
```

## Related Patterns

- **CQRS**: Separate read (projections) and write (events) models
- **Saga Pattern**: Event-driven orchestration across services
- **Snapshot Pattern**: Optimize replay performance
- **Outbox Pattern**: Reliable event publishing to external systems

## References

- [Azure Architecture Center: Event Sourcing Pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing)
- [Martin Fowler: Event Sourcing](https://martinfowler.com/eaaDev/EventSourcing.html)
- [Azure Cosmos DB Change Feed](https://learn.microsoft.com/en-us/azure/cosmos-db/change-feed)
- [SQL Server Temporal Tables](https://learn.microsoft.com/en-us/sql/relational-databases/tables/temporal-tables)

---

**Status**: Reference Documentation
**Content Type**: Technical Pattern
**Evergreen**: Yes (timeless architectural pattern)
**Reusability**: Highly Reusable for compliance-critical Innovation Nexus workflows
