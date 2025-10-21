# Command Migration Patterns Guide v1.0 → v2.0

## Overview

This guide provides comprehensive patterns and strategies for migrating Claude Code commands from v1.0 (markdown-based) to v2.0 (JSON/DAG-based). The v2.0 format introduces explicit dependencies, parallel execution, context sharing, and advanced error recovery patterns.

### Benefits of Migration

- **Parallel Execution**: Automatic parallelization reduces execution time by 40-70%
- **Context Sharing**: Eliminate redundant work through shared analysis cache
- **Error Recovery**: Saga pattern compensations enable automatic rollback
- **Progress Tracking**: Real-time visibility with accurate time estimates
- **Resource Management**: Prevent deadlocks with explicit resource locking
- **Machine-Readable**: Enable automated validation and optimization

### Migration Complexity Levels

- **Simple (30 mins)**: Sequential commands with <5 agents
- **Moderate (1 hour)**: Parallel patterns with 5-10 agents
- **Complex (2-3 hours)**: Hierarchical patterns with 10-20 agents
- **Advanced (4+ hours)**: Multi-pattern orchestration with 20+ agents

## Pattern Catalog

### Pattern 1: Sequential Pipeline

**Description**: Simple chain of dependent steps executed in order.

**v1.0 Characteristics**:
- Numbered steps (1, 2, 3...)
- Each step "depends on" previous
- Linear execution flow
- Single execution thread

**v2.0 Transformation**:
```json
{
  "phases": [
    {
      "id": "pipeline",
      "name": "Sequential Pipeline",
      "parallel": false,
      "agents": [
        {"id": "step1", "dependencies": []},
        {"id": "step2", "dependencies": ["step1"]},
        {"id": "step3", "dependencies": ["step2"]}
      ]
    }
  ]
}
```

**Use Cases**:
- Build pipelines (compile → test → deploy)
- Data transformations (extract → transform → load)
- Document generation (analyze → generate → review)

**Migration Example**:

