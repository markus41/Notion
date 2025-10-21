# ADR-009: DAG-Based Orchestration

## Status

**Accepted** - December 2024

## Context

The Claude Code Orchestration v1.0 used a sequential markdown-based approach where agents were executed one after another in a linear fashion. This approach had several limitations:

### Problems with Sequential Execution

1. **Performance Bottleneck**: Independent tasks couldn't run in parallel, leading to unnecessary waiting time
2. **Implicit Dependencies**: Dependencies between agents were not explicitly declared, making it difficult to understand task relationships
3. **No Optimization Opportunity**: The system couldn't optimize execution order based on dependencies
4. **Poor Scalability**: As command complexity grew, execution time increased linearly
5. **Limited Recovery**: Difficult to resume from specific points after failures

### Requirements for v2.0

- Support parallel execution of independent tasks
- Explicit dependency declaration between agents
- Automatic optimization of execution order
- Efficient resource utilization
- Deterministic execution with predictable outcomes
- Support for complex workflows with conditional paths

### Constraints

- Must maintain backward compatibility with existing command structure
- Cannot introduce circular dependencies
- Must provide clear error messages for dependency issues
- Performance overhead of graph construction must be minimal
- Must integrate with existing progress tracking systems

## Decision

We will implement a **Directed Acyclic Graph (DAG) based orchestration system** for managing agent execution dependencies and enabling parallel processing.

### Core Design Elements

1. **DAG Construction**
   - Build graph from explicit dependencies in command definition
   - Validate graph for cycles using DFS-based cycle detection
   - Generate execution levels using topological sort

2. **Execution Strategy**
   - Execute all nodes at the same level in parallel using `Promise.all()`
   - Wait for level completion before proceeding to next level
   - Pass context between dependent nodes

3. **Dependency Management**
   ```typescript
   interface AgentNode {
     id: string
     dependencies: string[]  // Explicit dependencies
     context: Map<string, any>
   }
   ```

4. **Parallelization Algorithm**
   ```typescript
   // Topological sort with level assignment
   function buildExecutionLevels(dag: DAG): Level[] {
     const levels: Level[] = []
     const inDegree = calculateInDegree(dag)

     while (hasNodesWithZeroInDegree(inDegree)) {
       const currentLevel = getNodesWithZeroInDegree(inDegree)
       levels.push(currentLevel)
       removeNodesFromGraph(currentLevel, inDegree)
     }

     return levels
   }
   ```

5. **Failure Handling**
   - **Fail-fast**: Stop execution on first failure (default)
   - **Continue-on-error**: Mark failed nodes, continue with non-dependent tasks
   - **Retry with backoff**: Exponential backoff for transient failures

## Alternatives Considered

### 1. Sequential Execution (v1.0 Approach)

**Pros:**
- Simple to implement and understand
- Predictable execution order
- Easy debugging

**Cons:**
- No parallelization benefit
- Slow execution for complex commands
- Doesn't scale with command complexity

**Why Rejected:** Performance limitations became unacceptable as commands grew more complex

### 2. Event-Driven Choreography

**Pros:**
- Highly decoupled agents
- Dynamic execution paths
- Natural async handling

**Cons:**
- Difficult to reason about execution flow
- Complex debugging and monitoring
- Hard to guarantee ordering constraints
- Potential for event storms

**Why Rejected:** Loss of execution predictability and increased debugging complexity

### 3. External Workflow Engine (Temporal, Airflow)

**Pros:**
- Battle-tested orchestration
- Built-in persistence and recovery
- Rich monitoring and debugging tools

**Cons:**
- Heavy external dependency
- Significant integration complexity
- Overkill for command orchestration
- Requires separate infrastructure

**Why Rejected:** Adds unnecessary complexity for our use case; we need lightweight, embedded orchestration

### 4. Promise-Chain Based Execution

**Pros:**
- Native JavaScript approach
- No graph construction overhead
- Simple error propagation

**Cons:**
- Difficult to express complex dependencies
- No automatic parallelization
- Hard to visualize execution flow

**Why Rejected:** Doesn't provide the parallelization benefits we need

## Consequences

### Positive Consequences

1. **Performance Improvement**: 50-70% execution time reduction through parallelization
2. **Explicit Dependencies**: Clear understanding of task relationships
3. **Automatic Optimization**: System determines optimal execution order
4. **Scalability**: Execution time grows with critical path, not total tasks
5. **Visual Representation**: DAG can be visualized for debugging
6. **Deterministic Execution**: Same input always produces same execution order
7. **Resource Efficiency**: Better CPU and I/O utilization through parallel execution

### Negative Consequences

1. **Implementation Complexity**: DAG construction and validation logic
2. **Learning Curve**: Command authors must understand dependency declaration
3. **Memory Overhead**: Graph structure requires additional memory
4. **Debugging Complexity**: Parallel execution makes debugging harder
5. **Dependency Declaration**: Requires explicit dependency specification

### Risks and Mitigations

| Risk | Impact | Mitigation |
|------|---------|------------|
| **Circular Dependencies** | High - System deadlock | Validate DAG at construction time with cycle detection |
| **Resource Contention** | Medium - Performance degradation | ResourceManager with locking mechanisms |
| **Graph Construction Overhead** | Low - Slower startup | Cache constructed DAGs, optimize algorithms |
| **Complex Debugging** | Medium - Harder troubleshooting | Enhanced logging, visual DAG representation |
| **Memory Exhaustion** | Low - System failure | Limit graph size, streaming execution for large graphs |

## Validation

### Success Metrics

1. **Performance**: 50%+ reduction in execution time for parallel-friendly commands
2. **Reliability**: <0.1% failure rate due to dependency issues
3. **Adoption**: 80%+ of complex commands use parallel execution
4. **Developer Satisfaction**: Positive feedback on dependency management

### Validation Approach

1. **Unit Tests**: Comprehensive DAG construction and validation tests
2. **Integration Tests**: End-to-end command execution with various dependency patterns
3. **Performance Tests**: Benchmark sequential vs. parallel execution
4. **Load Tests**: Stress test with complex graphs (100+ nodes)
5. **User Studies**: Gather feedback from command authors

## Implementation Notes

### Phase 1: Core DAG Implementation
- DAG data structure and algorithms
- Cycle detection and validation
- Topological sort implementation

### Phase 2: Execution Engine
- Parallel scheduler integration
- Context passing between nodes
- Progress tracking updates

### Phase 3: Optimizations
- DAG caching for repeated executions
- Dynamic rescheduling based on runtime conditions
- Predictive prefetching for common patterns

## Related Documents

- [ADR-008: Agent Orchestration Integration](./ADR-008-agent-orchestration-integration.md)
- [C4 Architecture Diagrams](../architecture/orchestration-c4.md)
- [v2.0 Command Format Specification](../specifications/command-format-v2.md)

## Decision History

- 2024-12-01: Initial proposal
- 2024-12-05: Reviewed alternatives with team
- 2024-12-10: Accepted with minor modifications
- 2024-12-15: Implementation started