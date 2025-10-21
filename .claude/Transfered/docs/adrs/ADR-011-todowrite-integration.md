# ADR-011: TodoWrite Integration

## Status

**Accepted** - December 2024

## Context

The Claude Code Orchestration system executes complex multi-agent commands that can take several minutes to complete. Users need visibility into:

### User Experience Problems

1. **Black Box Execution**: Users don't know what's happening during long-running commands
2. **No Progress Indication**: Cannot estimate remaining time or see current status
3. **Unclear Dependencies**: Don't understand why certain tasks are running
4. **Lost Context**: After interruption, unclear what was completed
5. **No Actionable Feedback**: Can't see which specific agent or task failed

### Current State

The TodoWrite tool is already part of Claude's toolkit, providing:
- Hierarchical task management
- Real-time status updates (pending, in_progress, completed)
- Visual progress indication
- Familiar UX that users already understand

### Requirements

- Provide real-time visibility into command execution
- Show hierarchical task structure (phases → agents → subtasks)
- Update status as execution progresses
- Handle dynamic task addition/removal
- Support nested task hierarchies
- Gracefully degrade if TodoWrite unavailable

### Constraints

- Cannot modify TodoWrite tool itself
- Must work with existing TodoWrite API
- Updates must not slow down execution
- Must handle TodoWrite failures gracefully
- Limited to TodoWrite's status states

## Decision

We will **deeply integrate TodoWrite** as the primary progress visualization mechanism for command orchestration.

### Integration Architecture

```typescript
interface TodoWriteIntegration {
  // Automatic todo generation from DAG
  generateTodos(dag: DAG): Todo[]

  // Real-time updates
  onNodeStart(nodeId: string): void
  onNodeComplete(nodeId: string): void
  onNodeFailed(nodeId: string, error: Error): void

  // Periodic sync
  syncProgress(): void
}
```

### Todo Structure Mapping

```typescript
// Command → Phase → Agents hierarchy
interface TodoHierarchy {
  command: {
    content: "Execute build-fullstack command",
    activeForm: "Executing build-fullstack command",
    status: "in_progress",
    children: [
      {
        content: "Phase 1: Requirements Analysis",
        activeForm: "Analyzing requirements",
        status: "completed",
        children: [
          {
            content: "Run architect agent",
            activeForm: "Running architect agent",
            status: "completed"
          }
        ]
      },
      {
        content: "Phase 2: Implementation",
        activeForm: "Implementing components",
        status: "in_progress",
        children: [
          {
            content: "Build frontend with React",
            activeForm: "Building frontend with React",
            status: "in_progress"
          },
          {
            content: "Build backend API",
            activeForm: "Building backend API",
            status: "pending"
          }
        ]
      }
    ]
  }
}
```

### Auto-Generation Algorithm

```typescript
function generateTodosFromDAG(dag: DAG): Todo[] {
  const todos: Todo[] = []

  // Group nodes by phase
  const phases = groupNodesByPhase(dag.nodes)

  for (const [phaseName, nodes] of phases) {
    const phaseTodo: Todo = {
      content: `Phase ${phaseIndex}: ${phaseName}`,
      activeForm: `Executing ${phaseName}`,
      status: 'pending',
      children: []
    }

    // Add agent tasks as children
    for (const node of nodes) {
      phaseTodo.children.push({
        content: `Run ${node.agentType} agent`,
        activeForm: `Running ${node.agentType} agent`,
        status: 'pending'
      })
    }

    todos.push(phaseTodo)
  }

  return todos
}
```

### Real-Time Update Strategy

1. **Event-Driven Updates**
   ```typescript
   class ProgressTracker {
     constructor(private todoWrite: TodoWriteAPI) {
       this.eventEmitter.on('node:start', this.handleNodeStart)
       this.eventEmitter.on('node:complete', this.handleNodeComplete)
       this.eventEmitter.on('node:error', this.handleNodeError)
     }

     handleNodeStart(nodeId: string) {
       const todo = this.findTodoByNodeId(nodeId)
       todo.status = 'in_progress'
       this.updateImmediate()
     }
   }
   ```

2. **Batched Updates**
   ```typescript
   class BatchedUpdater {
     private pendingUpdates: Map<string, TodoUpdate> = new Map()
     private updateInterval: number = 1000  // 1 second

     scheduleUpdate(todoId: string, update: TodoUpdate) {
       this.pendingUpdates.set(todoId, update)
     }

     async flush() {
       if (this.pendingUpdates.size === 0) return

       const updates = Array.from(this.pendingUpdates.values())
       await this.todoWrite.batchUpdate(updates)
       this.pendingUpdates.clear()
     }
   }
   ```

3. **Graceful Degradation**
   ```typescript
   class SafeTodoWriter {
     async update(todos: Todo[]) {
       try {
         await this.todoWrite.update(todos)
       } catch (error) {
         console.warn('TodoWrite update failed, continuing execution', error)
         // Fall back to console progress
         this.logProgress(todos)
       }
     }
   }
   ```

## Alternatives Considered

### 1. Custom Progress UI

**Pros:**
- Full control over visualization
- Rich interactive features
- Custom styling and branding

**Cons:**
- Significant development effort
- Separate UI to maintain
- Users need to learn new interface
- Not integrated with Claude's environment

**Why Rejected:** TodoWrite already provides a familiar, integrated solution

### 2. Log-Based Progress

