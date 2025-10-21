---
title: Workflow Creation Guide
description: Design and implement multi-agent workflows with dependency management, quality gates, and error handling. Build scalable orchestration for complex tasks.
tags:
  - workflows
  - orchestration
  - agents
  - automation
  - patterns
  - best-practices
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Workflow Creation Guide

**Target Audience**: Developers, Solution Architects
**Estimated Reading Time**: 20-25 minutes
**Last Updated**: 2025-10-08

## Table of Contents

1. [Introduction](#introduction)
2. [Workflow DSL Overview](#workflow-dsl-overview)
3. [Workflow Patterns](#workflow-patterns)
4. [Dependency Management](#dependency-management)
5. [Quality Gates](#quality-gates)
6. [Error Handling](#error-handling)
7. [State Management](#state-management)
8. [Advanced Topics](#advanced-topics)
9. [Testing Workflows](#testing-workflows)
10. [Best Practices](#best-practices)
11. [Complete Examples](#complete-examples)
12. [Troubleshooting](#troubleshooting)
13. [API Reference](#api-reference)

---

## Introduction

### What are Workflows?

Workflows in Agent Studio are declarative, structured definitions that orchestrate multiple meta-agents to accomplish complex tasks. They provide a powerful abstraction for coordinating agent execution, managing dependencies, handling errors, and maintaining state across distributed operations.

### Why Use Workflows?

**Benefits of Workflow-Based Orchestration**:

- **Declarative Design**: Define what you want to achieve, not how to achieve it
- **Dependency Management**: Automatic task ordering and parallel execution optimization
- **Resilience**: Built-in retry logic, error handling, and state recovery
- **Observability**: Real-time progress tracking via SignalR and comprehensive telemetry
- **Reusability**: Template-based workflows with parameterization
- **Quality Assurance**: Integrated quality gates and validation at every stage

**When to Use Workflows**:

- Multi-step processes requiring coordination between multiple agents
- Complex dependency graphs where tasks must execute in specific orders
- Operations requiring checkpointing and recovery capabilities
- Scenarios needing real-time progress updates and monitoring
- Projects with strict quality gates and validation requirements

---

## Workflow DSL Overview

### Syntax

Agent Studio workflows can be defined in both **YAML** and **JSON** formats. YAML is recommended for its readability and human-friendly syntax.

### Core Concepts

#### 1. **Workflow Execution**

A workflow execution represents a single run of a workflow definition with specific inputs and context.

```yaml
workflow:
  id: deploy-feature-workflow
  name: "Feature Deployment Pipeline"
  pattern: sequential  # sequential | parallel | iterative | dynamic
  description: |
    Complete deployment pipeline including build, test,
    security scan, and deployment to staging environment

  timeout: 30m  # Optional: Maximum execution time
  maxRetries: 3  # Optional: Maximum retry attempts per task
```

#### 2. **Tasks**

Tasks are individual units of work executed by specific agents. Each task has inputs, outputs, and acceptance criteria.

```yaml
tasks:
  - id: task-build
    name: "Build Application"
    agent: code-generator-typescript
    estimatedHours: 2
    complexity: medium  # low | medium | high | critical

    inputs:
      sourceCode: "src/"
      configuration: "build.config.json"

    outputs:
      artifacts: "dist/"
      buildReport: "build-report.json"

    acceptanceCriteria:
      - "Build completes without errors"
      - "All TypeScript types are valid"
      - "Bundle size < 500KB"
```

#### 3. **Dependencies**

Tasks can depend on other tasks, creating a directed acyclic graph (DAG) that determines execution order.

```yaml
tasks:
  - id: task-compile
    dependencies: []  # Runs first

  - id: task-test
    dependencies: [task-compile]  # Runs after compilation

  - id: task-deploy
    dependencies: [task-test]  # Runs after tests pass
```

#### 4. **Execution Context**

The execution context carries state between tasks, enabling data flow through the workflow.

```yaml
context:
  environmentType: "staging"
  deploymentRegion: "eastus"
  version: "1.2.3"

  # Access previous task outputs
  buildArtifacts: "{{task-compile.outputs.artifacts}}"
```

---

## Workflow Patterns

### Sequential Workflows

Sequential workflows execute tasks in strict order, one after another. Each task must complete before the next begins.

**When to Use**:
- Tasks have strict ordering requirements
- Each step depends on the previous step's output
- Simple, linear processes

**Example**:

```yaml
workflow:
  pattern: sequential

tasks:
  - id: step1-analyze
    name: "Analyze Requirements"
    agent: architect
    outputs:
      architectureDoc: "architecture.md"

  - id: step2-design
    name: "Create Design"
    agent: architect
    dependencies: [step1-analyze]
    inputs:
      requirements: "{{step1-analyze.outputs.architectureDoc}}"
    outputs:
      designDoc: "design.md"

  - id: step3-implement
    name: "Implement Solution"
    agent: builder
    dependencies: [step2-design]
    inputs:
      design: "{{step2-design.outputs.designDoc}}"
    outputs:
      implementation: "src/"

  - id: step4-validate
    name: "Validate Implementation"
    agent: validator
    dependencies: [step3-implement]
    inputs:
      code: "{{step3-implement.outputs.implementation}}"
```

**Best Practices**:
- Keep sequential chains short (< 10 steps) for better observability
- Use checkpointing after each critical step
- Include clear acceptance criteria for each task

---

### Parallel Workflows

Parallel workflows execute independent tasks concurrently, maximizing throughput and reducing total execution time.

**When to Use**:
- Tasks are independent and can run simultaneously
- Performance optimization is critical
- Fork-join patterns (parallel execution followed by aggregation)

**Example**:

```yaml
workflow:
  pattern: parallel

tasks:
  # Initial task - runs first
  - id: prepare-environment
    name: "Prepare Build Environment"
    agent: devops-automator
    dependencies: []
    outputs:
      environment: "build-env-config"

  # Parallel tasks - run simultaneously after preparation
  - id: build-frontend
    name: "Build Frontend"
    agent: code-generator-typescript
    dependencies: [prepare-environment]
    estimatedHours: 3

  - id: build-backend
    name: "Build Backend"
    agent: code-generator-typescript
    dependencies: [prepare-environment]
    estimatedHours: 4

  - id: build-docs
    name: "Build Documentation"
    agent: technical-writer
    dependencies: [prepare-environment]
    estimatedHours: 2

  # Aggregation task - runs after all parallel tasks complete
  - id: package-release
    name: "Package Release"
    agent: devops-automator
    dependencies: [build-frontend, build-backend, build-docs]
    inputs:
      frontendArtifacts: "{{build-frontend.outputs.artifacts}}"
      backendArtifacts: "{{build-backend.outputs.artifacts}}"
      documentation: "{{build-docs.outputs.docs}}"
```

**Automatic Parallelization**:

The workflow engine automatically detects which tasks can run in parallel by analyzing dependencies:

```yaml
# These tasks will automatically run in parallel
tasks:
  - id: unit-tests
    dependencies: [build]

  - id: integration-tests
    dependencies: [build]

  - id: security-scan
    dependencies: [build]

  # This waits for all three to complete
  - id: generate-report
    dependencies: [unit-tests, integration-tests, security-scan]
```

**Best Practices**:
- Ensure truly independent tasks (no shared mutable state)
- Consider resource constraints (CPU, memory, API rate limits)
- Use aggregation tasks to collect and validate parallel results
- Set appropriate timeouts for the slowest expected task

---

### Saga Pattern

The Saga pattern manages distributed transactions with compensation logic for rollback when failures occur.

**When to Use**:
- Distributed transactions across multiple services
- Operations requiring rollback on failure
- Long-running business processes with multiple steps

**Example**:

```yaml
workflow:
  pattern: saga

tasks:
  - id: reserve-inventory
    name: "Reserve Inventory"
    agent: inventory-manager
    compensation: release-inventory-reservation
    outputs:
      reservationId: "reservation-id"

  - id: process-payment
    name: "Process Payment"
    agent: payment-processor
    dependencies: [reserve-inventory]
    compensation: refund-payment
    outputs:
      transactionId: "transaction-id"

  - id: create-shipment
    name: "Create Shipment"
    agent: shipping-coordinator
    dependencies: [process-payment]
    compensation: cancel-shipment
    outputs:
      trackingNumber: "tracking-number"

  - id: send-confirmation
    name: "Send Order Confirmation"
    agent: notification-service
    dependencies: [create-shipment]
    compensation: send-cancellation-notice

# Compensation actions (executed in reverse order on failure)
compensations:
  release-inventory-reservation:
    agent: inventory-manager
    action: release
    inputs:
      reservationId: "{{reserve-inventory.outputs.reservationId}}"

  refund-payment:
    agent: payment-processor
    action: refund
    inputs:
      transactionId: "{{process-payment.outputs.transactionId}}"

  cancel-shipment:
    agent: shipping-coordinator
    action: cancel
    inputs:
      trackingNumber: "{{create-shipment.outputs.trackingNumber}}"

  send-cancellation-notice:
    agent: notification-service
    action: notify
    inputs:
      notificationType: "order-cancelled"
```

**Compensation Execution**:

If `create-shipment` fails, the system automatically executes:
1. `refund-payment` (reverse of process-payment)
2. `release-inventory-reservation` (reverse of reserve-inventory)

**Best Practices**:
- Always define compensation for state-changing operations
- Test compensation logic thoroughly
- Make compensations idempotent (safe to retry)
- Log all compensation executions for audit trails

---

### Event-Driven Workflows

Event-driven workflows react to events and execute tasks based on triggers and conditions.

**When to Use**:
- Reactive systems responding to external events
- Pub/sub architectures
- Asynchronous, message-driven processes

**Example**:

```yaml
workflow:
  pattern: event-driven

triggers:
  - event: pull-request-opened
    source: github-webhook
    filters:
      - "event.repository == 'agent-studio'"
      - "event.labels.contains('ready-for-review')"

  - event: commit-pushed
    source: github-webhook
    filters:
      - "event.branch == 'main'"

tasks:
  - id: run-ci-checks
    name: "Run CI Checks"
    agent: ci-engineer
    triggeredBy: [pull-request-opened, commit-pushed]
    outputs:
      testResults: "test-results.json"
      coverageReport: "coverage.json"

  - id: security-scan
    name: "Run Security Scan"
    agent: security-specialist
    triggeredBy: [pull-request-opened]
    dependencies: [run-ci-checks]

  - id: auto-merge
    name: "Auto-Merge PR"
    agent: devops-automator
    triggeredBy: [pull-request-opened]
    dependencies: [run-ci-checks, security-scan]
    conditions:
      - "{{run-ci-checks.outputs.testResults.passed}} == true"
      - "{{security-scan.outputs.vulnerabilities.critical}} == 0"
```

**Best Practices**:
- Define clear event schemas and contracts
- Use filters to avoid unnecessary task execution
- Implement event deduplication for idempotency
- Monitor event processing latency

---

### Dynamic Workflows

Dynamic workflows adapt at runtime, generating tasks based on execution results and agent handoffs.

**When to Use**:
- Workflows where the path cannot be predetermined
- Agent collaboration with dynamic handoffs
- Adaptive processes based on intermediate results

**Example**:

```yaml
workflow:
  pattern: dynamic
  maxIterations: 10  # Safety limit to prevent infinite loops

tasks:
  - id: initial-analysis
    name: "Initial Problem Analysis"
    agent: architect
    outputs:
      complexity: "complexity-assessment"
      recommendedApproach: "approach"

  - id: dynamic-execution
    name: "Adaptive Execution"
    agent: "{{initial-analysis.outputs.recommendedApproach.agent}}"
    handoffEnabled: true

    handoffRules:
      - condition: "requires-code-generation"
        targetAgent: builder
        reason: "Implementation work identified"

      - condition: "requires-validation"
        targetAgent: validator
        reason: "Validation needed before proceeding"

      - condition: "requires-documentation"
        targetAgent: scribe
        reason: "Documentation requirements identified"
```

**Handoff Mechanism**:

Agents can dynamically hand off work to other agents:

```typescript
// Agent response with handoff
{
  success: true,
  result: {
    analysis: "Complex implementation required",
    recommendation: "Hand off to builder agent"
  },
  handoff: {
    targetAgentType: "builder",
    reason: "Implementation complexity exceeds analysis scope",
    context: {
      designDoc: "architecture.md",
      requirements: ["feature-1", "feature-2"]
    },
    priority: 1
  }
}
```

**Best Practices**:
- Always set `maxIterations` to prevent infinite loops
- Log all handoffs for observability
- Define clear handoff criteria and reasons
- Use a validator agent to determine completion in iterative workflows

---

## Dependency Management

### Defining Dependencies

Dependencies define the order of task execution. Agent Studio supports multiple dependency types:

#### Finish-to-Start (Default)

Task B starts after Task A completes:

```yaml
tasks:
  - id: task-a
    name: "Compile Code"

  - id: task-b
    name: "Run Tests"
    dependencies: [task-a]  # Starts after task-a completes
```

#### Multiple Dependencies

Task C starts only after both A and B complete:

```yaml
tasks:
  - id: task-a
    name: "Build Frontend"

  - id: task-b
    name: "Build Backend"

  - id: task-c
    name: "Integration Test"
    dependencies: [task-a, task-b]  # Waits for both
```

### DAG Validation

The workflow engine validates the dependency graph before execution:

**Cycle Detection**:

```yaml
# INVALID - Circular dependency
tasks:
  - id: task-a
    dependencies: [task-b]

  - id: task-b
    dependencies: [task-a]  # ERROR: Circular dependency detected
```

**Error Message**:
```
WorkflowValidationError: Circular dependency detected in workflow 'my-workflow'
  Cycle: task-a -> task-b -> task-a
```

**Orphaned Tasks**:

```yaml
# WARNING - task-x is unreachable
tasks:
  - id: task-a
    dependencies: []

  - id: task-b
    dependencies: [task-a]

  - id: task-x
    dependencies: [task-nonexistent]  # WARNING: Dependency not found
```

### Critical Path Analysis

The engine computes the critical path (longest path through the DAG) to estimate total execution time:

```yaml
tasks:
  - id: task-a
    estimatedHours: 2

  - id: task-b
    dependencies: [task-a]
    estimatedHours: 3

  - id: task-c
    dependencies: [task-a]
    estimatedHours: 1

  - id: task-d
    dependencies: [task-b, task-c]
    estimatedHours: 2

# Critical Path: task-a -> task-b -> task-d (7 hours)
# task-c is not on critical path (can be delayed without affecting total time)
```

**Accessing Critical Path**:

```typescript
// Via API
const workflow = await workflowClient.getWorkflow(workflowId);
console.log(workflow.criticalPath);  // ['task-a', 'task-b', 'task-d']
console.log(workflow.estimatedDuration);  // '7 hours'
```

### Parallel Execution

Tasks without dependencies or with satisfied dependencies run in parallel automatically:

```yaml
# Execution Timeline:
# t=0: task-setup starts
# t=1: task-setup completes
# t=1: task-build-ui, task-build-api, task-build-docs start in parallel
# t=5: All parallel tasks complete
# t=5: task-package starts

tasks:
  - id: task-setup
    estimatedHours: 1

  # These run in parallel after setup
  - id: task-build-ui
    dependencies: [task-setup]
    estimatedHours: 3

  - id: task-build-api
    dependencies: [task-setup]
    estimatedHours: 4

  - id: task-build-docs
    dependencies: [task-setup]
    estimatedHours: 2

  # Waits for all parallel tasks
  - id: task-package
    dependencies: [task-build-ui, task-build-api, task-build-docs]
    estimatedHours: 1
```

---

## Quality Gates

Quality gates are validation checkpoints that enforce quality standards at various stages of the workflow.

### Pre-Task Gates

Validate preconditions before a task starts:

```yaml
tasks:
  - id: deploy-to-production
    name: "Deploy to Production"
    agent: devops-automator

    qualityGates:
      preTask:
        - condition: "{{test-coverage}} >= 85"
          validator: test-engineer
          description: "Minimum test coverage required"
          blocking: true

        - condition: "{{security-scan.vulnerabilities.critical}} == 0"
          validator: security-specialist
          description: "No critical vulnerabilities allowed"
          blocking: true

        - condition: "{{approvals.count}} >= 2"
          validator: approval-checker
          description: "Require 2 human approvals for production"
          blocking: true
```

### Post-Task Gates

Validate task outputs after execution:

```yaml
tasks:
  - id: build-application
    name: "Build Application"
    agent: code-generator-typescript

    qualityGates:
      postTask:
        - validator: senior-reviewer
          action: code-review
          blocking: true
          criteria:
            - "No major code quality issues"
            - "Follows coding standards"
            - "Proper error handling"

        - validator: test-engineer
          action: coverage-check
          blocking: true
          criteria:
            - "Test coverage >= 85%"
            - "All critical paths covered"

        - validator: performance-optimizer
          action: performance-check
          blocking: false  # Warning only, doesn't block
          criteria:
            - "Bundle size < 500KB"
            - "Load time < 3s"
```

### Phase Gates

Validate entire phase completion before proceeding:

```yaml
phases:
  - phase: 1
    name: "Development Phase"
    tasks: [...]

    qualityGates:
      postPhase:
        - condition: "allTasksCompleted == true"
          validator: phase-validator
          blocking: true

        - condition: "{{phase-test-suite.passed}} == true"
          validator: test-engineer
          blocking: true
          onFail: rollback-phase

  - phase: 2
    name: "Deployment Phase"
    dependencies: [phase-1]  # Only starts if Phase 1 gates pass
    tasks: [...]
```

### Epic Gates

Final validation before marking the entire workflow complete:

```yaml
epic:
  qualityGates:
    postEpic:
      - condition: "testCoverage >= 85"
        validator: test-engineer
        measurement: "dotnet test /p:CollectCoverage=true"
        blocking: true

      - condition: "securityVulnerabilities.critical == 0 && securityVulnerabilities.high == 0"
        validator: security-specialist
        measurement: "Trivy scan + CodeQL analysis"
        blocking: true

      - condition: "performanceP95Latency < 500"
        validator: performance-optimizer
        measurement: "Load test with 100 concurrent users"
        blocking: true

      - condition: "documentationComplete == true"
        validator: technical-writer
        blocking: false  # Warning only

  successCriteria:
    - "All quality gates passed"
    - "No blocking issues remaining"
    - "Stakeholder sign-off received"
```

### Custom Validators

Define custom validation logic:

```typescript
// Custom validator agent
class CustomValidator {
  async validate(context: ValidationContext): Promise<ValidationResult> {
    const testCoverage = await this.measureTestCoverage(context);
    const codeQuality = await this.analyzeCodeQuality(context);

    return {
      passed: testCoverage >= 85 && codeQuality.grade >= 'B',
      metrics: {
        testCoverage,
        codeQualityGrade: codeQuality.grade
      },
      message: `Coverage: ${testCoverage}%, Quality: ${codeQuality.grade}`,
      blocking: true
    };
  }
}
```

---

## Error Handling

### Retry Strategies

#### Exponential Backoff

Automatic retry with increasing delays:

```yaml
tasks:
  - id: call-external-api
    name: "Call External API"
    agent: integration-specialist

    errorHandling:
      retry:
        maxAttempts: 3
        strategy: exponential-backoff
        baseDelay: 1s
        maxDelay: 30s
        # Attempt 1: 1s delay
        # Attempt 2: 2s delay
        # Attempt 3: 4s delay

      retryableErrors:
        - "TimeoutError"
        - "NetworkError"
        - "ServiceUnavailableError"

      nonRetryableErrors:
        - "AuthenticationError"
        - "ValidationError"
```

#### Fixed Delay

Retry with consistent delay:

```yaml
errorHandling:
  retry:
    maxAttempts: 5
    strategy: fixed-delay
    delay: 5s
```

#### Custom Retry Logic

```typescript
errorHandling: {
  retry: {
    maxAttempts: 3,
    strategy: 'custom',
    shouldRetry: (error, attemptNumber) => {
      // Custom logic
      if (error.type === 'RateLimitError') {
        const retryAfter = error.retryAfter || 60;
        return {
          retry: true,
          delay: retryAfter * 1000
        };
      }

      if (attemptNumber >= 3) {
        return { retry: false };
      }

      return {
        retry: true,
        delay: Math.pow(2, attemptNumber) * 1000
      };
    }
  }
}
```

### Compensation Logic

Saga pattern compensation for distributed rollback:

```yaml
tasks:
  - id: create-resources
    name: "Create Cloud Resources"
    agent: cloud-provisioner
    compensation: delete-resources

  - id: configure-resources
    name: "Configure Resources"
    agent: cloud-provisioner
    dependencies: [create-resources]
    compensation: reset-configuration

compensations:
  delete-resources:
    agent: cloud-provisioner
    action: delete
    inputs:
      resourceIds: "{{create-resources.outputs.resourceIds}}"

  reset-configuration:
    agent: cloud-provisioner
    action: reset
    inputs:
      resourceIds: "{{configure-resources.outputs.resourceIds}}"
```

### Circuit Breakers

Prevent cascading failures:

```yaml
tasks:
  - id: call-downstream-service
    name: "Call Downstream Service"
    agent: integration-specialist

    circuitBreaker:
      enabled: true
      failureThreshold: 5  # Open after 5 failures
      successThreshold: 2  # Close after 2 successes (in half-open state)
      timeout: 60s  # How long to keep circuit open

      fallback:
        action: use-cached-data
        agent: cache-manager
```

**Circuit Breaker States**:

1. **Closed**: Normal operation, requests flow through
2. **Open**: Failures exceeded threshold, requests fail immediately
3. **Half-Open**: Testing if service recovered, limited requests allowed

---

## State Management

### Workflow Context

The execution context carries state between tasks:

```yaml
workflow:
  context:
    # Initial context
    environment: "production"
    version: "2.1.0"

tasks:
  - id: build
    outputs:
      artifacts: "dist/"
      buildNumber: "12345"

  - id: deploy
    dependencies: [build]
    inputs:
      # Access context
      environment: "{{context.environment}}"
      version: "{{context.version}}"

      # Access previous task outputs
      artifacts: "{{build.outputs.artifacts}}"
      buildNumber: "{{build.outputs.buildNumber}}"
```

**Context API**:

```typescript
// C# - Access context in custom agent
public class DeploymentAgent {
  public async Task<AgentResponse> Execute(AgentRequest request) {
    var environment = request.Context["environment"];
    var buildNumber = request.Context["build_buildNumber"];

    // Add to context
    var result = new Dictionary<string, object> {
      ["deploymentUrl"] = $"https://{environment}.example.com",
      ["deployedAt"] = DateTime.UtcNow
    };

    return new AgentResponse {
      Success = true,
      Result = result
    };
  }
}
```

### Checkpointing

Automatic state snapshots for recovery:

```yaml
workflow:
  checkpointing:
    enabled: true
    strategy: automatic  # automatic | manual | phase-based
    frequency: after-each-task
    retention: 7d  # Keep checkpoints for 7 days

    storage:
      type: cosmos-db
      container: workflow-checkpoints
```

**Checkpoint Structure**:

```json
{
  "id": "checkpoint-abc123",
  "workflowExecutionId": "workflow-xyz789",
  "sequenceNumber": 3,
  "timestamp": "2025-10-08T10:30:00Z",
  "workflowSnapshot": {
    "id": "workflow-xyz789",
    "status": "Running",
    "currentPhase": 1
  },
  "contextSnapshot": {
    "state": {
      "environment": "staging",
      "build_artifacts": "dist/"
    },
    "results": {
      "task-build": {
        "success": true,
        "buildNumber": "12345"
      }
    }
  }
}
```

**Recovery from Checkpoint**:

```typescript
// Recover workflow from last checkpoint
const checkpoint = await stateManager.getLatestCheckpoint(workflowId);
const result = await workflowExecutor.resumeFromCheckpoint(checkpoint);
```

### Event Sourcing

Maintain complete audit trail:

```yaml
workflow:
  eventSourcing:
    enabled: true
    storage:
      type: cosmos-db
      container: workflow-events

    events:
      - WorkflowStarted
      - TaskStarted
      - TaskCompleted
      - TaskFailed
      - PhaseCompleted
      - CheckpointCreated
      - WorkflowCompleted
```

**Event Structure**:

```json
{
  "eventId": "evt-001",
  "eventType": "TaskCompleted",
  "workflowId": "workflow-xyz789",
  "taskId": "task-build",
  "timestamp": "2025-10-08T10:30:00Z",
  "payload": {
    "taskName": "Build Application",
    "duration": 120000,
    "outputs": {
      "artifacts": "dist/"
    }
  },
  "metadata": {
    "agent": "code-generator-typescript",
    "correlationId": "corr-abc123"
  }
}
```

**Event Replay**:

Reconstruct workflow state from event log:

```typescript
async function replayWorkflow(workflowId: string): Promise<WorkflowState> {
  const events = await eventStore.getEvents(workflowId);
  const state = new WorkflowState();

  for (const event of events) {
    state.apply(event);  // Replay each event
  }

  return state;
}
```

---

## Advanced Topics

### Conditional Execution

Execute tasks based on runtime conditions:

```yaml
tasks:
  - id: security-scan
    name: "Security Scan"
    agent: security-specialist
    outputs:
      vulnerabilityCount: "count"

  - id: auto-fix-vulnerabilities
    name: "Auto-Fix Security Issues"
    agent: security-specialist
    dependencies: [security-scan]

    condition: "{{security-scan.outputs.vulnerabilityCount}} > 0"
    # Only runs if vulnerabilities found

  - id: deploy-to-production
    name: "Deploy to Production"
    dependencies: [security-scan]

    condition: "{{security-scan.outputs.vulnerabilityCount}} == 0"
    # Only runs if no vulnerabilities
```

**Complex Conditions**:

```yaml
condition: |
  {{test-results.coverage}} >= 85 AND
  {{security-scan.critical}} == 0 AND
  ({{environment}} == 'staging' OR {{approvals}} >= 2)
```

### Dynamic Task Generation

Generate tasks at runtime based on data:

```yaml
tasks:
  - id: discover-microservices
    name: "Discover Microservices"
    agent: service-discovery
    outputs:
      services: ["api-gateway", "user-service", "order-service", "payment-service"]

  - id: deploy-services
    name: "Deploy All Services"
    agent: deployment-generator
    dependencies: [discover-microservices]

    dynamicTaskGeneration:
      enabled: true
      template:
        taskIdPrefix: "deploy-"
        agent: devops-automator
        inputs:
          serviceName: "{{item}}"

      forEach: "{{discover-microservices.outputs.services}}"
      # Generates: deploy-api-gateway, deploy-user-service, etc.
```

### Sub-Workflows

Nest workflows for reusability:

```yaml
workflows:
  # Main workflow
  - id: main-deployment-pipeline
    name: "Main Deployment Pipeline"

    tasks:
      - id: build
        name: "Build Application"
        agent: code-generator-typescript

      - id: run-tests
        name: "Run Test Suite"
        workflow: test-workflow  # Reference to sub-workflow
        dependencies: [build]
        inputs:
          artifacts: "{{build.outputs.artifacts}}"

      - id: deploy
        name: "Deploy to Environment"
        workflow: deployment-workflow  # Another sub-workflow
        dependencies: [run-tests]

  # Sub-workflow definition
  - id: test-workflow
    name: "Comprehensive Test Suite"

    tasks:
      - id: unit-tests
        agent: test-engineer

      - id: integration-tests
        agent: test-engineer
        dependencies: [unit-tests]

      - id: e2e-tests
        agent: test-engineer
        dependencies: [integration-tests]
```

### Workflow Templates

Parameterized, reusable workflows:

```yaml
template:
  id: deployment-template
  name: "Generic Deployment Template"

  parameters:
    - name: environment
      type: string
      required: true
      allowed: [dev, staging, production]

    - name: region
      type: string
      required: true
      default: eastus

    - name: enableBlueGreen
      type: boolean
      default: false

  tasks:
    - id: deploy
      name: "Deploy to {{parameters.environment}}"
      agent: devops-automator
      inputs:
        environment: "{{parameters.environment}}"
        region: "{{parameters.region}}"
        strategy: "{{parameters.enableBlueGreen ? 'blue-green' : 'rolling'}}"
```

**Using Template**:

```yaml
workflow:
  template: deployment-template
  parameters:
    environment: production
    region: westus
    enableBlueGreen: true
```

---

## Testing Workflows

### Local Testing

Test workflows in development environment:

```bash
# Validate workflow definition
dotnet run --project AgentStudio.Cli -- workflow validate \
  --file workflows/my-workflow.yaml

# Dry-run workflow (simulate execution)
dotnet run --project AgentStudio.Cli -- workflow dry-run \
  --file workflows/my-workflow.yaml \
  --context context.json

# Execute workflow locally
dotnet run --project AgentStudio.Cli -- workflow execute \
  --file workflows/my-workflow.yaml \
  --environment local
```

**Mock Agents for Testing**:

```yaml
workflow:
  id: test-workflow

  # Use mock agents in test environment
  agentOverrides:
    code-generator-typescript:
      type: mock
      responses:
        - taskId: task-build
          success: true
          outputs:
            artifacts: "dist/"
            buildNumber: "12345"
```

### Integration Testing

End-to-end workflow validation:

```csharp
[TestClass]
public class WorkflowIntegrationTests
{
    [TestMethod]
    public async Task TestDeploymentWorkflow_Success()
    {
        // Arrange
        var workflow = WorkflowDefinition.LoadFromFile("workflows/deployment.yaml");
        var executor = new WorkflowExecutor(/* dependencies */);

        var context = new Dictionary<string, object>
        {
            ["environment"] = "staging",
            ["version"] = "1.0.0"
        };

        // Act
        var result = await executor.ExecuteAsync(workflow, context);

        // Assert
        Assert.IsTrue(result.Success);
        Assert.AreEqual(WorkflowStatus.Completed, result.Status);
        Assert.IsTrue(result.Context.Results.ContainsKey("deploy"));

        var deployOutput = result.Context.Results["deploy"];
        Assert.IsNotNull(deployOutput.Result["deploymentUrl"]);
    }

    [TestMethod]
    public async Task TestWorkflowRecovery_FromCheckpoint()
    {
        // Simulate failure after task 2
        var checkpoint = await CreateCheckpointAfterTask("task-2");

        // Resume from checkpoint
        var result = await executor.ResumeFromCheckpointAsync(checkpoint);

        // Should complete remaining tasks
        Assert.IsTrue(result.Success);
        Assert.AreEqual(3, result.Context.Results.Count); // Tasks 3-5 executed
    }
}
```

### Chaos Testing

Validate resilience under failure conditions:

```yaml
chaosTests:
  - name: "Task Timeout Test"
    inject:
      type: timeout
      taskId: task-build
      duration: 1ms  # Force timeout

    expect:
      workflowStatus: Failed
      retryAttempts: 3
      compensationExecuted: true

  - name: "Network Failure Test"
    inject:
      type: network-error
      taskId: call-external-api
      errorType: ServiceUnavailableError

    expect:
      circuitBreakerState: Open
      fallbackExecuted: true

  - name: "Checkpoint Recovery Test"
    inject:
      type: crash
      afterTask: task-3

    expect:
      recoverySuccessful: true
      resumedFromCheckpoint: checkpoint-3
      remainingTasksExecuted: [task-4, task-5]
```

---

## Best Practices

### Design Patterns

#### 1. **Pipeline Pattern**

Sequential stages with validation gates:

```yaml
workflow:
  pattern: sequential

phases:
  - phase: build
    tasks: [compile, package]
    qualityGates:
      postPhase:
        - condition: "buildSuccess == true"

  - phase: test
    dependencies: [build]
    tasks: [unit-test, integration-test]
    qualityGates:
      postPhase:
        - condition: "testCoverage >= 85"

  - phase: deploy
    dependencies: [test]
    tasks: [deploy-staging, smoke-test, deploy-production]
```

#### 2. **Fan-Out/Fan-In Pattern**

Parallel execution with aggregation:

```yaml
tasks:
  - id: split-data
    outputs:
      batches: [batch-1, batch-2, batch-3]

  # Fan-out: Process in parallel
  - id: process-batches
    dynamicTaskGeneration:
      forEach: "{{split-data.outputs.batches}}"
      template:
        agent: data-processor

  # Fan-in: Aggregate results
  - id: merge-results
    dependencies: [process-batches]
    agent: data-aggregator
```

#### 3. **Retry with Circuit Breaker**

Resilient external service calls:

```yaml
tasks:
  - id: call-payment-api
    errorHandling:
      retry:
        maxAttempts: 3
        strategy: exponential-backoff

    circuitBreaker:
      enabled: true
      failureThreshold: 5
      fallback:
        action: queue-for-later
```

### Performance Optimization

#### Parallel Execution

Maximize concurrency:

```yaml
# Bad: Sequential execution
tasks:
  - id: task-1
  - id: task-2
    dependencies: [task-1]
  - id: task-3
    dependencies: [task-2]

# Good: Parallel where possible
tasks:
  - id: task-1
  - id: task-2  # Runs in parallel with task-1
  - id: task-3  # Runs in parallel with task-1
  - id: task-4
    dependencies: [task-1, task-2, task-3]  # Waits for all
```

#### Caching

Cache expensive operations:

```yaml
tasks:
  - id: fetch-large-dataset
    caching:
      enabled: true
      key: "dataset-{{date}}-{{version}}"
      ttl: 3600  # 1 hour
      storage: redis
```

#### Resource Limits

Prevent resource exhaustion:

```yaml
workflow:
  resourceLimits:
    maxConcurrentTasks: 10
    maxMemoryMB: 4096
    maxCpuPercent: 80

  taskDefaults:
    timeout: 5m
    maxRetries: 3
```

### Observability

#### Logging

Structured logging for all workflow events:

```yaml
workflow:
  logging:
    level: info  # debug | info | warn | error
    includeContext: true
    includeTaskOutputs: false  # Privacy: don't log sensitive outputs

    destinations:
      - type: application-insights
        connectionString: "{{secrets.appInsights}}"

      - type: console
        format: json
```

#### Tracing

Distributed tracing with OpenTelemetry:

```yaml
workflow:
  tracing:
    enabled: true
    serviceName: agent-studio-workflows

    exporters:
      - type: jaeger
        endpoint: "http://jaeger:14268/api/traces"

      - type: application-insights
        connectionString: "{{secrets.appInsights}}"
```

#### Metrics

Track workflow performance:

```yaml
workflow:
  metrics:
    enabled: true

    custom:
      - name: workflow_duration_seconds
        type: histogram
        labels: [workflow_id, pattern, status]

      - name: task_execution_count
        type: counter
        labels: [task_id, agent_type, status]

      - name: quality_gate_failures
        type: counter
        labels: [gate_name, blocking]
```

---

## Complete Examples

### Example 1: CI/CD Pipeline

```yaml
workflow:
  id: ci-cd-pipeline
  name: "Continuous Integration and Deployment"
  pattern: sequential

  context:
    repository: "agent-studio"
    branch: "main"
    environment: "production"

tasks:
  - id: checkout-code
    name: "Checkout Source Code"
    agent: git-operator
    outputs:
      commitHash: "hash"
      changedFiles: "files"

  - id: install-dependencies
    name: "Install Dependencies"
    agent: package-manager
    dependencies: [checkout-code]
    inputs:
      packageManager: "npm"
    outputs:
      dependencyTree: "tree"

  - id: run-linting
    name: "Run Code Linting"
    agent: code-quality-checker
    dependencies: [install-dependencies]

  - id: run-unit-tests
    name: "Run Unit Tests"
    agent: test-engineer
    dependencies: [install-dependencies]
    outputs:
      testResults: "results"
      coverage: "coverage"

    qualityGates:
      postTask:
        - condition: "{{run-unit-tests.outputs.coverage}} >= 85"
          validator: test-engineer
          blocking: true

  - id: run-integration-tests
    name: "Run Integration Tests"
    agent: test-engineer
    dependencies: [run-unit-tests]

  - id: build-application
    name: "Build Application"
    agent: build-engineer
    dependencies: [run-linting, run-integration-tests]
    outputs:
      artifacts: "dist/"
      version: "1.2.3"

  - id: security-scan
    name: "Security Vulnerability Scan"
    agent: security-specialist
    dependencies: [build-application]
    outputs:
      vulnerabilities: "scan-results"

    qualityGates:
      postTask:
        - condition: "{{security-scan.outputs.vulnerabilities.critical}} == 0"
          validator: security-specialist
          blocking: true

  - id: deploy-to-staging
    name: "Deploy to Staging"
    agent: devops-automator
    dependencies: [security-scan]
    inputs:
      artifacts: "{{build-application.outputs.artifacts}}"
      environment: "staging"
    outputs:
      deploymentUrl: "url"

  - id: smoke-tests
    name: "Run Smoke Tests"
    agent: test-engineer
    dependencies: [deploy-to-staging]
    inputs:
      baseUrl: "{{deploy-to-staging.outputs.deploymentUrl}}"

  - id: deploy-to-production
    name: "Deploy to Production"
    agent: devops-automator
    dependencies: [smoke-tests]
    inputs:
      artifacts: "{{build-application.outputs.artifacts}}"
      environment: "production"
      strategy: "blue-green"

    qualityGates:
      preTask:
        - condition: "{{approvals.count}} >= 2"
          validator: approval-checker
          blocking: true
          description: "Require 2 approvals for production deployment"
```

### Example 2: Data Processing Pipeline

```yaml
workflow:
  id: data-processing-pipeline
  name: "Batch Data Processing Pipeline"
  pattern: parallel

  context:
    inputBucket: "raw-data"
    outputBucket: "processed-data"
    batchSize: 1000

tasks:
  - id: fetch-data
    name: "Fetch Raw Data"
    agent: data-fetcher
    outputs:
      recordCount: "count"
      batches: "batch-ids"

  - id: validate-data
    name: "Validate Data Quality"
    agent: data-validator
    dependencies: [fetch-data]
    outputs:
      validRecords: "valid-count"
      invalidRecords: "invalid-count"

  # Parallel processing of batches
  - id: process-batch-1
    name: "Process Batch 1"
    agent: data-processor
    dependencies: [validate-data]
    inputs:
      batchId: "{{fetch-data.outputs.batches[0]}}"

  - id: process-batch-2
    name: "Process Batch 2"
    agent: data-processor
    dependencies: [validate-data]
    inputs:
      batchId: "{{fetch-data.outputs.batches[1]}}"

  - id: process-batch-3
    name: "Process Batch 3"
    agent: data-processor
    dependencies: [validate-data]
    inputs:
      batchId: "{{fetch-data.outputs.batches[2]}}"

  # Aggregate results
  - id: merge-results
    name: "Merge Processed Data"
    agent: data-aggregator
    dependencies: [process-batch-1, process-batch-2, process-batch-3]
    inputs:
      batches:
        - "{{process-batch-1.outputs.data}}"
        - "{{process-batch-2.outputs.data}}"
        - "{{process-batch-3.outputs.data}}"
    outputs:
      mergedData: "merged"

  - id: generate-report
    name: "Generate Processing Report"
    agent: report-generator
    dependencies: [merge-results]
    inputs:
      totalRecords: "{{fetch-data.outputs.recordCount}}"
      processedRecords: "{{merge-results.outputs.mergedData.count}}"
```

### Example 3: Multi-Service Deployment with Compensation

```yaml
workflow:
  id: multi-service-deployment
  name: "Multi-Service Deployment with Rollback"
  pattern: saga

  context:
    services: [api-gateway, user-service, order-service, payment-service]
    targetEnvironment: production

tasks:
  - id: backup-database
    name: "Backup Production Database"
    agent: database-admin
    compensation: restore-database-backup
    outputs:
      backupId: "backup-id"

  - id: deploy-api-gateway
    name: "Deploy API Gateway"
    agent: devops-automator
    dependencies: [backup-database]
    compensation: rollback-api-gateway
    inputs:
      service: api-gateway
      version: "2.1.0"
    outputs:
      deploymentId: "deployment-id"

  - id: deploy-user-service
    name: "Deploy User Service"
    agent: devops-automator
    dependencies: [deploy-api-gateway]
    compensation: rollback-user-service
    inputs:
      service: user-service
      version: "1.5.0"

  - id: deploy-order-service
    name: "Deploy Order Service"
    agent: devops-automator
    dependencies: [deploy-user-service]
    compensation: rollback-order-service
    inputs:
      service: order-service
      version: "3.2.1"

  - id: deploy-payment-service
    name: "Deploy Payment Service"
    agent: devops-automator
    dependencies: [deploy-order-service]
    compensation: rollback-payment-service
    inputs:
      service: payment-service
      version: "2.0.5"

  - id: run-health-checks
    name: "Run Health Checks"
    agent: monitoring-agent
    dependencies: [deploy-payment-service]
    inputs:
      services: "{{context.services}}"

    qualityGates:
      postTask:
        - condition: "{{run-health-checks.outputs.allHealthy}} == true"
          validator: monitoring-agent
          blocking: true
          onFail: rollback-saga

compensations:
  restore-database-backup:
    agent: database-admin
    action: restore
    inputs:
      backupId: "{{backup-database.outputs.backupId}}"

  rollback-api-gateway:
    agent: devops-automator
    action: rollback
    inputs:
      deploymentId: "{{deploy-api-gateway.outputs.deploymentId}}"

  rollback-user-service:
    agent: devops-automator
    action: rollback
    inputs:
      deploymentId: "{{deploy-user-service.outputs.deploymentId}}"

  rollback-order-service:
    agent: devops-automator
    action: rollback
    inputs:
      deploymentId: "{{deploy-order-service.outputs.deploymentId}}"

  rollback-payment-service:
    agent: devops-automator
    action: rollback
    inputs:
      deploymentId: "{{deploy-payment-service.outputs.deploymentId}}"
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Circular Dependency Detected

**Error**:
```
WorkflowValidationError: Circular dependency detected
  Cycle: task-a -> task-b -> task-c -> task-a
```

**Solution**:
```yaml
# Before (circular)
tasks:
  - id: task-a
    dependencies: [task-c]
  - id: task-b
    dependencies: [task-a]
  - id: task-c
    dependencies: [task-b]

# After (fixed)
tasks:
  - id: task-a
    dependencies: []
  - id: task-b
    dependencies: [task-a]
  - id: task-c
    dependencies: [task-b]
```

#### Issue: Task Timeout

**Error**:
```
TaskExecutionError: Task 'build-application' exceeded timeout of 5m
```

**Solution**:
```yaml
tasks:
  - id: build-application
    timeout: 15m  # Increase timeout

    # Or add retry logic
    errorHandling:
      retry:
        maxAttempts: 2
        strategy: exponential-backoff
```

#### Issue: Quality Gate Blocking Workflow

**Error**:
```
QualityGateError: Quality gate 'test-coverage' failed
  Expected: coverage >= 85
  Actual: coverage = 72
  Blocking: true
```

**Solution**:
```yaml
# Option 1: Fix the underlying issue (increase test coverage)

# Option 2: Temporarily make gate non-blocking
qualityGates:
  postTask:
    - condition: "{{coverage}} >= 85"
      blocking: false  # Warning only

# Option 3: Lower threshold (not recommended)
qualityGates:
  postTask:
    - condition: "{{coverage}} >= 70"
      blocking: true
```

#### Issue: Checkpoint Recovery Failing

**Error**:
```
CheckpointError: Failed to restore workflow state from checkpoint
  Reason: Context schema mismatch
```

**Solution**:
```yaml
# Ensure checkpoint retention
workflow:
  checkpointing:
    enabled: true
    retention: 7d  # Keep for 7 days

    # Version checkpoints to handle schema changes
    version: "2.0"

    # Allow schema evolution
    allowSchemaEvolution: true
```

#### Issue: Agent Handoff Loop

**Error**:
```
WorkflowError: Maximum iterations (10) exceeded in dynamic workflow
  Handoff chain: architect -> builder -> validator -> architect -> ...
```

**Solution**:
```yaml
workflow:
  pattern: dynamic
  maxIterations: 10

  # Add completion detection
  completionCriteria:
    - "{{validator.outputs.is_complete}} == true"
    - "{{iteration}} >= 3 AND {{errors}} == 0"
```

### Debugging Workflows

#### Enable Debug Logging

```yaml
workflow:
  logging:
    level: debug
    includeContext: true
    includeTaskOutputs: true
```

#### View Execution Trace

```bash
# Get workflow execution details
dotnet run --project AgentStudio.Cli -- workflow trace \
  --workflow-id abc-123 \
  --format json \
  --output trace.json
```

#### Inspect Checkpoint

```bash
# List checkpoints
dotnet run --project AgentStudio.Cli -- checkpoint list \
  --workflow-id abc-123

# View checkpoint details
dotnet run --project AgentStudio.Cli -- checkpoint get \
  --checkpoint-id cp-456 \
  --format yaml
```

---

## API Reference

### REST API

#### Create Workflow

```http
POST /api/v1/workflows HTTP/1.1
Content-Type: application/json

{
  "type": "Sequential",
  "description": "Deploy application to production",
  "agents": [
    {
      "type": "Builder",
      "id": "build-agent",
      "config": {
        "framework": "dotnet"
      }
    },
    {
      "type": "Validator",
      "id": "test-agent"
    }
  ],
  "context": {
    "environment": "production",
    "version": "1.0.0"
  },
  "priority": "High",
  "timeoutMinutes": 30
}
```

**Response**:
```json
{
  "workflowId": "wf-abc123",
  "status": "Running",
  "type": "Sequential",
  "agents": [
    {
      "agentId": "agent-001",
      "type": "Builder",
      "status": "Running"
    },
    {
      "agentId": "agent-002",
      "type": "Validator",
      "status": "Pending"
    }
  ],
  "createdAt": "2025-10-08T10:00:00Z",
  "estimatedCompletion": "2025-10-08T10:30:00Z",
  "statusUrl": "/api/v1/workflows/wf-abc123"
}
```

#### Get Workflow Status

```http
GET /api/v1/workflows/{workflowId} HTTP/1.1
```

**Response**:
```json
{
  "workflowId": "wf-abc123",
  "status": "Running",
  "type": "Sequential",
  "description": "Deploy application to production",
  "progress": {
    "percentage": 66.7,
    "currentStep": "Running tests",
    "completedAgents": ["Builder"],
    "pendingAgents": ["Validator"]
  },
  "agents": [
    {
      "agentId": "agent-001",
      "type": "Builder",
      "status": "Completed",
      "startedAt": "2025-10-08T10:00:00Z",
      "completedAt": "2025-10-08T10:10:00Z",
      "durationSeconds": 600,
      "outputSummary": "Build completed successfully"
    },
    {
      "agentId": "agent-002",
      "type": "Validator",
      "status": "Running",
      "startedAt": "2025-10-08T10:10:00Z",
      "progress": {
        "currentTest": "integration-tests",
        "testsCompleted": 15,
        "testsTotal": 20
      }
    }
  ],
  "createdAt": "2025-10-08T10:00:00Z",
  "updatedAt": "2025-10-08T10:15:00Z"
}
```

#### Cancel Workflow

```http
DELETE /api/v1/workflows/{workflowId} HTTP/1.1
```

**Response**:
```json
{
  "workflowId": "wf-abc123",
  "status": "Cancelled",
  "cancelledAt": "2025-10-08T10:20:00Z",
  "message": "Workflow cancelled by user request"
}
```

### SignalR Real-Time Events

#### Subscribe to Workflow Events

```typescript
import * as signalR from "@microsoft/signalr";

const connection = new signalR.HubConnectionBuilder()
  .withUrl("/hubs/meta-agent")
  .build();

// Subscribe to workflow
await connection.invoke("SubscribeToWorkflow", workflowId);

// Listen for events
connection.on("ReceiveAgentThought", (workflowId, taskId, thought) => {
  console.log(`[${taskId}] ${thought.type}: ${thought.content}`);
});

connection.on("ReceiveProgress", (workflowId, percentage, message) => {
  console.log(`Progress: ${percentage}% - ${message}`);
});

connection.on("ReceiveTaskCompleted", (workflowId, task) => {
  console.log(`Task ${task.id} completed in ${task.durationSeconds}s`);
});
```

### .NET SDK

```csharp
using AgentStudio.Orchestration;

// Create workflow executor
var executor = serviceProvider.GetRequiredService<IWorkflowExecutor>();

// Define workflow
var workflow = new WorkflowExecution
{
    Id = Guid.NewGuid().ToString(),
    WorkflowDefinitionId = "deployment-workflow",
    Pattern = WorkflowPattern.Sequential,
    Status = WorkflowStatus.Pending,
    Tasks = new List<AgentTask>
    {
        new AgentTask
        {
            Id = "task-1",
            AgentType = "builder",
            Request = new AgentRequest
            {
                Task = "Build application",
                Context = new Dictionary<string, object>
                {
                    ["environment"] = "production"
                }
            }
        }
    },
    Context = new ExecutionContext(),
    CreatedAt = DateTimeOffset.UtcNow,
    InitiatedBy = "user@example.com"
};

// Execute workflow
var result = await executor.ExecuteAsync(workflow, cancellationToken);

if (result.Success)
{
    Console.WriteLine($"Workflow {result.WorkflowId} completed in {result.Duration}");
}
```

### Python SDK

```python
from meta_agents.workflows import WorkflowClient

# Create client
client = WorkflowClient(base_url="http://localhost:5000")

# Create workflow
workflow = client.create_workflow(
    workflow_type="sequential",
    description="Deploy application",
    agents=[
        {"type": "builder", "config": {"framework": "python"}},
        {"type": "validator"}
    ],
    context={"environment": "production"},
    priority="high"
)

print(f"Workflow {workflow.id} created")

# Monitor progress
for event in client.stream_events(workflow.id):
    if event.type == "progress":
        print(f"Progress: {event.percentage}%")
    elif event.type == "task_completed":
        print(f"Task {event.task_id} completed")
    elif event.type == "workflow_completed":
        print("Workflow completed!")
        break
```

---

## Summary

This guide covered:

- **Workflow DSL**: YAML/JSON syntax for defining workflows
- **Patterns**: Sequential, Parallel, Saga, Event-Driven, and Dynamic execution
- **Dependencies**: DAG construction, validation, and automatic parallelization
- **Quality Gates**: Pre/post task validation and epic-level gates
- **Error Handling**: Retry strategies, compensation, and circuit breakers
- **State Management**: Context, checkpointing, and event sourcing
- **Advanced Topics**: Conditionals, dynamic generation, sub-workflows, templates
- **Testing**: Local, integration, and chaos testing strategies
- **Best Practices**: Design patterns, performance optimization, observability
- **Complete Examples**: CI/CD, data processing, multi-service deployment
- **API Reference**: REST, SignalR, .NET, and Python APIs

For additional resources:
- [API Documentation](../api/meta-agent-api-guide.md)
- [Architecture Overview](../../meta-agents/ARCHITECTURE.md)
- [Integration Guide](../integration-guide.md)
- [Example Workflows](../../../examples/workflows/)

---

**Need Help?**

- GitHub Issues: [github.com/your-org/agent-studio/issues](https://github.com/your-org/agent-studio/issues)
- Documentation: [docs.agent-studio.dev](https://docs.agent-studio.dev)
- Slack Community: [agent-studio.slack.com](https://agent-studio.slack.com)
