# Command Format Specification v2.0

## Table of Contents
1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Schema Reference](#schema-reference)
4. [Field Descriptions](#field-descriptions)
5. [Validation Rules](#validation-rules)
6. [Examples](#examples)
7. [JSON Schema](#json-schema)
8. [Migration Guide](#migration-guide)
9. [Breaking Changes](#breaking-changes)
10. [FAQ](#faq)

## Overview

The v2.0 command format transforms Claude Code commands from implicit markdown definitions to explicit, machine-readable JSON specifications. This format enables:

- **Explicit Dependencies**: Machine-readable DAG construction
- **Parallel Execution**: Automatic parallelization of independent tasks
- **Context Sharing**: Eliminate redundant work through shared cache
- **Error Recovery**: Saga pattern compensations for rollback
- **Resource Management**: Deadlock prevention and lock management
- **Progress Tracking**: Automatic todo generation with time estimates

### Format Goals

1. **Machine-Readable**: JSON format for programmatic parsing and validation
2. **Declarative**: Define what to execute, not how
3. **Composable**: Commands can reference and compose other commands
4. **Observable**: Built-in progress tracking and telemetry
5. **Recoverable**: Explicit compensation and retry strategies
6. **Cacheable**: Context sharing to eliminate redundant computation
7. **Versionable**: Semantic versioning for backward compatibility

### File Format

- **Extension**: `.json` (required for v2.0)
- **Location**: `.claude/commands/` directory
- **Naming**: `command-name.json` (kebab-case)
- **Encoding**: UTF-8
- **Validation**: Must pass JSON Schema validation

## Design Principles

### 1. Dependency-First Design
All task relationships are explicitly declared through `dependencies` arrays, enabling the DAG Builder to construct optimal execution graphs.

### 2. Phase-Based Organization
Commands are organized into logical phases that group related tasks, improving readability while maintaining execution flexibility.

### 3. Context as First-Class Citizen
Every agent node declares its context requirements (inputs/outputs), enabling the Context Manager to share data and eliminate redundant work.

### 4. Fail-Safe by Default
All nodes must define failure behavior through `continueOnError`, `retryable`, and `compensation` fields.

### 5. Observable Execution
Built-in time estimates and progress tracking enable real-time visibility into command execution.

## Schema Reference

### CommandDefinition

The root object defining a complete command.

```typescript
interface CommandDefinition {
  version: string;                    // Schema version (required: "2.0.0")
  name: string;                        // Command name (e.g., "/review-all")
  description: string;                 // Human-readable description
  phases: Phase[];                     // Ordered execution phases
  metadata?: CommandMetadata;          // Optional metadata
  globalContext?: GlobalContext;       // Global context configuration
  resources?: ResourceRequirements;    // Resource lock requirements
}
```

### Phase

A logical grouping of related agent tasks.

```typescript
interface Phase {
  id: string;                         // Unique phase identifier
  name: string;                       // Display name (e.g., "Analysis")
  description?: string;               // Optional phase description
  agents: AgentNode[];                // Agent nodes in this phase
  parallel?: boolean;                 // Can agents run in parallel? (default: true)
  continueOnError?: boolean;          // Continue if phase fails? (default: false)
  maxParallelism?: number;            // Max concurrent agents (default: unlimited)
  timeout?: number;                   // Phase timeout in milliseconds
}
```

### AgentNode

A single agent task within a phase.

```typescript
interface AgentNode {
  id: string;                         // Unique node ID within command
  agentId: string;                    // Agent type from registry
  task: string;                       // Task description for agent
  dependencies: string[];             // Node IDs this depends on
  estimatedTime?: number;             // Estimated milliseconds
  timeout?: number;                   // Timeout in milliseconds
  retryPolicy?: RetryPolicy;          // Retry configuration
  compensation?: CompensationAction;  // Rollback logic
  context?: ContextRequirements;      // Context I/O specification
  priority?: number;                  // Execution priority (higher = first)
  skipCondition?: SkipCondition;      // Conditional execution
}
```

### ContextRequirements

Defines context data flow between agents.

```typescript
interface ContextRequirements {
  inputs: ContextInput[];             // Required input keys
  outputs: ContextOutput[];           // Produced output keys
  passthrough?: boolean;              // Pass all context (default: false)
}

interface ContextInput {
  key: string;                        // Context key name
  required?: boolean;                 // Is this required? (default: true)
  default?: any;                      // Default value if missing
  transform?: string;                 // JSONPath transformation
}

interface ContextOutput {
  key: string;                        // Context key name
  ttl?: number;                       // Cache TTL in seconds
  persist?: boolean;                  // Persist across phases
  merge?: MergeStrategy;              // How to merge with existing
}

enum MergeStrategy {
  REPLACE = "replace",                // Replace existing value
  MERGE = "merge",                     // Deep merge objects
  APPEND = "append",                   // Append to array
  CONCAT = "concat"                    // Concatenate strings
}
```

### CompensationAction

Saga pattern compensation for rollback.

```typescript
interface CompensationAction {
  type: CompensationType;             // Compensation strategy
  description: string;                // What this compensation does
  agentId?: string;                   // Agent for custom compensation
  task?: string;                       // Compensation task
  rollbackTo?: string;                // Node ID to rollback to
  compensateOn?: CompensateTrigger[]; // When to trigger compensation
}

enum CompensationType {
  NONE = "none",                      // No compensation needed
  RETRY = "retry",                     // Retry the operation
  ROLLBACK = "rollback",               // Rollback to previous state
  CUSTOM = "custom",                   // Custom agent compensation
  CASCADE = "cascade"                  // Trigger dependent compensations
}

enum CompensateTrigger {
  ERROR = "error",                     // Any error
  TIMEOUT = "timeout",                 // Operation timeout
  VALIDATION_FAILURE = "validation",   // Output validation failed
  USER_CANCEL = "cancel"               // User cancellation
}
```

### RetryPolicy

Configures retry behavior for failed operations.

```typescript
interface RetryPolicy {
  maxAttempts: number;                // Maximum retry attempts
  strategy: RetryStrategy;            // Retry strategy
  initialDelay?: number;               // Initial delay in ms
  maxDelay?: number;                   // Maximum delay in ms
  backoffMultiplier?: number;         // Exponential backoff multiplier
  retryableErrors?: string[];         // Specific errors to retry
}

enum RetryStrategy {
  IMMEDIATE = "immediate",             // No delay between retries
  LINEAR = "linear",                   // Linear backoff
  EXPONENTIAL = "exponential",        // Exponential backoff
  FIBONACCI = "fibonacci"              // Fibonacci backoff
}
```

### CommandMetadata

Optional metadata for command management.

```typescript
interface CommandMetadata {
  author?: string;                    // Command author
  version?: string;                   // Command version (semver)
  tags?: string[];                    // Searchable tags
  category?: string;                  // Command category
  visibility?: Visibility;            // Command visibility
  deprecated?: boolean;               // Is deprecated?
  replacedBy?: string;                // Replacement command
  examples?: Example[];               // Usage examples
  requirements?: Requirements;        // System requirements
}

enum Visibility {
  PUBLIC = "public",                  // Available to all users
  PRIVATE = "private",                // User-specific
  TEAM = "team",                      // Team-specific
  BETA = "beta"                       // Beta testing
}
```

### ResourceRequirements

Defines resource locks needed by the command.

```typescript
interface ResourceRequirements {
  locks: ResourceLock[];              // Required resource locks
  maxWaitTime?: number;               // Max wait for locks (ms)
}

interface ResourceLock {
  resource: string;                   // Resource identifier
  type: LockType;                     // Lock type
  priority?: number;                  // Lock priority
}

enum LockType {
  EXCLUSIVE = "exclusive",            // Exclusive access
  SHARED = "shared",                  // Shared read access
  UPGRADE = "upgrade"                 // Upgradeable lock
}
```

### SkipCondition

Conditional execution based on context.

```typescript
interface SkipCondition {
  type: ConditionType;                // Condition type
  expression: string;                 // Condition expression
  skipMessage?: string;               // Message when skipped
}

enum ConditionType {
  CONTEXT = "context",                // Check context value
  FILE_EXISTS = "file_exists",        // Check file existence
  COMMAND_SUCCESS = "command_success", // Previous command result
  CUSTOM = "custom"                    // Custom condition
}
```

## Field Descriptions

### Root Level Fields

| Field | Required | Description |
|-------|----------|-------------|
| `version` | Yes | Schema version, must be "2.0.0" for this specification |
| `name` | Yes | Command name starting with "/" (e.g., "/review-all") |
| `description` | Yes | Human-readable description shown in command list |
| `phases` | Yes | Array of execution phases, minimum 1 phase required |
| `metadata` | No | Additional metadata for discovery and management |
| `globalContext` | No | Global context configuration affecting all nodes |
| `resources` | No | Resource locks required by entire command |

### Phase Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `id` | Yes | - | Unique identifier within command |
| `name` | Yes | - | Display name shown in progress tracker |
| `description` | No | - | Optional description of phase purpose |
| `agents` | Yes | - | Array of agent nodes, minimum 1 required |
| `parallel` | No | `true` | Whether agents can run in parallel |
| `continueOnError` | No | `false` | Continue to next phase on failure |
| `maxParallelism` | No | unlimited | Maximum concurrent agents |
| `timeout` | No | - | Phase-level timeout in milliseconds |

### AgentNode Fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `id` | Yes | - | Unique node identifier for dependencies |
| `agentId` | Yes | - | Agent type from registry |
| `task` | Yes | - | Task description passed to agent |
| `dependencies` | Yes | `[]` | Array of node IDs this depends on |
| `estimatedTime` | No | 60000 | Estimated execution time in ms |
| `timeout` | No | 300000 | Operation timeout in ms |
| `retryPolicy` | No | no retry | Retry configuration |
| `compensation` | No | none | Rollback strategy |
| `context` | No | - | Context input/output specification |
| `priority` | No | 0 | Higher priority executes first |
| `skipCondition` | No | - | Conditional execution |

## Validation Rules

### Schema Validation

1. **Version**: Must be exactly "2.0.0"
2. **Name**: Must start with "/" and contain only lowercase letters, numbers, and hyphens
3. **Phases**: Must have at least one phase
4. **Agent IDs**: Must be unique within the command
5. **Dependencies**: Must reference existing node IDs
6. **Circular Dependencies**: Not allowed, will fail validation
7. **Agent Registry**: `agentId` must exist in agent registry

### Dependency Validation

```javascript
// Valid: Linear dependency
{
  "agents": [
    { "id": "analyze", "dependencies": [] },
    { "id": "review", "dependencies": ["analyze"] },
    { "id": "report", "dependencies": ["review"] }
  ]
}

// Valid: Diamond dependency
{
  "agents": [
    { "id": "analyze", "dependencies": [] },
    { "id": "security", "dependencies": ["analyze"] },
    { "id": "quality", "dependencies": ["analyze"] },
    { "id": "report", "dependencies": ["security", "quality"] }
  ]
}

// Invalid: Circular dependency
{
  "agents": [
    { "id": "a", "dependencies": ["b"] },
    { "id": "b", "dependencies": ["a"] }  // ERROR: Circular
  ]
}

// Invalid: Missing dependency
{
  "agents": [
    { "id": "review", "dependencies": ["analyze"] }  // ERROR: "analyze" not found
  ]
}
```

### Context Validation

1. **Input Keys**: Must be produced by a previous node or provided globally
2. **Output Keys**: Should not conflict with reserved keys
3. **TTL**: Must be positive integer (seconds)
4. **Merge Strategy**: Only applicable to existing keys

### Time Validation

1. **Timeout**: Must be greater than `estimatedTime`
2. **Phase Timeout**: Must be greater than sum of serial agent times
3. **Estimated Time**: Should be realistic (warn if > 1 hour)

## Examples

### Example 1: Simple Sequential Command

```json
{
  "version": "2.0.0",
  "name": "/hello-world",
  "description": "Simple greeting command",
  "phases": [
    {
      "id": "greeting",
      "name": "Greeting Phase",
      "parallel": false,
      "agents": [
        {
          "id": "greet",
          "agentId": "general-assistant",
          "task": "Say hello to the user",
          "dependencies": [],
          "estimatedTime": 1000
        },
        {
          "id": "goodbye",
          "agentId": "general-assistant",
          "task": "Say goodbye to the user",
          "dependencies": ["greet"],
          "estimatedTime": 1000
        }
      ]
    }
  ]
}
```

### Example 2: Parallel Analysis Command

```json
{
  "version": "2.0.0",
  "name": "/review-all",
  "description": "Comprehensive code review across 5 dimensions",
  "metadata": {
    "author": "Platform Team",
    "version": "2.1.0",
    "category": "code-review",
    "tags": ["review", "quality", "security", "performance"]
  },
  "phases": [
    {
      "id": "analysis",
      "name": "Codebase Analysis",
      "description": "Analyze codebase structure and metrics",
      "parallel": false,
      "agents": [
        {
          "id": "analyzer",
          "agentId": "codebase-analyzer",
          "task": "Analyze codebase structure, dependencies, and metrics",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "inputs": [],
            "outputs": [
              {
                "key": "codebase_analysis",
                "ttl": 3600,
                "persist": true
              },
              {
                "key": "file_list",
                "ttl": 3600,
                "persist": true
              }
            ]
          }
        }
      ]
    },
    {
      "id": "reviews",
      "name": "Parallel Reviews",
      "description": "Run specialized reviews in parallel",
      "parallel": true,
      "maxParallelism": 3,
      "continueOnError": true,
      "agents": [
        {
          "id": "quality",
          "agentId": "quality-reviewer",
          "task": "Review code quality, patterns, and best practices",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "priority": 10,
          "context": {
            "inputs": [
              { "key": "codebase_analysis", "required": true },
              { "key": "file_list", "required": true }
            ],
            "outputs": [
              { "key": "quality_review", "ttl": 3600 }
            ]
          }
        },
        {
          "id": "security",
          "agentId": "security-reviewer",
          "task": "Review security vulnerabilities and best practices",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "priority": 20,
          "retryPolicy": {
            "maxAttempts": 2,
            "strategy": "exponential",
            "initialDelay": 1000
          },
          "context": {
            "inputs": [
              { "key": "codebase_analysis", "required": true },
              { "key": "file_list", "required": true }
            ],
            "outputs": [
              { "key": "security_review", "ttl": 3600 }
            ]
          }
        },
        {
          "id": "performance",
          "agentId": "performance-reviewer",
          "task": "Review performance bottlenecks and optimization opportunities",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [
              { "key": "codebase_analysis", "required": true }
            ],
            "outputs": [
              { "key": "performance_review", "ttl": 3600 }
            ]
          }
        },
        {
          "id": "accessibility",
          "agentId": "accessibility-reviewer",
          "task": "Review accessibility compliance and best practices",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "skipCondition": {
            "type": "context",
            "expression": "codebase_analysis.has_frontend == false",
            "skipMessage": "No frontend code detected, skipping accessibility review"
          },
          "context": {
            "inputs": [
              { "key": "file_list", "required": true }
            ],
            "outputs": [
              { "key": "accessibility_review", "ttl": 3600 }
            ]
          }
        },
        {
          "id": "documentation",
          "agentId": "documentation-reviewer",
          "task": "Review documentation completeness and quality",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [
              { "key": "codebase_analysis", "required": true }
            ],
            "outputs": [
              { "key": "documentation_review", "ttl": 3600 }
            ]
          }
        }
      ]
    },
    {
      "id": "synthesis",
      "name": "Final Synthesis",
      "description": "Synthesize all reviews into final report",
      "parallel": false,
      "agents": [
        {
          "id": "synthesizer",
          "agentId": "senior-reviewer",
          "task": "Synthesize all reviews and provide prioritized recommendations",
          "dependencies": ["quality", "security", "performance", "accessibility", "documentation"],
          "estimatedTime": 360000,
          "context": {
            "inputs": [
              { "key": "quality_review", "required": false, "default": "Not performed" },
              { "key": "security_review", "required": false, "default": "Not performed" },
              { "key": "performance_review", "required": false, "default": "Not performed" },
              { "key": "accessibility_review", "required": false, "default": "Not performed" },
              { "key": "documentation_review", "required": false, "default": "Not performed" }
            ],
            "outputs": [
              { "key": "final_report", "persist": true }
            ]
          }
        }
      ]
    }
  ]
}
```

### Example 3: Hierarchical Feature Implementation

```json
{
  "version": "2.0.0",
  "name": "/implement-feature",
  "description": "Implement a complete feature with architecture, code, and tests",
  "phases": [
    {
      "id": "design",
      "name": "Architecture Design",
      "agents": [
        {
          "id": "architect",
          "agentId": "architect-supreme",
          "task": "Design system architecture and create ADR",
          "dependencies": [],
          "estimatedTime": 900000,
          "context": {
            "outputs": [
              { "key": "architecture_design", "persist": true },
              { "key": "api_contracts", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "implementation",
      "name": "Parallel Implementation",
      "parallel": true,
      "agents": [
        {
          "id": "backend",
          "agentId": "code-generator-python",
          "task": "Implement backend services based on architecture",
          "dependencies": ["architect"],
          "estimatedTime": 1200000,
          "context": {
            "inputs": [
              { "key": "architecture_design" },
              { "key": "api_contracts" }
            ],
            "outputs": [
              { "key": "backend_code", "persist": true }
            ]
          }
        },
        {
          "id": "frontend",
          "agentId": "typescript-code-generator",
          "task": "Implement frontend components",
          "dependencies": ["architect"],
          "estimatedTime": 1200000,
          "context": {
            "inputs": [
              { "key": "api_contracts" }
            ],
            "outputs": [
              { "key": "frontend_code", "persist": true }
            ]
          }
        },
        {
          "id": "database",
          "agentId": "database-architect",
          "task": "Design and implement database schema",
          "dependencies": ["architect"],
          "estimatedTime": 600000,
          "compensation": {
            "type": "rollback",
            "description": "Drop created tables and migrations",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [
              { "key": "architecture_design" }
            ],
            "outputs": [
              { "key": "database_schema", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "testing",
      "name": "Test Generation",
      "parallel": true,
      "agents": [
        {
          "id": "backend-tests",
          "agentId": "test-engineer",
          "task": "Generate comprehensive backend tests",
          "dependencies": ["backend"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [
              { "key": "backend_code" }
            ],
            "outputs": [
              { "key": "backend_tests" }
            ]
          }
        },
        {
          "id": "frontend-tests",
          "agentId": "test-engineer",
          "task": "Generate frontend component tests",
          "dependencies": ["frontend"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [
              { "key": "frontend_code" }
            ],
            "outputs": [
              { "key": "frontend_tests" }
            ]
          }
        },
        {
          "id": "integration-tests",
          "agentId": "test-engineer",
          "task": "Generate integration tests",
          "dependencies": ["backend", "frontend", "database"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [
              { "key": "backend_code" },
              { "key": "frontend_code" },
              { "key": "database_schema" }
            ],
            "outputs": [
              { "key": "integration_tests" }
            ]
          }
        }
      ]
    },
    {
      "id": "review",
      "name": "Code Review",
      "agents": [
        {
          "id": "review",
          "agentId": "senior-reviewer",
          "task": "Review implementation and suggest improvements",
          "dependencies": ["backend-tests", "frontend-tests", "integration-tests"],
          "estimatedTime": 600000,
          "context": {
            "passthrough": true,
            "outputs": [
              { "key": "review_report", "persist": true }
            ]
          }
        }
      ]
    }
  ]
}
```

### Example 4: Database Migration with Saga Pattern

```json
{
  "version": "2.0.0",
  "name": "/database-migration",
  "description": "Execute database migration with automatic rollback on failure",
  "resources": {
    "locks": [
      {
        "resource": "database",
        "type": "exclusive",
        "priority": 100
      }
    ],
    "maxWaitTime": 60000
  },
  "phases": [
    {
      "id": "preparation",
      "name": "Migration Preparation",
      "parallel": false,
      "agents": [
        {
          "id": "backup",
          "agentId": "database-architect",
          "task": "Create database backup before migration",
          "dependencies": [],
          "estimatedTime": 300000,
          "compensation": {
            "type": "none",
            "description": "Backup is kept for safety"
          },
          "context": {
            "outputs": [
              { "key": "backup_id", "persist": true }
            ]
          }
        },
        {
          "id": "validate-schema",
          "agentId": "database-architect",
          "task": "Validate current schema matches expected state",
          "dependencies": ["backup"],
          "estimatedTime": 60000,
          "context": {
            "outputs": [
              { "key": "schema_valid", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "migration",
      "name": "Execute Migration",
      "parallel": false,
      "continueOnError": false,
      "agents": [
        {
          "id": "migrate-schema",
          "agentId": "database-architect",
          "task": "Apply schema migrations",
          "dependencies": ["validate-schema"],
          "estimatedTime": 180000,
          "compensation": {
            "type": "custom",
            "description": "Rollback schema to previous version",
            "agentId": "database-architect",
            "task": "Execute reverse migration scripts",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [
              { "key": "schema_valid" }
            ],
            "outputs": [
              { "key": "migration_version", "persist": true }
            ]
          }
        },
        {
          "id": "migrate-data",
          "agentId": "database-architect",
          "task": "Transform and migrate data to new schema",
          "dependencies": ["migrate-schema"],
          "estimatedTime": 600000,
          "retryPolicy": {
            "maxAttempts": 3,
            "strategy": "exponential",
            "initialDelay": 5000,
            "retryableErrors": ["DEADLOCK", "TIMEOUT"]
          },
          "compensation": {
            "type": "custom",
            "description": "Restore data from backup",
            "agentId": "database-architect",
            "task": "Restore data from backup_id",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [
              { "key": "backup_id" },
              { "key": "migration_version" }
            ],
            "outputs": [
              { "key": "rows_migrated", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "validation",
      "name": "Post-Migration Validation",
      "parallel": true,
      "agents": [
        {
          "id": "validate-integrity",
          "agentId": "database-architect",
          "task": "Validate data integrity constraints",
          "dependencies": ["migrate-data"],
          "estimatedTime": 120000,
          "compensation": {
            "type": "cascade",
            "description": "Trigger full rollback if validation fails",
            "rollbackTo": "backup",
            "compensateOn": ["validation"]
          },
          "context": {
            "inputs": [
              { "key": "rows_migrated" }
            ],
            "outputs": [
              { "key": "integrity_valid" }
            ]
          }
        },
        {
          "id": "validate-performance",
          "agentId": "performance-reviewer",
          "task": "Validate query performance meets SLAs",
          "dependencies": ["migrate-data"],
          "estimatedTime": 180000,
          "context": {
            "outputs": [
              { "key": "performance_report" }
            ]
          }
        }
      ]
    },
    {
      "id": "finalization",
      "name": "Migration Finalization",
      "agents": [
        {
          "id": "cleanup",
          "agentId": "database-architect",
          "task": "Clean up temporary tables and old schema objects",
          "dependencies": ["validate-integrity", "validate-performance"],
          "estimatedTime": 60000,
          "skipCondition": {
            "type": "context",
            "expression": "integrity_valid == false",
            "skipMessage": "Skipping cleanup due to validation failure"
          }
        }
      ]
    }
  ]
}
```

### Example 5: Dynamic Adaptive Testing

```json
{
  "version": "2.0.0",
  "name": "/adaptive-test",
  "description": "Dynamically adjust test strategy based on initial results",
  "phases": [
    {
      "id": "initial-test",
      "name": "Initial Test Suite",
      "agents": [
        {
          "id": "unit-tests",
          "agentId": "test-engineer",
          "task": "Run unit test suite and analyze coverage",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              { "key": "coverage_report", "persist": true },
              { "key": "failed_tests", "persist": true },
              { "key": "coverage_percentage", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "adaptive-testing",
      "name": "Adaptive Test Generation",
      "parallel": true,
      "agents": [
        {
          "id": "coverage-improvement",
          "agentId": "test-engineer",
          "task": "Generate tests for uncovered code paths",
          "dependencies": ["unit-tests"],
          "estimatedTime": 600000,
          "skipCondition": {
            "type": "context",
            "expression": "coverage_percentage >= 85",
            "skipMessage": "Coverage already meets threshold"
          },
          "context": {
            "inputs": [
              { "key": "coverage_report" }
            ],
            "outputs": [
              { "key": "additional_tests" }
            ]
          }
        },
        {
          "id": "failure-analysis",
          "agentId": "test-engineer",
          "task": "Analyze test failures and generate fixes",
          "dependencies": ["unit-tests"],
          "estimatedTime": 900000,
          "skipCondition": {
            "type": "context",
            "expression": "failed_tests.length == 0",
            "skipMessage": "No test failures to analyze"
          },
          "context": {
            "inputs": [
              { "key": "failed_tests" }
            ],
            "outputs": [
              { "key": "test_fixes" },
              { "key": "root_causes" }
            ]
          }
        },
        {
          "id": "performance-tests",
          "agentId": "performance-reviewer",
          "task": "Generate performance tests for critical paths",
          "dependencies": ["unit-tests"],
          "estimatedTime": 600000,
          "priority": -10,
          "context": {
            "inputs": [
              { "key": "coverage_report" }
            ],
            "outputs": [
              { "key": "performance_tests" }
            ]
          }
        }
      ]
    },
    {
      "id": "integration",
      "name": "Integration Testing",
      "agents": [
        {
          "id": "integration-suite",
          "agentId": "test-engineer",
          "task": "Run integration tests based on unit test results",
          "dependencies": ["coverage-improvement", "failure-analysis", "performance-tests"],
          "estimatedTime": 1200000,
          "retryPolicy": {
            "maxAttempts": 2,
            "strategy": "linear",
            "initialDelay": 10000
          },
          "context": {
            "inputs": [
              { "key": "additional_tests", "required": false },
              { "key": "test_fixes", "required": false },
              { "key": "performance_tests", "required": false }
            ],
            "outputs": [
              { "key": "integration_results", "persist": true }
            ]
          }
        }
      ]
    },
    {
      "id": "report",
      "name": "Test Report Generation",
      "agents": [
        {
          "id": "report-generator",
          "agentId": "senior-reviewer",
          "task": "Generate comprehensive test report with recommendations",
          "dependencies": ["integration-suite"],
          "estimatedTime": 300000,
          "context": {
            "passthrough": true,
            "outputs": [
              { "key": "test_report", "persist": true }
            ]
          }
        }
      ]
    }
  ]
}
```

## JSON Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://claude.ai/schemas/command-v2.0.0.json",
  "title": "Claude Command v2.0 Schema",
  "description": "Schema for Claude Code command definitions",
  "type": "object",
  "required": ["version", "name", "description", "phases"],
  "properties": {
    "version": {
      "type": "string",
      "const": "2.0.0",
      "description": "Schema version"
    },
    "name": {
      "type": "string",
      "pattern": "^/[a-z0-9-]+$",
      "description": "Command name starting with /"
    },
    "description": {
      "type": "string",
      "minLength": 1,
      "maxLength": 200,
      "description": "Human-readable command description"
    },
    "phases": {
      "type": "array",
      "minItems": 1,
      "items": {
        "$ref": "#/definitions/phase"
      },
      "description": "Execution phases"
    },
    "metadata": {
      "$ref": "#/definitions/metadata",
      "description": "Optional command metadata"
    },
    "globalContext": {
      "$ref": "#/definitions/globalContext",
      "description": "Global context configuration"
    },
    "resources": {
      "$ref": "#/definitions/resourceRequirements",
      "description": "Resource lock requirements"
    }
  },
  "definitions": {
    "phase": {
      "type": "object",
      "required": ["id", "name", "agents"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9-]*$",
          "description": "Unique phase identifier"
        },
        "name": {
          "type": "string",
          "minLength": 1,
          "maxLength": 50,
          "description": "Phase display name"
        },
        "description": {
          "type": "string",
          "maxLength": 200,
          "description": "Phase description"
        },
        "agents": {
          "type": "array",
          "minItems": 1,
          "items": {
            "$ref": "#/definitions/agentNode"
          },
          "description": "Agent nodes in this phase"
        },
        "parallel": {
          "type": "boolean",
          "default": true,
          "description": "Can agents run in parallel"
        },
        "continueOnError": {
          "type": "boolean",
          "default": false,
          "description": "Continue on failure"
        },
        "maxParallelism": {
          "type": "integer",
          "minimum": 1,
          "description": "Maximum concurrent agents"
        },
        "timeout": {
          "type": "integer",
          "minimum": 1000,
          "description": "Phase timeout in milliseconds"
        }
      }
    },
    "agentNode": {
      "type": "object",
      "required": ["id", "agentId", "task", "dependencies"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9-]*$",
          "description": "Unique node identifier"
        },
        "agentId": {
          "type": "string",
          "description": "Agent type from registry"
        },
        "task": {
          "type": "string",
          "minLength": 1,
          "description": "Task description for agent"
        },
        "dependencies": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Node IDs this depends on"
        },
        "estimatedTime": {
          "type": "integer",
          "minimum": 100,
          "default": 60000,
          "description": "Estimated time in milliseconds"
        },
        "timeout": {
          "type": "integer",
          "minimum": 100,
          "default": 300000,
          "description": "Timeout in milliseconds"
        },
        "retryPolicy": {
          "$ref": "#/definitions/retryPolicy",
          "description": "Retry configuration"
        },
        "compensation": {
          "$ref": "#/definitions/compensation",
          "description": "Rollback strategy"
        },
        "context": {
          "$ref": "#/definitions/contextRequirements",
          "description": "Context I/O specification"
        },
        "priority": {
          "type": "integer",
          "default": 0,
          "description": "Execution priority"
        },
        "skipCondition": {
          "$ref": "#/definitions/skipCondition",
          "description": "Conditional execution"
        }
      }
    },
    "contextRequirements": {
      "type": "object",
      "properties": {
        "inputs": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/contextInput"
          },
          "description": "Required input keys"
        },
        "outputs": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/contextOutput"
          },
          "description": "Produced output keys"
        },
        "passthrough": {
          "type": "boolean",
          "default": false,
          "description": "Pass all context through"
        }
      }
    },
    "contextInput": {
      "type": "object",
      "required": ["key"],
      "properties": {
        "key": {
          "type": "string",
          "description": "Context key name"
        },
        "required": {
          "type": "boolean",
          "default": true,
          "description": "Is this required"
        },
        "default": {
          "description": "Default value if missing"
        },
        "transform": {
          "type": "string",
          "description": "JSONPath transformation"
        }
      }
    },
    "contextOutput": {
      "type": "object",
      "required": ["key"],
      "properties": {
        "key": {
          "type": "string",
          "description": "Context key name"
        },
        "ttl": {
          "type": "integer",
          "minimum": 1,
          "description": "Cache TTL in seconds"
        },
        "persist": {
          "type": "boolean",
          "default": false,
          "description": "Persist across phases"
        },
        "merge": {
          "type": "string",
          "enum": ["replace", "merge", "append", "concat"],
          "default": "replace",
          "description": "Merge strategy"
        }
      }
    },
    "compensation": {
      "type": "object",
      "required": ["type", "description"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["none", "retry", "rollback", "custom", "cascade"],
          "description": "Compensation strategy"
        },
        "description": {
          "type": "string",
          "description": "What this compensation does"
        },
        "agentId": {
          "type": "string",
          "description": "Agent for custom compensation"
        },
        "task": {
          "type": "string",
          "description": "Compensation task"
        },
        "rollbackTo": {
          "type": "string",
          "description": "Node ID to rollback to"
        },
        "compensateOn": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["error", "timeout", "validation", "cancel"]
          },
          "description": "When to trigger compensation"
        }
      }
    },
    "retryPolicy": {
      "type": "object",
      "required": ["maxAttempts", "strategy"],
      "properties": {
        "maxAttempts": {
          "type": "integer",
          "minimum": 1,
          "maximum": 10,
          "description": "Maximum retry attempts"
        },
        "strategy": {
          "type": "string",
          "enum": ["immediate", "linear", "exponential", "fibonacci"],
          "description": "Retry strategy"
        },
        "initialDelay": {
          "type": "integer",
          "minimum": 0,
          "default": 1000,
          "description": "Initial delay in ms"
        },
        "maxDelay": {
          "type": "integer",
          "minimum": 0,
          "default": 60000,
          "description": "Maximum delay in ms"
        },
        "backoffMultiplier": {
          "type": "number",
          "minimum": 1,
          "default": 2,
          "description": "Exponential backoff multiplier"
        },
        "retryableErrors": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Specific errors to retry"
        }
      }
    },
    "skipCondition": {
      "type": "object",
      "required": ["type", "expression"],
      "properties": {
        "type": {
          "type": "string",
          "enum": ["context", "file_exists", "command_success", "custom"],
          "description": "Condition type"
        },
        "expression": {
          "type": "string",
          "description": "Condition expression"
        },
        "skipMessage": {
          "type": "string",
          "description": "Message when skipped"
        }
      }
    },
    "metadata": {
      "type": "object",
      "properties": {
        "author": {
          "type": "string",
          "description": "Command author"
        },
        "version": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+$",
          "description": "Command version (semver)"
        },
        "tags": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Searchable tags"
        },
        "category": {
          "type": "string",
          "description": "Command category"
        },
        "visibility": {
          "type": "string",
          "enum": ["public", "private", "team", "beta"],
          "default": "public",
          "description": "Command visibility"
        },
        "deprecated": {
          "type": "boolean",
          "default": false,
          "description": "Is deprecated"
        },
        "replacedBy": {
          "type": "string",
          "description": "Replacement command"
        },
        "examples": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/example"
          },
          "description": "Usage examples"
        },
        "requirements": {
          "$ref": "#/definitions/requirements",
          "description": "System requirements"
        }
      }
    },
    "example": {
      "type": "object",
      "required": ["command", "description"],
      "properties": {
        "command": {
          "type": "string",
          "description": "Example command"
        },
        "description": {
          "type": "string",
          "description": "What this example does"
        }
      }
    },
    "requirements": {
      "type": "object",
      "properties": {
        "minVersion": {
          "type": "string",
          "description": "Minimum Claude version"
        },
        "features": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Required features"
        }
      }
    },
    "globalContext": {
      "type": "object",
      "properties": {
        "initial": {
          "type": "object",
          "description": "Initial context values"
        },
        "cacheTTL": {
          "type": "integer",
          "minimum": 1,
          "default": 3600,
          "description": "Default cache TTL in seconds"
        },
        "persistKeys": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "description": "Keys to persist across phases"
        }
      }
    },
    "resourceRequirements": {
      "type": "object",
      "properties": {
        "locks": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/resourceLock"
          },
          "description": "Required resource locks"
        },
        "maxWaitTime": {
          "type": "integer",
          "minimum": 0,
          "description": "Max wait for locks in ms"
        }
      }
    },
    "resourceLock": {
      "type": "object",
      "required": ["resource", "type"],
      "properties": {
        "resource": {
          "type": "string",
          "description": "Resource identifier"
        },
        "type": {
          "type": "string",
          "enum": ["exclusive", "shared", "upgrade"],
          "description": "Lock type"
        },
        "priority": {
          "type": "integer",
          "default": 0,
          "description": "Lock priority"
        }
      }
    }
  }
}
```

## Migration Guide

### Step 1: Analyze Existing v1.0 Command

Review your existing markdown command to understand:
- Command name and description
- Phase structure
- Agent tasks and dependencies
- Estimated execution times

### Step 2: Create JSON Structure

1. Start with basic structure:
```json
{
  "version": "2.0.0",
  "name": "/your-command",
  "description": "Your description",
  "phases": []
}
```

### Step 3: Convert Phases

For each phase in v1.0:
1. Create phase object with unique ID
2. Set `parallel` based on whether tasks can run concurrently
3. Add agents array

### Step 4: Convert Agent Tasks

For each numbered step in v1.0:
1. Create agent node with unique ID
2. Map agent type to `agentId` from registry
3. Copy task description
4. Convert "depends on" to explicit `dependencies` array
5. Convert time estimates to milliseconds

### Step 5: Add Context Requirements

For each agent:
1. Identify data dependencies from other agents
2. Add `context.inputs` for required data
3. Add `context.outputs` for produced data
4. Set TTL and persistence as needed

### Step 6: Add Error Handling

For critical operations:
1. Add `retryPolicy` for transient failures
2. Add `compensation` for rollback scenarios
3. Set `continueOnError` at phase level if appropriate

### Step 7: Add Metadata

Enhance discoverability:
1. Add author and version
2. Add tags and category
3. Add usage examples

### Step 8: Validate

1. Run JSON Schema validation
2. Check for circular dependencies
3. Verify all agent IDs exist in registry
4. Test with orchestration engine

### Migration Example

**v1.0 (Markdown):**
```markdown
# /analyze-code