**Pros:**
- Simple to implement
- No dependencies
- Always works

**Cons:**
- Poor user experience
- No hierarchical view
- Hard to track overall progress
- Logs get buried in output

**Why Rejected:** Insufficient visualization for complex multi-agent workflows

### 3. External Progress Service

**Pros:**
- Rich features (Datadog, New Relic)
- Professional monitoring
- Historical tracking

**Cons:**
- External dependency
- Complex integration
- Cost implications
- Network latency

**Why Rejected:** Overkill for command execution progress

### 4. No Progress Tracking

**Pros:**
- Simplest approach
- No overhead
- No dependencies

**Cons:**
- Terrible user experience
- No visibility into execution
- Can't debug issues
- Users abandon long-running commands

**Why Rejected:** Unacceptable user experience for multi-minute executions

## Consequences

### Positive Consequences

1. **User Experience**
   - 100% visibility into execution progress
   - Clear understanding of what's running
   - Estimated time remaining from completed vs. pending tasks
   - Familiar interface users already know

2. **Debugging**
   - Immediately see which agent failed
   - Track execution timeline
   - Understand dependency chains
   - Identify performance bottlenecks

3. **Integration Benefits**
   - No custom UI needed
   - Leverages existing tool
   - Automatic persistence of progress
   - Works in all Claude environments

4. **Developer Experience**
   - Simple API to update progress
   - Automatic generation from DAG
   - No manual progress management

### Negative Consequences

1. **Dependency on TodoWrite**
   - Execution tied to external tool
   - Must handle API changes
   - Need graceful degradation

2. **Performance Overhead**
   - API calls for updates
   - Serialization costs
   - Network latency (minimal)

3. **Limited Customization**
   - Restricted to TodoWrite's features
   - Cannot add custom visualizations
   - Fixed status states

### Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **TodoWrite API Changes** | High - Breaking integration | Adapter pattern, version detection |
| **Update Frequency Limits** | Low - Throttling | Batched updates, rate limiting |
| **TodoWrite Unavailable** | Medium - No progress | Graceful degradation to logs |
| **Large Task Lists** | Low - Performance | Pagination, hierarchical collapse |
| **Sync Issues** | Low - Incorrect status | Periodic full sync, validation |

## Validation

### Success Metrics

1. **Visibility**: 100% of tasks visible in TodoWrite
2. **Update Latency**: <1s from event to UI update
3. **Accuracy**: 100% status accuracy
4. **Reliability**: <0.1% update failures
5. **Performance**: <1% execution overhead

### Validation Approach

1. **Integration Tests**
   - Todo generation from various DAG structures
   - Update handling for all status transitions
   - Graceful degradation scenarios

2. **User Testing**
   - Observe users executing commands
   - Gather feedback on progress clarity
   - Measure task abandonment rates

3. **Performance Tests**
   - Measure update overhead
   - Test with 100+ task hierarchies
   - Validate batching effectiveness

4. **Reliability Tests**
   - Simulate TodoWrite failures
   - Test recovery mechanisms
   - Validate fallback behavior

## Implementation Notes

### Configuration

```typescript
interface TodoWriteConfig {
  enabled: boolean           // Default: true
  updateInterval: number     // Default: 1000ms
  batchSize: number         // Default: 10
  maxRetries: number        // Default: 3
  fallbackToLogs: boolean   // Default: true
  hierarchyDepth: number    // Default: 3
}
```

### Update Patterns

```typescript
// Immediate updates for critical events
const criticalEvents = ['phase:start', 'phase:complete', 'command:failed']

// Batched updates for high-frequency events
const batchedEvents = ['agent:progress', 'context:cached', 'resource:acquired']

// Periodic sync for consistency
setInterval(() => this.syncFullProgress(), 30000)  // Every 30 seconds
```

### Todo State Mapping

| Orchestration State | Todo Status | Todo Active Form |
|-------------------|-------------|------------------|
| Node pending | `pending` | Base content |
| Node executing | `in_progress` | Active form |
| Node completed | `completed` | Base content |
| Node failed | `in_progress` | "Failed: {error}" |
| Node skipped | `completed` | "Skipped" |

### Example Output

```
📋 Execute build-fullstack command
  ✅ Phase 1: Requirements Analysis
    ✅ Run architect agent (5.2s)
    ✅ Validate requirements (2.1s)

  🔄 Phase 2: Implementation (executing...)
    🔄 Build frontend components (running...)
    🔄 Build backend API (running...)
    ⏳ Create database schema

  ⏳ Phase 3: Testing
    ⏳ Run unit tests
    ⏳ Run integration tests

  ⏳ Phase 4: Deployment
    ⏳ Deploy to staging
    ⏳ Run smoke tests

Progress: 35% (7/20 tasks completed)
Estimated remaining: ~3 minutes
```

## Related Documents

- [ADR-009: DAG-Based Orchestration](./ADR-009-dag-based-orchestration.md)
- [ADR-010: Context Manager Design](./ADR-010-context-manager-design.md)
- [C4 Architecture Diagrams](../architecture/orchestration-c4.md)
- [TodoWrite Tool Documentation](../tools/todowrite.md)

## Decision History

- 2024-12-01: Initial progress tracking discussion
- 2024-12-04: TodoWrite identified as solution
- 2024-12-08: Integration design approved
- 2024-12-10: Accepted with batching strategy
- 2024-12-11: Implementation started