v1.0 (Markdown):
```markdown
1. Analyze codebase structure (5 minutes)
2. Generate documentation from code (depends on 1, 10 minutes)
3. Create API reference (depends on 2, 8 minutes)
4. Generate examples (depends on 3, 5 minutes)
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/document-api",
  "description": "Generate comprehensive API documentation",
  "phases": [
    {
      "id": "documentation",
      "name": "Documentation Generation",
      "parallel": false,
      "agents": [
        {
          "id": "analyze",
          "agentId": "codebase-analyzer",
          "task": "Analyze codebase structure",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {"key": "codebase_analysis", "ttl": 3600, "persist": true}
            ]
          }
        },
        {
          "id": "generate-docs",
          "agentId": "documentation-expert",
          "task": "Generate documentation from code",
          "dependencies": ["analyze"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "codebase_analysis"}],
            "outputs": [{"key": "documentation", "persist": true}]
          }
        },
        {
          "id": "api-reference",
          "agentId": "api-designer",
          "task": "Create API reference",
          "dependencies": ["generate-docs"],
          "estimatedTime": 480000,
          "context": {
            "inputs": [{"key": "documentation"}],
            "outputs": [{"key": "api_reference", "persist": true}]
          }
        },
        {
          "id": "examples",
          "agentId": "documentation-expert",
          "task": "Generate examples",
          "dependencies": ["api-reference"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [{"key": "api_reference"}],
            "outputs": [{"key": "examples", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

### Pattern 2: Fan-Out Parallel Analysis

**Description**: Single analysis phase followed by multiple parallel reviewers sharing the same context.

**v1.0 Characteristics**:
- Initial analysis step
- Multiple reviewers "depend on step 1"
- Implicit parallel execution
- Redundant analysis without context sharing

**v2.0 Transformation**:
```json
{
  "phases": [
    {
      "id": "analysis",
      "name": "Initial Analysis",
      "agents": [
        {"id": "analyzer", "dependencies": [], "context": {"outputs": [{"key": "shared_analysis", "ttl": 3600}]}}
      ]
    },
    {
      "id": "reviews",
      "name": "Parallel Reviews",
      "parallel": true,
      "maxParallelism": 5,
      "agents": [
        {"id": "review1", "dependencies": ["analyzer"], "context": {"inputs": [{"key": "shared_analysis"}]}},
        {"id": "review2", "dependencies": ["analyzer"], "context": {"inputs": [{"key": "shared_analysis"}]}},
        {"id": "review3", "dependencies": ["analyzer"], "context": {"inputs": [{"key": "shared_analysis"}]}}
      ]
    }
  ]
}
```

**Context Sharing Strategy**:
- Cache expensive analysis results with TTL
- All reviewers share the same context key
- Persist critical data across phases
- Use `passthrough: true` for complete context

**Use Cases**:
- Code reviews (/review-all pattern)
- Multi-tool security scanning
- Parallel test execution
- Multi-dimension quality analysis

**Migration Example**:

v1.0 (Markdown):
```markdown
## Code Review
1. Analyze codebase (5 minutes)
2. Quality review (depends on 1, 10 minutes)
3. Security review (depends on 1, 10 minutes)
4. Performance review (depends on 1, 10 minutes)
5. Synthesize all reviews (depends on 2,3,4, 5 minutes)
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/review-all",
  "description": "Comprehensive code review across multiple dimensions",
  "phases": [
    {
      "id": "analysis",
      "name": "Codebase Analysis",
      "agents": [
        {
          "id": "analyzer",
          "agentId": "codebase-analyzer",
          "task": "Analyze codebase structure and metrics",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {"key": "codebase_analysis", "ttl": 3600, "persist": true},
              {"key": "file_list", "ttl": 3600, "persist": true}
            ]
          }
        }
      ]
    },
    {
      "id": "reviews",
      "name": "Parallel Reviews",
      "parallel": true,
      "maxParallelism": 3,
      "continueOnError": true,
      "agents": [
        {
          "id": "quality",
          "agentId": "quality-reviewer",
          "task": "Review code quality and patterns",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "priority": 10,
          "context": {
            "inputs": [
              {"key": "codebase_analysis", "required": true},
              {"key": "file_list", "required": true}
            ],
            "outputs": [{"key": "quality_review", "ttl": 3600}]
          }
        },
        {
          "id": "security",
          "agentId": "security-reviewer",
          "task": "Review security vulnerabilities",
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
              {"key": "codebase_analysis", "required": true},
              {"key": "file_list", "required": true}
            ],
            "outputs": [{"key": "security_review", "ttl": 3600}]
          }
        },
        {
          "id": "performance",
          "agentId": "performance-reviewer",
          "task": "Review performance bottlenecks",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "codebase_analysis", "required": true}],
            "outputs": [{"key": "performance_review", "ttl": 3600}]
          }
        }
      ]
    },
    {
      "id": "synthesis",
      "name": "Final Synthesis",
      "agents": [
        {
          "id": "synthesizer",
          "agentId": "senior-reviewer",
          "task": "Synthesize all reviews and provide recommendations",
          "dependencies": ["quality", "security", "performance"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [
              {"key": "quality_review", "required": false, "default": "Not performed"},
              {"key": "security_review", "required": false, "default": "Not performed"},
              {"key": "performance_review", "required": false, "default": "Not performed"}
            ],
            "outputs": [{"key": "final_report", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

### Pattern 3: Hierarchical Decomposition

**Description**: Complex multi-phase tasks with nested sub-tasks and phase grouping.

**v1.0 Characteristics**:
- Multiple phases with headers (### Phase 1, ### Phase 2)
- Nested sub-tasks within phases
- Complex inter-phase dependencies
- Mixed parallel and sequential execution

**v2.0 Transformation**:
```json
{
  "phases": [
    {
      "id": "phase1",
      "name": "Foundation Phase",
      "agents": [/* foundation tasks */]
    },
    {
      "id": "phase2",
      "name": "Implementation Phase",
      "parallel": true,
      "agents": [/* parallel implementation tasks */]
    },
    {
      "id": "phase3",
      "name": "Validation Phase",
      "agents": [/* validation tasks depending on phase2 */]
    }
  ]
}
```

**Use Cases**:
- Feature implementation (/implement-epic)
- System hardening (/security-fortress)
- Multi-layer architecture design
- Complex refactoring projects

**Migration Example**:

v1.0 (Markdown):
```markdown
### Phase 1: Threat Modeling (0-20 mins)
1. threat-modeler - Create threat model
2. attack-surface-mapper - Map attack surfaces (depends on 1)
3. asset-identifier - Identify critical assets (depends on 1)

### Phase 2: Static Analysis (20-40 mins)
4. code-scanner - SAST testing (depends on 3)
5. dependency-auditor - Scan dependencies (depends on 3)
6. secrets-detective - Hunt for credentials (depends on 3)

### Phase 3: Dynamic Analysis (40-70 mins)
7. penetration-tester - OWASP testing (depends on 4,5,6)
8. injection-specialist - Injection testing (depends on 7)
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/security-fortress",
  "description": "Complete security hardening with threat modeling and testing",
  "phases": [
    {
      "id": "threat-modeling",
      "name": "Threat Modeling",
      "parallel": false,
      "agents": [
        {
          "id": "threat-modeler",
          "agentId": "threat-modeler",
          "task": "Create threat model using STRIDE methodology",
          "dependencies": [],
          "estimatedTime": 600000,
          "context": {
            "outputs": [
              {"key": "threat_model", "persist": true},
              {"key": "attack_vectors", "persist": true}
            ]
          }
        },
        {
          "id": "attack-mapper",
          "agentId": "attack-surface-mapper",
          "task": "Map all attack surfaces and entry points",
          "dependencies": ["threat-modeler"],
          "estimatedTime": 480000,
          "context": {
            "inputs": [{"key": "threat_model"}],
            "outputs": [{"key": "attack_surface", "persist": true}]
          }
        },
        {
          "id": "asset-identifier",
          "agentId": "asset-identifier",
          "task": "Identify critical assets and data flows",
          "dependencies": ["threat-modeler"],
          "estimatedTime": 420000,
          "context": {
            "inputs": [{"key": "threat_model"}],
            "outputs": [{"key": "critical_assets", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "static-analysis",
      "name": "Static Analysis",
      "parallel": true,
      "maxParallelism": 3,
      "agents": [
        {
          "id": "code-scanner",
          "agentId": "code-scanner-sast",
          "task": "Static application security testing",
          "dependencies": ["asset-identifier"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [{"key": "critical_assets"}],
            "outputs": [{"key": "sast_results", "ttl": 7200}]
          }
        },
        {
          "id": "dependency-auditor",
          "agentId": "dependency-auditor",
          "task": "Scan dependencies for known vulnerabilities",
          "dependencies": ["asset-identifier"],
          "estimatedTime": 600000,
          "retryPolicy": {
            "maxAttempts": 3,
            "strategy": "exponential",
            "initialDelay": 2000
          },
          "context": {
            "inputs": [{"key": "critical_assets"}],
            "outputs": [{"key": "dependency_vulns", "ttl": 7200}]
          }
        },
        {
          "id": "secrets-detective",
          "agentId": "secrets-detective",
          "task": "Hunt for exposed credentials and API keys",
          "dependencies": ["asset-identifier"],
          "estimatedTime": 720000,
          "context": {
            "inputs": [{"key": "critical_assets"}],
            "outputs": [{"key": "exposed_secrets", "ttl": 7200}]
          }
        }
      ]
    },
    {
      "id": "dynamic-analysis",
      "name": "Dynamic Analysis",
      "parallel": true,
      "agents": [
        {
          "id": "penetration-tester",
          "agentId": "penetration-tester-web",
          "task": "OWASP Top 10 testing",
          "dependencies": ["code-scanner", "dependency-auditor", "secrets-detective"],
          "estimatedTime": 1800000,
          "context": {
            "inputs": [
              {"key": "sast_results"},
              {"key": "dependency_vulns"},
              {"key": "exposed_secrets"}
            ],
            "outputs": [{"key": "pentest_results", "persist": true}]
          }
        },
        {
          "id": "injection-specialist",
          "agentId": "injection-specialist",
          "task": "SQL, NoSQL, command injection testing",
          "dependencies": ["penetration-tester"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [{"key": "pentest_results"}],
            "outputs": [{"key": "injection_vulns", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

### Pattern 4: Conditional Execution

**Description**: Dynamic task execution based on runtime conditions.

**v1.0 Characteristics**:
- "If X then Y" logic in descriptions
- "Skip if..." comments
- Manual condition checking
- Implicit branching logic

**v2.0 Transformation**:
```json
{
  "agents": [
    {
      "id": "conditional-task",
      "skipCondition": {
        "type": "context",
        "expression": "coverage_percentage >= 85",
        "skipMessage": "Coverage already meets threshold"
      }
    }
  ]
}
```

**Condition Types**:
- `context`: Check context values
- `file_exists`: Check file existence
- `command_success`: Check previous command result
- `custom`: Custom condition evaluation

**Use Cases**:
- Skip tests if no code changes
- Conditional deployment based on environment
- Adaptive testing based on coverage
- Skip frontend tasks for backend-only projects

**Migration Example**:

v1.0 (Markdown):
```markdown
1. Run unit tests and measure coverage
2. If coverage < 85%, generate additional tests
3. If frontend exists, run accessibility review
4. If database changes, run migration validation
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/adaptive-test",
  "description": "Adaptive testing based on coverage",
  "phases": [
    {
      "id": "initial-test",
      "name": "Initial Testing",
      "agents": [
        {
          "id": "unit-tests",
          "agentId": "test-engineer",
          "task": "Run unit tests and measure coverage",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {"key": "coverage_percentage", "persist": true},
              {"key": "has_frontend", "persist": true},
              {"key": "database_changes", "persist": true}
            ]
          }
        }
      ]
    },
    {
      "id": "conditional-tasks",
      "name": "Conditional Tasks",
      "parallel": true,
      "agents": [
        {
          "id": "coverage-improvement",
          "agentId": "test-engineer",
          "task": "Generate additional tests for uncovered code",
          "dependencies": ["unit-tests"],
          "estimatedTime": 600000,
          "skipCondition": {
            "type": "context",
            "expression": "coverage_percentage >= 85",
            "skipMessage": "Coverage already meets 85% threshold"
          },
          "context": {
            "outputs": [{"key": "additional_tests"}]
          }
        },
        {
          "id": "accessibility-review",
          "agentId": "accessibility-reviewer",
          "task": "Review accessibility compliance",
          "dependencies": ["unit-tests"],
          "estimatedTime": 600000,
          "skipCondition": {
            "type": "context",
            "expression": "has_frontend == false",
            "skipMessage": "No frontend detected, skipping accessibility"
          },
          "context": {
            "outputs": [{"key": "accessibility_report"}]
          }
        },
        {
          "id": "migration-validation",
          "agentId": "database-architect",
          "task": "Validate database migrations",
          "dependencies": ["unit-tests"],
          "estimatedTime": 480000,
          "skipCondition": {
            "type": "context",
            "expression": "database_changes == false",
            "skipMessage": "No database changes detected"
          },
          "context": {
            "outputs": [{"key": "migration_validation"}]
          }
        }
      ]
    }
  ]
}
```

### Pattern 5: Saga Compensation

**Description**: Reversible operations with automatic rollback on failure.

**v1.0 Characteristics**:
- "Rollback if..." comments
- Manual rollback steps
- No automatic compensation
- Error recovery undefined

**v2.0 Transformation**:
```json
{
  "agents": [
    {
      "id": "risky-operation",
      "compensation": {
        "type": "custom",
        "description": "Rollback database changes",
        "agentId": "database-architect",
        "task": "Execute reverse migration",
        "compensateOn": ["error", "validation"]
      }
    }
  ]
}
```

**Compensation Types**:
- `none`: No compensation needed
- `retry`: Retry the operation
- `rollback`: Rollback to previous state
- `custom`: Custom agent compensation
- `cascade`: Trigger dependent compensations

**Use Cases**:
- Database migrations
- Infrastructure changes
- Deployment operations
- File system modifications
- Third-party integrations

**Migration Example**:

v1.0 (Markdown):
```markdown
1. Create database backup
2. Apply schema migration (rollback on failure)
3. Migrate data (restore from backup on failure)
4. Validate integrity (trigger rollback if invalid)
5. Clean up temporary tables
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/database-migration",
  "description": "Database migration with automatic rollback",
  "resources": {
    "locks": [
      {"resource": "database", "type": "exclusive", "priority": 100}
    ],
    "maxWaitTime": 60000
  },
  "phases": [
    {
      "id": "preparation",
      "name": "Migration Preparation",
      "agents": [
        {
          "id": "backup",
          "agentId": "database-architect",
          "task": "Create database backup",
          "dependencies": [],
          "estimatedTime": 300000,
          "compensation": {
            "type": "none",
            "description": "Backup is kept for safety"
          },
          "context": {
            "outputs": [{"key": "backup_id", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "migration",
      "name": "Execute Migration",
      "continueOnError": false,
      "agents": [
        {
          "id": "migrate-schema",
          "agentId": "database-architect",
          "task": "Apply schema migrations",
          "dependencies": ["backup"],
          "estimatedTime": 180000,
          "compensation": {
            "type": "custom",
            "description": "Rollback schema to previous version",
            "agentId": "database-architect",
            "task": "Execute reverse migration scripts",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [{"key": "backup_id"}],
            "outputs": [{"key": "migration_version", "persist": true}]
          }
        },
        {
          "id": "migrate-data",
          "agentId": "database-architect",
          "task": "Transform and migrate data",
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
            "task": "Restore from backup_id",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [{"key": "backup_id"}, {"key": "migration_version"}],
            "outputs": [{"key": "rows_migrated", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "validation",
      "name": "Post-Migration Validation",
      "agents": [
        {
          "id": "validate-integrity",
          "agentId": "database-architect",
          "task": "Validate data integrity",
          "dependencies": ["migrate-data"],
          "estimatedTime": 120000,
          "compensation": {
            "type": "cascade",
            "description": "Trigger full rollback if validation fails",
            "rollbackTo": "backup",
            "compensateOn": ["validation"]
          },
          "context": {
            "inputs": [{"key": "rows_migrated"}],
            "outputs": [{"key": "integrity_valid"}]
          }
        }
      ]
    },
    {
      "id": "cleanup",
      "name": "Cleanup",
      "agents": [
        {
          "id": "cleanup",
          "agentId": "database-architect",
          "task": "Clean up temporary tables",
          "dependencies": ["validate-integrity"],
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

### Pattern 6: Resource Locking

**Description**: Prevent conflicts through explicit resource lock management.

**v1.0 Characteristics**:
- Implicit serialization comments
- "Wait for X to complete"
- Manual conflict avoidance
- No deadlock prevention

**v2.0 Transformation**:
```json
{
  "resources": {
    "locks": [
      {"resource": "database", "type": "exclusive"},
      {"resource": "config-file", "type": "shared"}
    ],
    "maxWaitTime": 60000
  }
}
```

**Lock Types**:
- `exclusive`: Single writer access
- `shared`: Multiple reader access
- `upgrade`: Upgradeable from shared to exclusive

**Use Cases**:
- Database operations
- File write operations
- Configuration updates
- Deployment operations
- Cache invalidation

**Migration Example**:

v1.0 (Markdown):
```markdown
1. Update configuration file (exclusive access needed)
2. Reload application config (wait for 1)
3. Update database schema (exclusive DB lock)
4. Run data migration (depends on 3)
```

v2.0 (JSON):
```json
{
  "version": "2.0.0",
  "name": "/config-update",
  "description": "Update configuration with proper locking",
  "resources": {
    "locks": [
      {"resource": "config-file", "type": "exclusive", "priority": 50},
      {"resource": "database", "type": "exclusive", "priority": 100}
    ],
    "maxWaitTime": 30000
  },
  "phases": [
    {
      "id": "config-update",
      "name": "Configuration Update",
      "agents": [
        {
          "id": "update-config",
          "agentId": "devops-automator",
          "task": "Update configuration file",
          "dependencies": [],
          "estimatedTime": 60000,
          "context": {
            "outputs": [{"key": "config_version", "persist": true}]
          }
        },
        {
          "id": "reload-config",
          "agentId": "devops-automator",
          "task": "Reload application configuration",
          "dependencies": ["update-config"],
          "estimatedTime": 30000,
          "retryPolicy": {
            "maxAttempts": 3,
            "strategy": "linear",
            "initialDelay": 2000
          }
        }
      ]
    },
    {
      "id": "database-update",
      "name": "Database Update",
      "agents": [
        {
          "id": "update-schema",
          "agentId": "database-architect",
          "task": "Update database schema",
          "dependencies": ["reload-config"],
          "estimatedTime": 180000,
          "context": {
            "inputs": [{"key": "config_version"}],
            "outputs": [{"key": "schema_version", "persist": true}]
          }
        },
        {
          "id": "migrate-data",
          "agentId": "database-architect",
          "task": "Run data migration",
          "dependencies": ["update-schema"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [{"key": "schema_version"}]
          }
        }
      ]
    }
  ]
}
```

## Step-by-Step Migration Process

### Step 1: Identify Pattern

**Pattern Recognition Checklist**:

1. **Sequential Pipeline?**
   - Linear numbered steps
   - Each depends on previous
   - No parallel execution mentioned

2. **Fan-Out Parallel?**
   - Single analysis step
   - Multiple steps depend on same step
   - Reviews/scans/tests in parallel

3. **Hierarchical Decomposition?**
   - Phase headers (###)
   - Complex nested structure
   - Mixed parallel/sequential

4. **Conditional Execution?**
   - "If X then Y" statements
   - "Skip if" conditions
   - Environment-dependent tasks

5. **Saga Compensation?**
   - "Rollback on failure"
   - Destructive operations
   - State changes mentioned

6. **Resource Locking?**
   - "Exclusive access"
   - "Wait for" statements
   - Shared resource conflicts

**Multi-Pattern Commands**:
Commands can combine multiple patterns. For example, /security-fortress uses:
- Hierarchical Decomposition (7 phases)
- Fan-Out Parallel (multiple scanners)
- Sequential Pipeline (within phases)

### Step 2: Extract Dependencies

**Dependency Mapping Process**:

1. **Create Node Inventory**:
   ```
   Step 1 → node ID: "analyzer"
   Step 2 → node ID: "reviewer"
   Step 3 → node ID: "reporter"
   ```

2. **Map Explicit Dependencies**:
   ```
   "depends on 1" → dependencies: ["analyzer"]
   "depends on 1,2" → dependencies: ["analyzer", "reviewer"]
   ```

3. **Identify Implicit Dependencies**:
   - Data flow dependencies (needs output from X)
   - Resource dependencies (needs same file/DB)
   - Logical dependencies (must happen after X)

4. **Build Dependency Matrix**:
   ```
   | Node      | Depends On        | Provides Data |
   |-----------|------------------|---------------|
   | analyzer  | []               | analysis      |
   | reviewer  | ["analyzer"]     | review        |
   | reporter  | ["reviewer"]     | report        |
   ```

### Step 3: Add Timing Estimates

**Time Estimation Guidelines**:

1. **Convert Human-Readable to Milliseconds**:
   - "5 minutes" → 300000
   - "30 seconds" → 30000
   - "2 hours" → 7200000

2. **Estimation Formula**:
   ```
   Base Time + (Complexity Factor × Size Factor)
   ```

3. **Common Agent Timings**:
   | Agent Type | Simple | Moderate | Complex |
   |------------|--------|----------|---------|
   | Analyzer   | 3-5 min| 5-10 min | 10-20 min|
   | Reviewer   | 5-10 min| 10-15 min| 15-30 min|
   | Generator  | 10-15 min| 15-30 min| 30-60 min|
   | Tester     | 5-10 min| 10-20 min| 20-40 min|

4. **Add Buffer for Uncertainty**:
   - Well-known tasks: +20%
   - New tasks: +50%
   - Complex tasks: +100%

5. **Set Timeout = Estimated × 3**:
   ```json
   {
     "estimatedTime": 300000,
     "timeout": 900000
   }
   ```

### Step 4: Define Context Flow

**Context Mapping Process**:

1. **Identify Shared Data**:
   - Analysis results used by multiple agents
   - Configuration needed across phases
   - State that must persist

2. **Define Context Keys**:
   ```json
   "context": {
     "outputs": [
       {"key": "codebase_analysis", "ttl": 3600, "persist": true}
     ]
   }
   ```

3. **Map Input Requirements**:
   ```json
   "context": {
     "inputs": [
       {"key": "codebase_analysis", "required": true},
       {"key": "optional_data", "required": false, "default": "N/A"}
     ]
   }
   ```

4. **TTL Guidelines**:
   - Expensive analysis: 3600-7200 seconds
   - Temporary data: 300-600 seconds
   - Critical state: persist: true

5. **Context Optimization**:
   - Share expensive computations
   - Cache intermediate results
   - Use passthrough sparingly

### Step 5: Add Compensation (if needed)

**When Compensation is Required**:

1. **Destructive Operations**:
   - Database changes
   - File modifications
   - Infrastructure updates
   - API calls with side effects

2. **Critical Path Operations**:
   - Payment processing
   - User data changes
   - Configuration updates
   - Deployment operations

3. **Compensation Design**:
   ```json
   "compensation": {
     "type": "custom",
     "description": "What this does",
     "agentId": "compensator",
     "task": "Specific rollback action",
     "compensateOn": ["error", "validation", "timeout"]
   }
   ```

4. **Compensation Order**:
   - Compensate in reverse dependency order
   - Child compensations before parent
   - Resource release last

### Step 6: Validate DAG

**Validation Checklist**:

1. **Unique IDs**:
   ```bash
   # Check for duplicate IDs
   cat command.json | jq '.phases[].agents[].id' | sort | uniq -d
   ```

2. **Valid Dependencies**:
   ```bash
   # List all dependencies
   cat command.json | jq '.phases[].agents[].dependencies[]'
   # List all IDs
   cat command.json | jq '.phases[].agents[].id'
   ```

3. **Circular Dependencies**:
   - Build adjacency list
   - Run topological sort
   - Check for cycles

4. **Agent Registry**:
   - Verify all agentId values exist
   - Check agent capabilities match tasks

5. **Time Validation**:
   - Timeout > estimatedTime
   - Phase timeout > sum of serial tasks
   - Total time reasonable

6. **Context Validation**:
   - All inputs have producers
   - No conflicting output keys
   - TTL values positive

## Anti-Patterns to Avoid

### Anti-Pattern 1: Over-Serialization

**Mistake**: Adding unnecessary dependencies that prevent parallelization.

**Example**:
```json
// BAD: Unnecessary serialization
{
  "agents": [
    {"id": "test1", "dependencies": []},
    {"id": "test2", "dependencies": ["test1"]},  // Could run parallel
    {"id": "test3", "dependencies": ["test2"]}   // Could run parallel
  ]
}

// GOOD: Proper parallelization
{
  "agents": [
    {"id": "analyze", "dependencies": []},
    {"id": "test1", "dependencies": ["analyze"]},
    {"id": "test2", "dependencies": ["analyze"]},
    {"id": "test3", "dependencies": ["analyze"]}
  ]
}
```

**Impact**: 3x longer execution time
**Fix**: Only add dependencies where data flows or order matters

### Anti-Pattern 2: Missing Context Sharing

**Mistake**: Not caching expensive analysis that multiple agents need.

**Example**:
```json
// BAD: Each reviewer re-analyzes
{
  "agents": [
    {"id": "quality", "task": "Analyze and review quality"},
    {"id": "security", "task": "Analyze and review security"}
  ]
}

// GOOD: Share analysis context
{
  "agents": [
    {
      "id": "analyzer",
      "context": {"outputs": [{"key": "analysis", "ttl": 3600}]}
    },
    {
      "id": "quality",
      "dependencies": ["analyzer"],
      "context": {"inputs": [{"key": "analysis"}]}
    },
    {
      "id": "security",
      "dependencies": ["analyzer"],
      "context": {"inputs": [{"key": "analysis"}]}
    }
  ]
}
```

**Impact**: 2x redundant computation
**Fix**: Extract shared analysis, cache with appropriate TTL

### Anti-Pattern 3: Circular Dependencies

**Mistake**: Creating dependency cycles.

**Example**:
```json
// BAD: Circular dependency
{
  "agents": [
    {"id": "frontend", "dependencies": ["backend"]},
    {"id": "backend", "dependencies": ["frontend"]}  // CIRCULAR!
  ]
}

// GOOD: Resolve with shared dependency
{
  "agents": [
    {"id": "api-design", "dependencies": []},
    {"id": "frontend", "dependencies": ["api-design"]},
    {"id": "backend", "dependencies": ["api-design"]}
  ]
}
```

**Impact**: Command fails validation
**Fix**: Restructure dependencies or merge circular nodes

### Anti-Pattern 4: Incorrect Compensation Order

**Mistake**: Compensating in wrong order, leaving partial state.

**Example**:
```json
// BAD: Parent compensates before child
{
  "agents": [
    {
      "id": "create-resource",
      "compensation": {"type": "custom", "task": "delete resource"}
    },
    {
      "id": "configure-resource",
      "dependencies": ["create-resource"],
      "compensation": {"type": "custom", "task": "reset config"}
    }
  ]
}

// GOOD: Reverse dependency order
{
  "agents": [
    {
      "id": "create-resource",
      "compensation": {
        "type": "cascade",
        "description": "Delete after dependents compensate"
      }
    },
    {
      "id": "configure-resource",
      "dependencies": ["create-resource"],
      "compensation": {
        "type": "custom",
        "task": "Reset config before resource deletion"
      }
    }
  ]
}
```

**Impact**: Incomplete rollback, orphaned resources
**Fix**: Use cascade type or explicit reverse order

### Anti-Pattern 5: Missing Timeouts

**Mistake**: No timeout on long-running or potentially hanging operations.

**Example**:
```json
// BAD: No timeout
{
  "agents": [
    {
      "id": "external-api-call",
      "estimatedTime": 60000
      // Missing timeout!
    }
  ]
}

// GOOD: Proper timeout
{
  "agents": [
    {
      "id": "external-api-call",
      "estimatedTime": 60000,
      "timeout": 180000,
      "retryPolicy": {
        "maxAttempts": 3,
        "strategy": "exponential"
      }
    }
  ]
}
```

**Impact**: Hung execution, no progress
**Fix**: Always set timeout = 3× estimated time

## Code Transformation Examples

### Example 1: Simple Review → Parallel Analysis

**v1.0 (Markdown)**:
```markdown
# Code Review

Review the codebase for issues.

1. Analyze codebase structure (5 min)
2. Check code quality (depends on 1, 10 min)
3. Check security issues (depends on 1, 10 min)
4. Generate review report (depends on 2,3, 5 min)
```

**v2.0 (JSON)**:
```json
{
  "version": "2.0.0",
  "name": "/code-review",
  "description": "Review the codebase for issues",
  "phases": [
    {
      "id": "analysis",
      "name": "Analysis",
      "agents": [
        {
          "id": "analyzer",
          "agentId": "codebase-analyzer",
          "task": "Analyze codebase structure",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {"key": "codebase_structure", "ttl": 3600}
            ]
          }
        }
      ]
    },
    {
      "id": "review",
      "name": "Parallel Review",
      "parallel": true,
      "agents": [
        {
          "id": "quality-check",
          "agentId": "quality-reviewer",
          "task": "Check code quality",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "codebase_structure"}],
            "outputs": [{"key": "quality_issues"}]
          }
        },
        {
          "id": "security-check",
          "agentId": "security-reviewer",
          "task": "Check security issues",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "codebase_structure"}],
            "outputs": [{"key": "security_issues"}]
          }
        }
      ]
    },
    {
      "id": "report",
      "name": "Report Generation",
      "agents": [
        {
          "id": "generate-report",
          "agentId": "report-generator",
          "task": "Generate review report",
          "dependencies": ["quality-check", "security-check"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [
              {"key": "quality_issues"},
              {"key": "security_issues"}
            ],
            "outputs": [{"key": "review_report", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

**Performance Improvement**: 30 min → 20 min (33% faster)

### Example 2: Test Generation → Adaptive Testing

**v1.0 (Markdown)**:
```markdown
# Generate Tests

Create comprehensive test suite.

1. Analyze code coverage (5 min)
2. Generate unit tests (depends on 1, 15 min)
3. Generate integration tests (depends on 2, 10 min)
4. Run all tests (depends on 3, 5 min)
5. If coverage < 80%, generate more tests (depends on 4, 10 min)
```

**v2.0 (JSON)**:
```json
{
  "version": "2.0.0",
  "name": "/generate-tests",
  "description": "Create comprehensive test suite",
  "phases": [
    {
      "id": "analysis",
      "name": "Coverage Analysis",
      "agents": [
        {
          "id": "analyze-coverage",
          "agentId": "test-engineer",
          "task": "Analyze code coverage",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {"key": "coverage_report", "persist": true},
              {"key": "coverage_percentage", "persist": true}
            ]
          }
        }
      ]
    },
    {
      "id": "test-generation",
      "name": "Test Generation",
      "parallel": true,
      "agents": [
        {
          "id": "unit-tests",
          "agentId": "test-engineer",
          "task": "Generate unit tests",
          "dependencies": ["analyze-coverage"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [{"key": "coverage_report"}],
            "outputs": [{"key": "unit_tests", "persist": true}]
          }
        },
        {
          "id": "integration-tests",
          "agentId": "test-engineer",
          "task": "Generate integration tests",
          "dependencies": ["analyze-coverage"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "coverage_report"}],
            "outputs": [{"key": "integration_tests", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "test-execution",
      "name": "Test Execution",
      "agents": [
        {
          "id": "run-tests",
          "agentId": "test-engineer",
          "task": "Run all tests",
          "dependencies": ["unit-tests", "integration-tests"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [
              {"key": "unit_tests"},
              {"key": "integration_tests"}
            ],
            "outputs": [
              {"key": "test_results", "persist": true},
              {"key": "new_coverage", "persist": true}
            ]
          }
        }
      ]
    },
    {
      "id": "adaptive-generation",
      "name": "Adaptive Test Generation",
      "agents": [
        {
          "id": "additional-tests",
          "agentId": "test-engineer",
          "task": "Generate additional tests for uncovered code",
          "dependencies": ["run-tests"],
          "estimatedTime": 600000,
          "skipCondition": {
            "type": "context",
            "expression": "new_coverage >= 80",
            "skipMessage": "Coverage meets 80% threshold"
          },
          "context": {
            "inputs": [{"key": "test_results"}],
            "outputs": [{"key": "additional_tests", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

**Performance Improvement**: 45 min → 25 min (44% faster with parallelization)

### Example 3: Security Scan → Multi-Layer Security

**v1.0 (Markdown)**:
```markdown
# Security Audit

Comprehensive security assessment.

## Phase 1: Static Analysis
1. Run SAST scanner (15 min)
2. Check dependencies (depends on 1, 10 min)
3. Find exposed secrets (depends on 1, 10 min)

## Phase 2: Dynamic Testing
4. Run penetration tests (depends on 2,3, 30 min)
5. Test authentication (depends on 4, 15 min)
6. Test for injections (depends on 4, 15 min)

## Phase 3: Reporting
7. Generate security report (depends on 5,6, 10 min)
```

**v2.0 (JSON)**:
```json
{
  "version": "2.0.0",
  "name": "/security-audit",
  "description": "Comprehensive security assessment",
  "phases": [
    {
      "id": "static-analysis",
      "name": "Static Analysis",
      "parallel": false,
      "agents": [
        {
          "id": "sast-scan",
          "agentId": "code-scanner-sast",
          "task": "Run SAST scanner",
          "dependencies": [],
          "estimatedTime": 900000,
          "context": {
            "outputs": [
              {"key": "sast_results", "ttl": 7200, "persist": true}
            ]
          }
        }
      ]
    },
    {
      "id": "dependency-analysis",
      "name": "Dependency Analysis",
      "parallel": true,
      "maxParallelism": 2,
      "agents": [
        {
          "id": "check-deps",
          "agentId": "dependency-auditor",
          "task": "Check dependencies for vulnerabilities",
          "dependencies": ["sast-scan"],
          "estimatedTime": 600000,
          "retryPolicy": {
            "maxAttempts": 2,
            "strategy": "exponential",
            "initialDelay": 2000
          },
          "context": {
            "inputs": [{"key": "sast_results"}],
            "outputs": [{"key": "dependency_vulns", "ttl": 7200}]
          }
        },
        {
          "id": "secret-scan",
          "agentId": "secrets-detective",
          "task": "Find exposed secrets",
          "dependencies": ["sast-scan"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [{"key": "sast_results"}],
            "outputs": [{"key": "exposed_secrets", "ttl": 7200}]
          }
        }
      ]
    },
    {
      "id": "dynamic-testing",
      "name": "Dynamic Testing",
      "parallel": false,
      "agents": [
        {
          "id": "pentest",
          "agentId": "penetration-tester-web",
          "task": "Run penetration tests",
          "dependencies": ["check-deps", "secret-scan"],
          "estimatedTime": 1800000,
          "timeout": 3600000,
          "context": {
            "inputs": [
              {"key": "dependency_vulns"},
              {"key": "exposed_secrets"}
            ],
            "outputs": [{"key": "pentest_results", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "specialized-testing",
      "name": "Specialized Security Tests",
      "parallel": true,
      "agents": [
        {
          "id": "auth-test",
          "agentId": "authentication-breaker",
          "task": "Test authentication mechanisms",
          "dependencies": ["pentest"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [{"key": "pentest_results"}],
            "outputs": [{"key": "auth_vulns"}]
          }
        },
        {
          "id": "injection-test",
          "agentId": "injection-specialist",
          "task": "Test for injection vulnerabilities",
          "dependencies": ["pentest"],
          "estimatedTime": 900000,
          "context": {
            "inputs": [{"key": "pentest_results"}],
            "outputs": [{"key": "injection_vulns"}]
          }
        }
      ]
    },
    {
      "id": "reporting",
      "name": "Security Reporting",
      "agents": [
        {
          "id": "report",
          "agentId": "security-reporter",
          "task": "Generate comprehensive security report",
          "dependencies": ["auth-test", "injection-test"],
          "estimatedTime": 600000,
          "context": {
            "inputs": [
              {"key": "sast_results"},
              {"key": "dependency_vulns"},
              {"key": "exposed_secrets"},
              {"key": "pentest_results"},
              {"key": "auth_vulns"},
              {"key": "injection_vulns"}
            ],
            "outputs": [{"key": "security_report", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

**Performance Improvement**: 105 min → 65 min (38% faster)

### Example 4: Deployment → Safe Deployment with Rollback

**v1.0 (Markdown)**:
```markdown
# Deploy to Production

Deploy application with zero downtime.

1. Run pre-deployment tests (10 min)
2. Create database backup (5 min)
3. Apply database migrations (depends on 2, 10 min, rollback on failure)
4. Deploy to canary (depends on 3, 5 min)
5. Run smoke tests (depends on 4, 5 min)
6. Deploy to production (depends on 5, 10 min, rollback on failure)
7. Run health checks (depends on 6, 3 min)
```

**v2.0 (JSON)**:
```json
{
  "version": "2.0.0",
  "name": "/deploy-production",
  "description": "Deploy application with zero downtime",
  "resources": {
    "locks": [
      {"resource": "production-env", "type": "exclusive", "priority": 100},
      {"resource": "database", "type": "exclusive", "priority": 90}
    ],
    "maxWaitTime": 120000
  },
  "phases": [
    {
      "id": "pre-deployment",
      "name": "Pre-Deployment Validation",
      "parallel": true,
      "agents": [
        {
          "id": "pre-tests",
          "agentId": "test-engineer",
          "task": "Run pre-deployment test suite",
          "dependencies": [],
          "estimatedTime": 600000,
          "context": {
            "outputs": [{"key": "test_passed", "persist": true}]
          }
        },
        {
          "id": "backup",
          "agentId": "database-architect",
          "task": "Create database backup",
          "dependencies": [],
          "estimatedTime": 300000,
          "compensation": {
            "type": "none",
            "description": "Backup retained for safety"
          },
          "context": {
            "outputs": [{"key": "backup_id", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "database-migration",
      "name": "Database Migration",
      "continueOnError": false,
      "agents": [
        {
          "id": "migrate-db",
          "agentId": "database-architect",
          "task": "Apply database migrations",
          "dependencies": ["backup", "pre-tests"],
          "estimatedTime": 600000,
          "compensation": {
            "type": "custom",
            "description": "Rollback database to previous version",
            "agentId": "database-architect",
            "task": "Execute rollback migration from backup_id",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [
              {"key": "backup_id"},
              {"key": "test_passed"}
            ],
            "outputs": [{"key": "migration_complete", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "canary-deployment",
      "name": "Canary Deployment",
      "agents": [
        {
          "id": "deploy-canary",
          "agentId": "devops-automator",
          "task": "Deploy to canary environment",
          "dependencies": ["migrate-db"],
          "estimatedTime": 300000,
          "compensation": {
            "type": "custom",
            "description": "Remove canary deployment",
            "agentId": "devops-automator",
            "task": "Rollback canary to previous version",
            "compensateOn": ["error", "validation"]
          },
          "context": {
            "inputs": [{"key": "migration_complete"}],
            "outputs": [{"key": "canary_url", "persist": true}]
          }
        },
        {
          "id": "smoke-tests",
          "agentId": "test-engineer",
          "task": "Run smoke tests on canary",
          "dependencies": ["deploy-canary"],
          "estimatedTime": 300000,
          "retryPolicy": {
            "maxAttempts": 3,
            "strategy": "linear",
            "initialDelay": 5000
          },
          "compensation": {
            "type": "cascade",
            "description": "Trigger canary rollback if tests fail",
            "compensateOn": ["validation"]
          },
          "context": {
            "inputs": [{"key": "canary_url"}],
            "outputs": [{"key": "smoke_test_passed", "persist": true}]
          }
        }
      ]
    },
    {
      "id": "production-deployment",
      "name": "Production Deployment",
      "agents": [
        {
          "id": "deploy-prod",
          "agentId": "devops-automator",
          "task": "Deploy to production using blue-green strategy",
          "dependencies": ["smoke-tests"],
          "estimatedTime": 600000,
          "compensation": {
            "type": "custom",
            "description": "Switch back to blue environment",
            "agentId": "devops-automator",
            "task": "Rollback to previous production version",
            "compensateOn": ["error", "validation", "timeout"]
          },
          "context": {
            "inputs": [{"key": "smoke_test_passed"}],
            "outputs": [{"key": "production_url", "persist": true}]
          }
        },
        {
          "id": "health-checks",
          "agentId": "devops-automator",
          "task": "Run production health checks",
          "dependencies": ["deploy-prod"],
          "estimatedTime": 180000,
          "retryPolicy": {
            "maxAttempts": 5,
            "strategy": "exponential",
            "initialDelay": 2000,
            "maxDelay": 30000
          },
          "compensation": {
            "type": "cascade",
            "description": "Trigger production rollback if unhealthy",
            "compensateOn": ["validation"]
          },
          "context": {
            "inputs": [{"key": "production_url"}],
            "outputs": [{"key": "deployment_status", "persist": true}]
          }
        }
      ]
    }
  ]
}
```

**Benefits**:
- Automatic rollback on any failure
- Parallel pre-deployment tasks (40% faster)
- Resource locking prevents conflicts
- Retry policies for transient failures
- Complete audit trail

## Validation Checklist

Before deploying your migrated v2.0 command, validate:

### Structure Validation
- [ ] Version is exactly "2.0.0"
- [ ] Command name starts with "/" and uses kebab-case
- [ ] Description is clear and under 200 characters
- [ ] At least one phase exists
- [ ] Each phase has unique ID
- [ ] Each phase has at least one agent

### Agent Validation
- [ ] All agent IDs are unique across entire command
- [ ] All agentId values exist in agent registry
- [ ] Every agent has a task description
- [ ] Dependencies array exists (even if empty)
- [ ] All dependencies reference existing agent IDs
- [ ] No circular dependencies exist

### Timing Validation
- [ ] All times converted to milliseconds
- [ ] estimatedTime provided for each agent
- [ ] timeout > estimatedTime (recommend 3x)
- [ ] Phase timeout > sum of sequential agent times
- [ ] Total execution time is reasonable

### Context Validation
- [ ] Context inputs match outputs from dependencies
- [ ] No conflicting output keys
- [ ] Required inputs have providers
- [ ] TTL values are positive integers
- [ ] Persist flag set for critical data

### Compensation Validation (if applicable)
- [ ] Compensation defined for destructive operations
- [ ] Compensation type matches operation
- [ ] Compensation order is reverse of dependencies
- [ ] compensateOn triggers are appropriate
- [ ] Rollback points are valid

### Resource Validation (if applicable)
- [ ] Resource identifiers are consistent
- [ ] Lock types are appropriate (exclusive/shared)
- [ ] Deadlock prevention considered
- [ ] maxWaitTime is reasonable

### Performance Validation
- [ ] Parallelism opportunities identified
- [ ] maxParallelism set appropriately
- [ ] Context sharing eliminates redundant work
- [ ] Estimated speedup calculated

### JSON Schema Validation
- [ ] Passes JSON schema validation
- [ ] No extra/unknown fields
- [ ] Required fields present
- [ ] Enum values valid

### Testing Validation
- [ ] Dry-run execution successful
- [ ] DAG visualization looks correct
- [ ] Performance metrics match estimates
- [ ] Rollback scenarios tested

## Tooling Recommendations

### JSON Schema Validators

1. **Online Validator**:
   ```bash
   curl -X POST https://www.jsonschemavalidator.net/api/validate \
     -H "Content-Type: application/json" \
     -d @command.json
   ```

2. **ajv CLI**:
   ```bash
   npm install -g ajv-cli
   ajv validate -s schema.json -d command.json
   ```

3. **VS Code Extension**:
   - Install "JSON Schema Validator"
   - Add schema reference in JSON file

### DAG Visualization Tools

1. **Graphviz**:
   ```python
   import json
   from graphviz import Digraph

   def visualize_dag(command_file):
       with open(command_file) as f:
           cmd = json.load(f)

       dot = Digraph()
       for phase in cmd['phases']:
           for agent in phase['agents']:
               dot.node(agent['id'])
               for dep in agent['dependencies']:
                   dot.edge(dep, agent['id'])

       dot.render('command-dag', view=True)
   ```

2. **Mermaid**:
   ```mermaid
   graph TD
     analyzer --> quality
     analyzer --> security
     quality --> synthesizer
     security --> synthesizer
   ```

### Migration Scripts

1. **Basic Converter Template**:
   ```python
   def convert_v1_to_v2(markdown_file):
       v2 = {
           "version": "2.0.0",
           "name": extract_name(markdown_file),
           "description": extract_description(markdown_file),
           "phases": []
       }

       # Parse markdown and build phases
       for phase in parse_phases(markdown_file):
           v2["phases"].append(convert_phase(phase))

       return json.dumps(v2, indent=2)
   ```

2. **Dependency Extractor**:
   ```python
   import re

   def extract_dependencies(step_text):
       pattern = r"depends on (?:step )?(\d+(?:,\s*\d+)*)"
       match = re.search(pattern, step_text)
       if match:
           return [f"step{n}" for n in match.group(1).split(",")]
       return []
   ```

### Linters for Common Issues

1. **Circular Dependency Checker**:
   ```python
   def has_cycle(agents):
       visited = set()
       rec_stack = set()

       def visit(node):
           if node in rec_stack:
               return True  # Cycle detected
           if node in visited:
               return False

           visited.add(node)
           rec_stack.add(node)

           for dep in get_dependencies(node):
               if visit(dep):
                   return True

           rec_stack.remove(node)
           return False

       for agent in agents:
           if visit(agent['id']):
               return True
       return False
   ```

2. **Context Validator**:
   ```python
   def validate_context(command):
       outputs = {}

       for phase in command['phases']:
           for agent in phase['agents']:
               # Check inputs exist
               if 'context' in agent:
                   for input in agent.get('context', {}).get('inputs', []):
                       if input['key'] not in outputs and input.get('required', True):
                           print(f"Missing input: {input['key']} in {agent['id']}")

                   # Register outputs
                   for output in agent.get('context', {}).get('outputs', []):
                       outputs[output['key']] = agent['id']
   ```

## FAQ

### Q: How long does migration take?
**A**: Simple commands: 30 minutes. Complex commands: 2-4 hours. The investment pays off through 40-70% performance improvements.

### Q: Can I mix v1.0 and v2.0 commands?
**A**: Yes, both formats are supported. Migrate gradually, starting with frequently-used commands.

### Q: What if my command doesn't fit any pattern?
**A**: Most commands are combinations of patterns. Start with the dominant pattern and add others as needed.

### Q: How do I estimate performance improvement?
**A**: Calculate parallelism factor: (sum of all task times) / (critical path time). Typically 1.5-3x improvement.

### Q: When should I use skipCondition vs dependencies?
**A**: Use dependencies for data flow. Use skipCondition for dynamic behavior based on runtime values.

### Q: How do I handle agent failures?
**A**: Use retryPolicy for transient failures, compensation for rollback, and continueOnError for non-critical tasks.

### Q: What's the maximum command size?
**A**: Keep commands under 1MB. Very large commands should be split into composed sub-commands.

### Q: How do I test migrations?
**A**: Use dry-run mode, validate JSON schema, visualize DAG, and compare execution times.

### Q: Can I generate v2.0 commands programmatically?
**A**: Yes, use the JSON schema to generate valid commands. Many teams build command generators for common patterns.

### Q: How do I debug execution issues?
**A**: Enable verbose logging, check context state at each step, visualize execution timeline, and review compensation triggers.

## Conclusion

Migrating to v2.0 unlocks significant performance improvements and reliability features. Start with simple commands to learn the patterns, then tackle complex orchestrations. The structured format enables better tooling, validation, and optimization.

For questions or assistance, consult the command specification at `docs/command-spec-v2.md` or reach out to the platform team.