Analyze codebase for issues.

1. Run static-analyzer (5 min)
2. Run linter (depends on 1, 3 min)
3. Run security-scanner (depends on 1, 3 min)
4. Generate report (depends on 2,3, 2 min)
```

**v2.0 (JSON):**
```json
{
  "version": "2.0.0",
  "name": "/analyze-code",
  "description": "Analyze codebase for issues",
  "phases": [
    {
      "id": "analysis",
      "name": "Code Analysis",
      "agents": [
        {
          "id": "static-analyzer",
          "agentId": "static-analyzer",
          "task": "Run static analysis",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              { "key": "static_analysis", "ttl": 3600 }
            ]
          }
        }
      ]
    },
    {
      "id": "validation",
      "name": "Parallel Validation",
      "parallel": true,
      "agents": [
        {
          "id": "linter",
          "agentId": "linter",
          "task": "Run linter",
          "dependencies": ["static-analyzer"],
          "estimatedTime": 180000,
          "context": {
            "inputs": [
              { "key": "static_analysis" }
            ],
            "outputs": [
              { "key": "lint_results" }
            ]
          }
        },
        {
          "id": "security-scanner",
          "agentId": "security-scanner",
          "task": "Run security scan",
          "dependencies": ["static-analyzer"],
          "estimatedTime": 180000,
          "context": {
            "inputs": [
              { "key": "static_analysis" }
            ],
            "outputs": [
              { "key": "security_results" }
            ]
          }
        }
      ]
    },
    {
      "id": "reporting",
      "name": "Report Generation",
      "agents": [
        {
          "id": "report",
          "agentId": "report-generator",
          "task": "Generate analysis report",
          "dependencies": ["linter", "security-scanner"],
          "estimatedTime": 120000,
          "context": {
            "inputs": [
              { "key": "lint_results" },
              { "key": "security_results" }
            ],
            "outputs": [
              { "key": "final_report", "persist": true }
            ]
          }
        }
      ]
    }
  ]
}
```

### Migration Checklist

- [ ] Command name starts with "/" and uses kebab-case
- [ ] Description is clear and under 200 characters
- [ ] All phases have unique IDs
- [ ] All agent nodes have unique IDs
- [ ] Dependencies reference valid node IDs
- [ ] No circular dependencies exist
- [ ] Agent IDs match registry entries
- [ ] Time estimates converted to milliseconds
- [ ] Context inputs/outputs defined
- [ ] Error handling added where needed
- [ ] JSON Schema validation passes
- [ ] Test with orchestration engine

## Breaking Changes

### 1. File Format
- **v1.0**: Markdown files (`.md`)
- **v2.0**: JSON files (`.json`)
- **Impact**: All commands must be converted to JSON
- **Migration**: Use migration guide to convert

### 2. Dependency Syntax
- **v1.0**: Text description "depends on step X"
- **v2.0**: Explicit `dependencies` array with node IDs
- **Impact**: Dependencies are now validated
- **Migration**: Map step numbers to node IDs

### 3. Time Format
- **v1.0**: Human-readable (e.g., "5 min")
- **v2.0**: Milliseconds (e.g., 300000)
- **Impact**: All times must be converted
- **Migration**: Multiply minutes by 60000

### 4. Agent References
- **v1.0**: Flexible text descriptions
- **v2.0**: Exact `agentId` from registry
- **Impact**: Agent names must match registry
- **Migration**: Map descriptions to registry IDs

### 5. Phase Structure
- **v1.0**: Implicit from markdown headings
- **v2.0**: Explicit phase objects with IDs
- **Impact**: Phases must be explicitly defined
- **Migration**: Convert headings to phase objects

### 6. Context Passing
- **v1.0**: Implicit data flow
- **v2.0**: Explicit context requirements
- **Impact**: Data dependencies must be declared
- **Migration**: Analyze data flow and add context

## FAQ

### Q: Can I still use markdown commands?

A: v1.0 markdown commands are supported for backward compatibility but don't benefit from advanced features like parallel execution, context sharing, or compensations. We recommend migrating to v2.0.

### Q: How do I handle dynamic dependencies?

A: Use the `skipCondition` field to conditionally execute nodes based on context values. The DAG remains static but execution can be dynamic.

### Q: What happens if an agent doesn't exist?

A: Validation will fail with a clear error message. The command won't execute until all agent IDs are valid.

### Q: Can phases have dependencies on other phases?

A: No, phases execute sequentially. Dependencies are only between agent nodes. Use agent dependencies to create complex execution flows.

### Q: How do I debug a v2.0 command?

A: The orchestration engine provides detailed logging including:
- DAG visualization
- Execution timeline
- Context state at each step
- Compensation triggers

### Q: Can I compose commands?

A: Yes, use the special `command` agentId to invoke other commands:
```json
{
  "id": "sub-command",
  "agentId": "command",
  "task": "/other-command",
  "dependencies": []
}
```

### Q: What's the maximum command size?

A: Commands should be under 1MB. Very large commands may indicate you should split into multiple composed commands.

### Q: How do I version commands?

A: Use semantic versioning in `metadata.version`. The orchestration engine can handle multiple versions of the same command.

### Q: Can I test commands locally?

A: Yes, use the orchestration engine's dry-run mode to validate and visualize execution without running agents.

### Q: How do I share context between commands?

A: Mark context outputs with `"persist": true` to make them available to subsequent commands in the same session.

---

This specification enables the full power of your orchestration engine while maintaining clarity and extensibility for future enhancements.