---
title: Orchestration v2.0 Integration Guide
description: Streamline command execution with parallel workflows, dependency management, and automatic progress tracking. Achieve 30-55% performance improvements.
tags:
  - orchestration
  - integration
  - workflows
  - performance
  - parallel-execution
  - best-practices
lastUpdated: 2025-10-09
author: Agent Studio Team
audience: developers
---

# Claude Code Orchestration v2.0 Integration Guide

## Table of Contents

1. [Quick Start (5 Minutes)](#quick-start-5-minutes)
2. [Tutorial 1: Convert Existing Command (30 Minutes)](#tutorial-1-convert-existing-command-30-minutes)
3. [Tutorial 2: Parallel Review Command (45 Minutes)](#tutorial-2-parallel-review-command-45-minutes)
4. [Tutorial 3: Hierarchical Decomposition (60 Minutes)](#tutorial-3-hierarchical-decomposition-60-minutes)
5. [Tutorial 4: Saga Compensation (45 Minutes)](#tutorial-4-saga-compensation-45-minutes)
6. [Tutorial 5: TodoWrite Integration (30 Minutes)](#tutorial-5-todowrite-integration-30-minutes)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)
9. [Advanced Topics](#advanced-topics)
10. [Migration Checklist](#migration-checklist)

---

## Quick Start (5 Minutes)

Get up and running with v2.0 orchestration in under 5 minutes.

### Prerequisites

The orchestration engine is already available in `.claude/lib/orchestration/`. No installation required!

### Create Your First v2.0 Command

**Step 1: Create command JSON**

Create a new file: `.claude/commands/v2/hello-world.json`

```json
{
  "version": "2.0.0",
  "name": "/hello-world",
  "description": "My first v2.0 command",
  "phases": [
    {
      "id": "greeting",
      "name": "Execute Greeting",
      "agents": [
        {
          "id": "greet",
          "agentId": "documentation-expert",
          "task": "Generate a friendly hello world message",
          "dependencies": [],
          "estimatedTime": 5000
        }
      ]
    }
  ]
}
```

**Step 2: Load and execute**

The orchestration engine integrates automatically with Claude Code commands. Simply invoke your command:

```bash
/hello-world
```

The engine will:
1. Load your JSON definition
2. Validate the command structure
3. Build a DAG (Directed Acyclic Graph)
4. Execute the agent
5. Track progress in real-time

**Step 3: Verify it works**

You should see:
- Progress updates in the Claude Code UI
- Execution completing successfully
- Output from the documentation-expert agent

**That's it!** You've created and executed your first v2.0 command.

### What You Just Did

- ✅ Created a v2.0 JSON command definition
- ✅ Specified an agent from the registry (`documentation-expert`)
- ✅ Set an estimated execution time (5000ms = 5 seconds)
- ✅ Organized work into phases
- ✅ Executed the command through Claude Code

### Next Steps

Now that you've created a basic command, let's explore more powerful patterns:
- [Tutorial 1](#tutorial-1-convert-existing-command-30-minutes): Convert an existing v1.0 command
- [Tutorial 2](#tutorial-2-parallel-review-command-45-minutes): Build parallel workflows
- [Tutorial 3](#tutorial-3-hierarchical-decomposition-60-minutes): Create complex multi-phase commands

---

## Tutorial 1: Convert Existing Command (30 Minutes)

Learn how to migrate a v1.0 markdown command to v2.0 JSON format with performance improvements.

### Scenario

You have an existing `/review-code` command that sequentially reviews code quality and security. You want to convert it to v2.0 and enable parallel execution.

### Current v1.0 (Markdown)

```markdown
# /review-code

Review code for quality and security issues.

1. Analyze code structure (5 minutes)
2. Review code quality (depends on step 1, 10 minutes)
3. Review security (depends on step 1, 10 minutes)
4. Generate report (depends on steps 2,3, 5 minutes)
```

**Current execution time**: 30 minutes (sequential)

### Goal

Convert to v2.0 with parallel quality and security reviews.

**Target execution time**: 20 minutes (33% faster!)

### Step 1: Identify the Pattern

This command follows the **Fan-Out Parallel Analysis** pattern:
- One initial analysis (step 1)
- Multiple parallel reviews that depend on the analysis (steps 2, 3)
- Final synthesis that depends on all reviews (step 4)

```
      analyzer (5 min)
         ├──> quality (10 min) ──┐
         └──> security (10 min) ─┴──> report (5 min)
```

### Step 2: Create JSON Structure

Create `.claude/commands/v2/review-code.json`:

```json
{
  "version": "2.0.0",
  "name": "/review-code",
  "description": "Review code for quality and security issues",
  "phases": [
    {
      "id": "analysis",
      "name": "Code Analysis",
      "parallel": false,
      "agents": []
    },
    {
      "id": "reviews",
      "name": "Parallel Reviews",
      "parallel": true,
      "agents": []
    },
    {
      "id": "reporting",
      "name": "Report Generation",
      "parallel": false,
      "agents": []
    }
  ]
}
```

### Step 3: Add the Analysis Agent

Add the initial analyzer to the `analysis` phase:

```json
{
  "id": "analysis",
  "name": "Code Analysis",
  "parallel": false,
  "agents": [
    {
      "id": "analyzer",
      "agentId": "senior-reviewer",
      "task": "Analyze code structure, dependencies, and metrics",
      "dependencies": [],
      "estimatedTime": 300000,
      "context": {
        "outputs": [
          {
            "key": "code_analysis",
            "ttl": 3600,
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Key points:**
- `estimatedTime`: 300000ms = 5 minutes (converted from "5 minutes")
- `context.outputs`: Declares what data this agent produces
- `ttl`: 3600 seconds = 1 hour cache time
- `persist`: Keep this data for subsequent phases

### Step 4: Add Parallel Reviewers

Add quality and security reviewers to the `reviews` phase:

```json
{
  "id": "reviews",
  "name": "Parallel Reviews",
  "parallel": true,
  "maxParallelism": 2,
  "agents": [
    {
      "id": "quality-review",
      "agentId": "senior-reviewer",
      "task": "Review code quality, patterns, and best practices",
      "dependencies": ["analyzer"],
      "estimatedTime": 600000,
      "priority": 10,
      "context": {
        "inputs": [
          {
            "key": "code_analysis",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "quality_issues",
            "ttl": 3600
          }
        ]
      }
    },
    {
      "id": "security-review",
      "agentId": "security-specialist",
      "task": "Review security vulnerabilities and best practices",
      "dependencies": ["analyzer"],
      "estimatedTime": 600000,
      "priority": 20,
      "context": {
        "inputs": [
          {
            "key": "code_analysis",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "security_issues",
            "ttl": 3600
          }
        ]
      }
    }
  ]
}
```

**Key points:**
- `parallel`: true enables concurrent execution
- `maxParallelism`: 2 limits to 2 concurrent reviews
- `dependencies`: Both depend on "analyzer" node
- `context.inputs`: Both need the "code_analysis" output
- `priority`: Higher priority executes first (security = 20 > quality = 10)

### Step 5: Add Report Generator

Add the final report generator to the `reporting` phase:

```json
{
  "id": "reporting",
  "name": "Report Generation",
  "parallel": false,
  "agents": [
    {
      "id": "report-generator",
      "agentId": "documentation-expert",
      "task": "Generate comprehensive code review report with prioritized recommendations",
      "dependencies": ["quality-review", "security-review"],
      "estimatedTime": 300000,
      "context": {
        "inputs": [
          {
            "key": "code_analysis",
            "required": true
          },
          {
            "key": "quality_issues",
            "required": true
          },
          {
            "key": "security_issues",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "final_report",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Key points:**
- `dependencies`: Depends on both review nodes
- `context.inputs`: Needs all three outputs from previous phases
- `persist`: Final report is saved for user

### Step 6: Complete Command Definition

Here's the complete JSON:

```json
{
  "version": "2.0.0",
  "name": "/review-code",
  "description": "Review code for quality and security issues",
  "metadata": {
    "author": "Platform Team",
    "version": "2.0.0",
    "category": "code-review",
    "tags": ["review", "quality", "security"]
  },
  "phases": [
    {
      "id": "analysis",
      "name": "Code Analysis",
      "parallel": false,
      "agents": [
        {
          "id": "analyzer",
          "agentId": "senior-reviewer",
          "task": "Analyze code structure, dependencies, and metrics",
          "dependencies": [],
          "estimatedTime": 300000,
          "context": {
            "outputs": [
              {
                "key": "code_analysis",
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
      "parallel": true,
      "maxParallelism": 2,
      "agents": [
        {
          "id": "quality-review",
          "agentId": "senior-reviewer",
          "task": "Review code quality, patterns, and best practices",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "priority": 10,
          "context": {
            "inputs": [
              {
                "key": "code_analysis",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "quality_issues",
                "ttl": 3600
              }
            ]
          }
        },
        {
          "id": "security-review",
          "agentId": "security-specialist",
          "task": "Review security vulnerabilities and best practices",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "priority": 20,
          "context": {
            "inputs": [
              {
                "key": "code_analysis",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "security_issues",
                "ttl": 3600
              }
            ]
          }
        }
      ]
    },
    {
      "id": "reporting",
      "name": "Report Generation",
      "parallel": false,
      "agents": [
        {
          "id": "report-generator",
          "agentId": "documentation-expert",
          "task": "Generate comprehensive code review report with prioritized recommendations",
          "dependencies": ["quality-review", "security-review"],
          "estimatedTime": 300000,
          "context": {
            "inputs": [
              {
                "key": "code_analysis",
                "required": true
              },
              {
                "key": "quality_issues",
                "required": true
              },
              {
                "key": "security_issues",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "final_report",
                "persist": true
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### Step 7: Test the Command

Run the command:

```bash
/review-code
```

Watch for:
- Phase 1 (Analysis): Runs first
- Phase 2 (Reviews): Both run in parallel
- Phase 3 (Reporting): Runs after reviews complete

### Results

**Before (v1.0 Sequential)**:
- Execution time: 30 minutes
- Agents run one at a time
- No context sharing (analyzer runs twice internally)

**After (v2.0 Parallel)**:
- Execution time: 20 minutes
- Quality and security reviews run concurrently
- Shared analysis context (no redundant work)
- **Performance improvement: 33% faster**

### Learning Outcomes

✅ Converted v1.0 markdown to v2.0 JSON
✅ Identified Fan-Out Parallel pattern
✅ Added explicit dependencies
✅ Enabled context sharing
✅ Configured parallel execution
✅ Achieved significant performance improvement

---

## Tutorial 2: Parallel Review Command (45 Minutes)

Build a comprehensive API analysis command from scratch with parallel execution across multiple dimensions.

### Requirement

Analyze a REST API across 4 dimensions in parallel:
1. Security review
2. Performance review
3. Documentation review
4. Schema review

Each review should run independently after an initial analysis, then synthesize results.

### Architecture

```
analyzer (5 min)
   ├─> security-review (10 min) ─┐
   ├─> performance-review (10 min) ─┤
   ├─> documentation-review (10 min) ─┤─> synthesis (5 min)
   └─> schema-review (10 min) ─┘
```

**Total time**: 20 minutes (vs 45 minutes sequential)

### Step 1: Plan the DAG

Before writing JSON, sketch the dependency graph:

**Level 0** (Start): `analyzer`
**Level 1** (Parallel): `security`, `performance`, `documentation`, `schema`
**Level 2** (Synthesis): `synthesizer`

Dependencies:
- Level 1 nodes → depend on `analyzer`
- Level 2 node → depends on all Level 1 nodes

### Step 2: Define Context Flow

**What does the analyzer produce?**
- API endpoints list
- Request/response schemas
- Authentication methods
- Rate limiting config

**What do reviewers need?**
- Security: endpoints, auth methods
- Performance: endpoints, rate limits
- Documentation: endpoints, schemas
- Schema: request/response schemas

**What does synthesis need?**
- All review results

### Step 3: Write the JSON

Create `.claude/commands/v2/analyze-api.json`:

```json
{
  "version": "2.0.0",
  "name": "/analyze-api",
  "description": "Comprehensive REST API analysis across multiple dimensions",
  "metadata": {
    "author": "API Team",
    "version": "1.0.0",
    "category": "api-analysis",
    "tags": ["api", "security", "performance", "documentation"]
  },
  "phases": [
    {
      "id": "discovery",
      "name": "API Discovery",
      "description": "Analyze API structure and extract metadata",
      "parallel": false,
      "agents": [
        {
          "id": "analyzer",
          "agentId": "api-designer",
          "task": "Analyze API endpoints, schemas, authentication, and rate limiting",
          "dependencies": [],
          "estimatedTime": 300000,
          "timeout": 600000,
          "context": {
            "outputs": [
              {
                "key": "api_endpoints",
                "ttl": 3600,
                "persist": true
              },
              {
                "key": "api_schemas",
                "ttl": 3600,
                "persist": true
              },
              {
                "key": "auth_methods",
                "ttl": 3600,
                "persist": true
              },
              {
                "key": "rate_limits",
                "ttl": 3600,
                "persist": true
              }
            ]
          }
        }
      ]
    },
    {
      "id": "analysis",
      "name": "Parallel Analysis",
      "description": "Run specialized analyses in parallel",
      "parallel": true,
      "maxParallelism": 4,
      "continueOnError": true,
      "agents": [
        {
          "id": "security-review",
          "agentId": "security-specialist",
          "task": "Review API security: authentication, authorization, input validation, and OWASP compliance",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "timeout": 900000,
          "priority": 40,
          "retryPolicy": {
            "maxAttempts": 2,
            "strategy": "exponential",
            "initialDelay": 2000
          },
          "context": {
            "inputs": [
              {
                "key": "api_endpoints",
                "required": true
              },
              {
                "key": "auth_methods",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "security_findings",
                "ttl": 7200,
                "persist": true
              }
            ]
          }
        },
        {
          "id": "performance-review",
          "agentId": "performance-optimizer",
          "task": "Review API performance: response times, caching, pagination, and scalability",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "timeout": 900000,
          "priority": 30,
          "context": {
            "inputs": [
              {
                "key": "api_endpoints",
                "required": true
              },
              {
                "key": "rate_limits",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "performance_findings",
                "ttl": 7200,
                "persist": true
              }
            ]
          }
        },
        {
          "id": "documentation-review",
          "agentId": "documentation-expert",
          "task": "Review API documentation: completeness, examples, error codes, and developer experience",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "timeout": 900000,
          "priority": 20,
          "context": {
            "inputs": [
              {
                "key": "api_endpoints",
                "required": true
              },
              {
                "key": "api_schemas",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "documentation_findings",
                "ttl": 7200,
                "persist": true
              }
            ]
          }
        },
        {
          "id": "schema-review",
          "agentId": "api-designer",
          "task": "Review API schemas: consistency, validation rules, versioning, and data models",
          "dependencies": ["analyzer"],
          "estimatedTime": 600000,
          "timeout": 900000,
          "priority": 10,
          "context": {
            "inputs": [
              {
                "key": "api_schemas",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "schema_findings",
                "ttl": 7200,
                "persist": true
              }
            ]
          }
        }
      ]
    },
    {
      "id": "synthesis",
      "name": "Results Synthesis",
      "description": "Synthesize all findings into actionable recommendations",
      "parallel": false,
      "agents": [
        {
          "id": "synthesizer",
          "agentId": "architect-supreme",
          "task": "Synthesize all API analysis findings and provide prioritized recommendations",
          "dependencies": [
            "security-review",
            "performance-review",
            "documentation-review",
            "schema-review"
          ],
          "estimatedTime": 300000,
          "timeout": 600000,
          "context": {
            "inputs": [
              {
                "key": "security_findings",
                "required": false,
                "default": "Not completed"
              },
              {
                "key": "performance_findings",
                "required": false,
                "default": "Not completed"
              },
              {
                "key": "documentation_findings",
                "required": false,
                "default": "Not completed"
              },
              {
                "key": "schema_findings",
                "required": false,
                "default": "Not completed"
              }
            ],
            "outputs": [
              {
                "key": "final_recommendations",
                "persist": true
              },
              {
                "key": "priority_matrix",
                "persist": true
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### Step 4: Add Retry Policies

Notice the retry policy on the security review:

```json
"retryPolicy": {
  "maxAttempts": 2,
  "strategy": "exponential",
  "initialDelay": 2000
}
```

This handles transient failures:
- First attempt: Immediate
- Second attempt: After 2 seconds
- Third attempt: After 4 seconds (exponential backoff)

### Step 5: Validate the Command

The orchestration engine will validate:
- ✅ All node IDs are unique
- ✅ All dependencies reference existing nodes
- ✅ No circular dependencies
- ✅ All agent IDs exist in registry
- ✅ Context inputs have providers

### Step 6: Test Execution

Run the command:

```bash
/analyze-api
```

Expected behavior:
1. **Phase 1** (Discovery): `analyzer` runs alone (5 min)
2. **Phase 2** (Analysis): All 4 reviews run in parallel (10 min)
   - Security review (priority 40) starts first
   - Performance review (priority 30) starts second
   - Documentation review (priority 20) starts third
   - Schema review (priority 10) starts last
3. **Phase 3** (Synthesis): `synthesizer` runs after all reviews (5 min)

**Total execution time**: ~20 minutes (vs 45 minutes sequential)

### Step 7: Handle Partial Failures

Notice the synthesis agent has `required: false` for all inputs:

```json
{
  "key": "security_findings",
  "required": false,
  "default": "Not completed"
}
```

Why? Because `continueOnError: true` in the analysis phase allows the command to continue even if one review fails. The synthesizer will work with whatever results are available.

### Learning Outcomes

✅ Built a complete parallel analysis command from scratch
✅ Planned execution graph before coding
✅ Defined rich context flow between agents
✅ Added retry policies for reliability
✅ Configured priority-based execution
✅ Handled partial failures gracefully
✅ Achieved 55% performance improvement through parallelization

---

## Tutorial 3: Hierarchical Decomposition (60 Minutes)

Create a complex multi-phase feature implementation workflow with design → code → test → review stages.

### Requirement

Implement a new feature with:
1. Architecture design (single phase)
2. Parallel implementation (backend, frontend, database)
3. Parallel testing (unit, integration, e2e)
4. Final code review

### Architecture

```
Phase 1: Design (10 min)
  └─> architecture-design

Phase 2: Implementation (30 min parallel)
  ├─> backend-code (depends on design)
  ├─> frontend-code (depends on design)
  └─> database-schema (depends on design)

Phase 3: Testing (20 min parallel)
  ├─> unit-tests (depends on code)
  ├─> integration-tests (depends on code)
  └─> e2e-tests (depends on code, unit, integration)

Phase 4: Review (10 min)
  └─> code-review (depends on all tests passing)
```

**Total time**: ~70 minutes (vs 100 minutes sequential = 30% improvement)

### Step 1: Design Phase

Create `.claude/commands/v2/implement-feature.json`:

```json
{
  "version": "2.0.0",
  "name": "/implement-feature",
  "description": "Implement a complete feature with architecture, code, tests, and review",
  "metadata": {
    "author": "Engineering Team",
    "version": "1.0.0",
    "category": "feature-implementation",
    "tags": ["implementation", "testing", "architecture"]
  },
  "phases": [
    {
      "id": "design",
      "name": "Architecture Design",
      "description": "Design system architecture and create ADR",
      "parallel": false,
      "agents": [
        {
          "id": "architect",
          "agentId": "architect-supreme",
          "task": "Design system architecture, create ADR, and define API contracts for the new feature",
          "dependencies": [],
          "estimatedTime": 600000,
          "timeout": 1200000,
          "context": {
            "outputs": [
              {
                "key": "architecture_design",
                "ttl": 7200,
                "persist": true
              },
              {
                "key": "api_contracts",
                "ttl": 7200,
                "persist": true
              },
              {
                "key": "data_model",
                "ttl": 7200,
                "persist": true
              }
            ]
          }
        }
      ]
    }
  ]
}
```

### Step 2: Implementation Phase

Add parallel implementation tasks:

```json
{
  "id": "implementation",
  "name": "Parallel Implementation",
  "description": "Implement backend, frontend, and database in parallel",
  "parallel": true,
  "maxParallelism": 3,
  "continueOnError": false,
  "agents": [
    {
      "id": "backend",
      "agentId": "code-generator-python",
      "task": "Implement backend services based on architecture design",
      "dependencies": ["architect"],
      "estimatedTime": 1800000,
      "timeout": 3600000,
      "context": {
        "inputs": [
          {
            "key": "architecture_design",
            "required": true
          },
          {
            "key": "api_contracts",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "backend_code",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "frontend",
      "agentId": "frontend-engineer",
      "task": "Implement frontend components based on design",
      "dependencies": ["architect"],
      "estimatedTime": 1800000,
      "timeout": 3600000,
      "context": {
        "inputs": [
          {
            "key": "api_contracts",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "frontend_code",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "database",
      "agentId": "database-architect",
      "task": "Design and implement database schema with migrations",
      "dependencies": ["architect"],
      "estimatedTime": 900000,
      "timeout": 1800000,
      "compensation": {
        "type": "rollback",
        "description": "Drop created tables and migrations on failure",
        "compensateOn": ["error", "validation"]
      },
      "context": {
        "inputs": [
          {
            "key": "architecture_design",
            "required": true
          },
          {
            "key": "data_model",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "database_schema",
            "persist": true
          },
          {
            "key": "migration_scripts",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Key points:**
- All three implementation tasks run in parallel
- Each depends only on the `architect` node from Phase 1
- Database task has compensation for rollback on failure
- `continueOnError: false` means any failure stops the phase

### Step 3: Testing Phase

Add comprehensive testing:

```json
{
  "id": "testing",
  "name": "Parallel Testing",
  "description": "Run unit, integration, and e2e tests in parallel",
  "parallel": true,
  "maxParallelism": 3,
  "agents": [
    {
      "id": "unit-tests",
      "agentId": "test-engineer",
      "task": "Generate and run comprehensive unit tests for backend and frontend",
      "dependencies": ["backend", "frontend"],
      "estimatedTime": 900000,
      "timeout": 1800000,
      "retryPolicy": {
        "maxAttempts": 2,
        "strategy": "linear",
        "initialDelay": 5000
      },
      "context": {
        "inputs": [
          {
            "key": "backend_code",
            "required": true
          },
          {
            "key": "frontend_code",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "unit_test_results",
            "persist": true
          },
          {
            "key": "unit_coverage",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "integration-tests",
      "agentId": "test-engineer",
      "task": "Generate and run integration tests for API endpoints",
      "dependencies": ["backend", "frontend", "database"],
      "estimatedTime": 1200000,
      "timeout": 2400000,
      "context": {
        "inputs": [
          {
            "key": "backend_code",
            "required": true
          },
          {
            "key": "frontend_code",
            "required": true
          },
          {
            "key": "database_schema",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "integration_test_results",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "e2e-tests",
      "agentId": "test-engineer",
      "task": "Generate and run end-to-end user workflow tests",
      "dependencies": ["backend", "frontend", "database", "unit-tests", "integration-tests"],
      "estimatedTime": 1500000,
      "timeout": 3000000,
      "skipCondition": {
        "type": "context",
        "expression": "unit_test_results.passed == false || integration_test_results.passed == false",
        "skipMessage": "Skipping e2e tests due to unit or integration test failures"
      },
      "context": {
        "inputs": [
          {
            "key": "backend_code",
            "required": true
          },
          {
            "key": "frontend_code",
            "required": true
          },
          {
            "key": "unit_test_results",
            "required": true
          },
          {
            "key": "integration_test_results",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "e2e_test_results",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Advanced features:**
- **Multi-level dependencies**: e2e tests depend on both code AND other tests
- **Skip condition**: e2e tests skip if unit/integration tests fail
- **Retry policy**: Unit tests retry on transient failures

### Step 4: Review Phase

Add final code review:

```json
{
  "id": "review",
  "name": "Code Review",
  "description": "Comprehensive code review of implementation and tests",
  "parallel": false,
  "agents": [
    {
      "id": "reviewer",
      "agentId": "senior-reviewer",
      "task": "Review all implementation code, tests, and architecture decisions. Provide actionable feedback.",
      "dependencies": ["unit-tests", "integration-tests", "e2e-tests"],
      "estimatedTime": 600000,
      "timeout": 1200000,
      "context": {
        "passthrough": true,
        "outputs": [
          {
            "key": "review_report",
            "persist": true
          },
          {
            "key": "approval_status",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Key feature:**
- `passthrough: true` gives the reviewer access to ALL previous context

### Complete Command

Here's the full command (combined from all steps above):

```json
{
  "version": "2.0.0",
  "name": "/implement-feature",
  "description": "Implement a complete feature with architecture, code, tests, and review",
  "metadata": {
    "author": "Engineering Team",
    "version": "1.0.0",
    "category": "feature-implementation",
    "tags": ["implementation", "testing", "architecture"]
  },
  "phases": [
    {
      "id": "design",
      "name": "Architecture Design",
      "description": "Design system architecture and create ADR",
      "parallel": false,
      "agents": [/* architect agent from Step 1 */]
    },
    {
      "id": "implementation",
      "name": "Parallel Implementation",
      "description": "Implement backend, frontend, and database in parallel",
      "parallel": true,
      "maxParallelism": 3,
      "continueOnError": false,
      "agents": [/* backend, frontend, database agents from Step 2 */]
    },
    {
      "id": "testing",
      "name": "Parallel Testing",
      "description": "Run unit, integration, and e2e tests in parallel",
      "parallel": true,
      "maxParallelism": 3,
      "agents": [/* test agents from Step 3 */]
    },
    {
      "id": "review",
      "name": "Code Review",
      "description": "Comprehensive code review of implementation and tests",
      "parallel": false,
      "agents": [/* reviewer agent from Step 4 */]
    }
  ]
}
```

### Learning Outcomes

✅ Created hierarchical multi-phase workflow
✅ Mixed parallel and sequential execution patterns
✅ Implemented multi-level dependencies (e2e depends on code AND tests)
✅ Added conditional execution with skipCondition
✅ Used compensation for database rollback
✅ Enabled full context passthrough for review
✅ Achieved 30% performance improvement

### Advanced Pattern: Dependency Diamond

Notice the e2e tests create a "dependency diamond":

```
     backend ─┐
              ├─> unit-tests ─┐
     frontend─┘                ├─> e2e-tests
                               │
     integration-tests ────────┘
```

The orchestration engine resolves this correctly:
1. backend and frontend complete
2. unit-tests and integration-tests run in parallel
3. e2e-tests waits for both test suites
4. All execute in optimal order

---

## Tutorial 4: Saga Compensation (45 Minutes)

Implement automatic rollback for a database migration using the Saga pattern.

### Requirement

Execute a database migration with:
- Automatic backup creation
- Schema migration with rollback capability
- Data migration with restore on failure
- Validation with cascading rollback
- Cleanup only if all validations pass

### Why Saga Pattern?

Database migrations are risky:
- Schema changes can break the application
- Data migrations can corrupt data
- Partial failures leave the database in inconsistent state

The Saga pattern provides:
- **Compensation**: Automatic rollback on any failure
- **Consistency**: All-or-nothing execution
- **Recovery**: Restore to last known good state

### Architecture

```
Phase 1: Preparation
  ├─> backup (no compensation - backup is kept)
  └─> validate-schema

Phase 2: Migration
  ├─> migrate-schema (compensation: rollback schema)
  └─> migrate-data (compensation: restore from backup)

Phase 3: Validation
  ├─> validate-integrity (compensation: cascade rollback)
  └─> validate-performance

Phase 4: Cleanup
  └─> cleanup (skip if validation failed)
```

### Step 1: Create Backup Agent

Create `.claude/commands/v2/database-migration.json`:

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
          "task": "Create complete database backup before migration",
          "dependencies": [],
          "estimatedTime": 300000,
          "timeout": 900000,
          "compensation": {
            "type": "none",
            "description": "Backup is kept for safety and future recovery"
          },
          "context": {
            "outputs": [
              {
                "key": "backup_id",
                "persist": true
              },
              {
                "key": "backup_location",
                "persist": true
              }
            ]
          }
        },
        {
          "id": "validate-schema",
          "agentId": "database-architect",
          "task": "Validate current schema matches expected state before migration",
          "dependencies": ["backup"],
          "estimatedTime": 60000,
          "timeout": 180000,
          "context": {
            "inputs": [
              {
                "key": "backup_id",
                "required": true
              }
            ],
            "outputs": [
              {
                "key": "schema_valid",
                "persist": true
              }
            ]
          }
        }
      ]
    }
  ]
}
```

**Key points:**
- `resources.locks`: Exclusive database lock prevents concurrent migrations
- Backup has `compensation.type: "none"` - we keep backups for safety
- Schema validation depends on backup completion

### Step 2: Add Migration with Compensation

Add the migration phase with custom compensation:

```json
{
  "id": "migration",
  "name": "Execute Migration",
  "parallel": false,
  "continueOnError": false,
  "agents": [
    {
      "id": "migrate-schema",
      "agentId": "database-architect",
      "task": "Apply schema migrations (ALTER TABLE, CREATE INDEX, etc.)",
      "dependencies": ["validate-schema"],
      "estimatedTime": 180000,
      "timeout": 600000,
      "compensation": {
        "type": "custom",
        "description": "Rollback schema to previous version using reverse migration scripts",
        "agentId": "database-architect",
        "task": "Execute reverse migration scripts to undo schema changes",
        "compensateOn": ["error", "validation"]
      },
      "context": {
        "inputs": [
          {
            "key": "schema_valid",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "migration_version",
            "persist": true
          },
          {
            "key": "migration_timestamp",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "migrate-data",
      "agentId": "database-architect",
      "task": "Transform and migrate data to new schema",
      "dependencies": ["migrate-schema"],
      "estimatedTime": 600000,
      "timeout": 1800000,
      "retryPolicy": {
        "maxAttempts": 3,
        "strategy": "exponential",
        "initialDelay": 5000,
        "maxDelay": 30000,
        "retryableErrors": ["DEADLOCK", "TIMEOUT", "CONNECTION_RESET"]
      },
      "compensation": {
        "type": "custom",
        "description": "Restore data from backup created in preparation phase",
        "agentId": "database-architect",
        "task": "Restore database from backup_id",
        "compensateOn": ["error", "validation"]
      },
      "context": {
        "inputs": [
          {
            "key": "backup_id",
            "required": true
          },
          {
            "key": "migration_version",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "rows_migrated",
            "persist": true
          },
          {
            "key": "data_migration_log",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Compensation details:**

**Schema compensation**:
```json
"compensation": {
  "type": "custom",
  "agentId": "database-architect",
  "task": "Execute reverse migration scripts",
  "compensateOn": ["error", "validation"]
}
```
- Triggers on errors OR validation failures
- Uses the same database-architect agent
- Executes reverse migration scripts

**Data compensation**:
```json
"compensation": {
  "type": "custom",
  "task": "Restore database from backup_id",
  "compensateOn": ["error", "validation"]
}
```
- Restores entire database from backup
- Uses backup_id from context

### Step 3: Add Validation with Cascade

Add validation that triggers full rollback if it fails:

```json
{
  "id": "validation",
  "name": "Post-Migration Validation",
  "parallel": true,
  "maxParallelism": 2,
  "agents": [
    {
      "id": "validate-integrity",
      "agentId": "database-architect",
      "task": "Validate data integrity constraints, foreign keys, and referential integrity",
      "dependencies": ["migrate-data"],
      "estimatedTime": 120000,
      "timeout": 360000,
      "compensation": {
        "type": "cascade",
        "description": "Trigger full rollback of entire migration if validation fails",
        "rollbackTo": "backup",
        "compensateOn": ["validation"]
      },
      "context": {
        "inputs": [
          {
            "key": "rows_migrated",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "integrity_valid",
            "persist": true
          },
          {
            "key": "integrity_report",
            "persist": true
          }
        ]
      }
    },
    {
      "id": "validate-performance",
      "agentId": "performance-optimizer",
      "task": "Validate query performance meets SLAs after migration",
      "dependencies": ["migrate-data"],
      "estimatedTime": 180000,
      "timeout": 540000,
      "context": {
        "inputs": [
          {
            "key": "migration_version",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "performance_valid",
            "persist": true
          },
          {
            "key": "performance_report",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Cascade compensation:**

```json
"compensation": {
  "type": "cascade",
  "rollbackTo": "backup",
  "compensateOn": ["validation"]
}
```

This means:
1. If validation fails, trigger compensation
2. Rollback to the "backup" checkpoint
3. Execute ALL compensations in reverse order:
   - First: Restore data (migrate-data compensation)
   - Then: Rollback schema (migrate-schema compensation)
   - Finally: System is back to pre-migration state

### Step 4: Add Conditional Cleanup

Add cleanup that only runs if validation passes:

```json
{
  "id": "finalization",
  "name": "Migration Finalization",
  "parallel": false,
  "agents": [
    {
      "id": "cleanup",
      "agentId": "database-architect",
      "task": "Clean up temporary tables, old indexes, and migration artifacts",
      "dependencies": ["validate-integrity", "validate-performance"],
      "estimatedTime": 60000,
      "timeout": 180000,
      "skipCondition": {
        "type": "context",
        "expression": "integrity_valid == false || performance_valid == false",
        "skipMessage": "Skipping cleanup due to validation failure - migration will be rolled back"
      },
      "context": {
        "inputs": [
          {
            "key": "integrity_valid",
            "required": true
          },
          {
            "key": "performance_valid",
            "required": true
          }
        ],
        "outputs": [
          {
            "key": "migration_complete",
            "persist": true
          }
        ]
      }
    }
  ]
}
```

**Skip condition:**
- Cleanup only runs if BOTH validations pass
- If either validation fails, skip cleanup
- The cascade compensation will rollback the migration

### Testing Failure Scenarios

To test the compensation logic, you can simulate failures:

**Test 1: Schema migration fails**
```typescript
// Simulate by having migrate-schema return error
// Expected: migrate-schema compensation executes
// Result: Schema rolled back, data migration never runs
```

**Test 2: Data migration fails**
```typescript
// Simulate by having migrate-data timeout
// Expected: migrate-data compensation executes (restore from backup)
// Then: migrate-schema compensation executes (rollback schema)
// Result: Complete rollback to pre-migration state
```

**Test 3: Validation fails**
```typescript
// Simulate by having validate-integrity detect corruption
// Expected: cascade compensation triggers
// Result: Full rollback to backup checkpoint
```

### Compensation Execution Order

When a failure occurs, compensations execute in **reverse dependency order**:

```
Forward execution:
  backup → validate-schema → migrate-schema → migrate-data → validate-integrity

Compensation (reverse):
  restore-data (migrate-data) → rollback-schema (migrate-schema)
  (validate-schema and backup have no compensation)
```

This ensures:
1. Child nodes compensate before parents
2. Resources released in correct order
3. Database returns to consistent state

### Learning Outcomes

✅ Implemented Saga pattern for database migration
✅ Created custom compensation actions
✅ Used cascade compensation for full rollback
✅ Added conditional execution with skipCondition
✅ Configured resource locking for exclusive access
✅ Handled transient failures with retry policies
✅ Ensured data consistency with validation gates

### Real-World Benefits

This pattern is used for:
- **Database migrations**: Schema and data changes
- **Deployment operations**: Blue-green deployments
- **Infrastructure changes**: Cloud resource provisioning
- **Payment processing**: Multi-step transactions
- **Data pipelines**: ETL operations with rollback

---

## Tutorial 5: TodoWrite Integration (30 Minutes)

Add real-time progress tracking to your commands using TodoWrite integration.

### Goal

Show progress updates in the Claude Code UI as your command executes:
- ⏳ Pending tasks
- ⚙️ Running tasks with active form ("Analyzing...")
- ✅ Completed tasks
- ❌ Failed tasks

### How It Works

The orchestration engine automatically generates todos from your command's DAG structure and updates them as execution progresses.

### Step 1: Enable Progress Tracking

Progress tracking is **enabled by default** for all v2.0 commands. The engine:

1. Analyzes your command's DAG
2. Creates todos for each agent node
3. Updates status as nodes execute
4. Shows estimated completion time

No configuration needed!

### Step 2: Automatic Todo Generation

For the `/review-code` command from Tutorial 1, the engine generates:

```typescript
[
  {
    content: "Analyze code structure",
    status: "pending",
    activeForm: "Analyzing code structure...",
    estimatedTime: 300000
  },
  {
    content: "Review code quality",
    status: "pending",
    activeForm: "Reviewing code quality...",
    estimatedTime: 600000
  },
  {
    content: "Review security",
    status: "pending",
    activeForm: "Reviewing security...",
    estimatedTime: 600000
  },
  {
    content: "Generate report",
    status: "pending",
    activeForm: "Generating report...",
    estimatedTime: 300000
  }
]
```

### Step 3: Watch Progress Updates

When you run `/review-code`, you'll see:

**Initial state (all pending)**:
```
⏳ Analyze code structure
⏳ Review code quality
⏳ Review security
⏳ Generate report
```

**After analyzer completes**:
```
✅ Analyze code structure (completed in 4.8s)
⚙️ Reviewing code quality... (in progress, ~6 min remaining)
⚙️ Reviewing security... (in progress, ~6 min remaining)
⏳ Generate report
```

**After reviews complete**:
```
✅ Analyze code structure (completed in 4.8s)
✅ Review code quality (completed in 9.2s)
✅ Review security (completed in 8.7s)
⚙️ Generating report... (in progress, ~2 min remaining)
```

**Final state**:
```
✅ Analyze code structure (completed in 4.8s)
✅ Review code quality (completed in 9.2s)
✅ Review security (completed in 8.7s)
✅ Generate report (completed in 4.1s)
```

### Step 4: Customize Todo Messages

You can customize how tasks appear in the todo list by adding descriptive task names:

```json
{
  "id": "security-review",
  "agentId": "security-specialist",
  "task": "Scan for vulnerabilities: SQL injection, XSS, authentication bypass, and exposed secrets",
  "estimatedTime": 600000
}
```

This generates:
```
⚙️ Scanning for vulnerabilities: SQL injection, XSS, authentication bypass, and exposed secrets...
```

**Best practices for task descriptions:**
- Start with an action verb (Scan, Review, Generate, Validate)
- Be specific about what's happening
- Keep under 80 characters for readability
- Use present tense imperative form

### Step 5: Group Related Todos by Phase

The orchestration engine groups todos by phase:

```
Phase 1: Code Analysis
  ✅ Analyze code structure (completed in 4.8s)

Phase 2: Parallel Reviews
  ✅ Review code quality (completed in 9.2s)
  ✅ Review security (completed in 8.7s)

Phase 3: Report Generation
  ⚙️ Generating report... (in progress, ~2 min remaining)
```

This makes it easy to see:
- Which phase is currently executing
- Progress within each phase
- Overall command progress

### Step 6: Handle Long-Running Commands

For commands with many agents, the engine intelligently batches updates:

```typescript
// Instead of 50 individual updates:
// Update 1: Task 1 pending
// Update 2: Task 2 pending
// ...

// Engine batches into phases:
// Update 1: Phase 1 started (5 tasks)
// Update 2: Phase 1 progress (2/5 complete)
// Update 3: Phase 1 complete
// Update 4: Phase 2 started (10 tasks)
```

This prevents:
- UI flooding with updates
- Performance degradation
- Poor user experience

### Step 7: Advanced - Custom Progress Hooks

For advanced use cases, you can add custom progress hooks:

```typescript
import { OrchestrationEngine } from '.claude/lib/orchestration';

const engine = new OrchestrationEngine({
  onNodeStart: (nodeId, phase) => {
    console.log(`Starting ${nodeId} in phase ${phase}`);
  },
  onNodeComplete: (nodeId, duration, success) => {
    console.log(`Completed ${nodeId} in ${duration}ms: ${success}`);
  },
  onPhaseComplete: (phaseId, results) => {
    console.log(`Phase ${phaseId} complete:`, results);
  }
});
```

### Step 8: Customize Todo Batching

Adjust batching behavior for your needs:

```typescript
const engine = new OrchestrationEngine({
  todoWrite: {
    batchSize: 10,        // Max todos per batch
    batchDelay: 500,      // Delay in ms before flushing batch
    enableGrouping: true  // Group by phase
  }
});
```

### Example: Hierarchical Todo Display

For the `/implement-feature` command from Tutorial 3:

```
Phase 1: Architecture Design
  ✅ Design system architecture (completed in 9.2 min)

Phase 2: Parallel Implementation
  ⚙️ Implementing backend services... (in progress, ~12 min remaining)
  ⚙️ Implementing frontend components... (in progress, ~15 min remaining)
  ⚙️ Designing database schema... (in progress, ~6 min remaining)

Phase 3: Parallel Testing (waiting for implementation)
  ⏳ Generate unit tests
  ⏳ Generate integration tests
  ⏳ Generate e2e tests

Phase 4: Code Review (waiting for testing)
  ⏳ Review implementation
```

As execution progresses:

```
Phase 1: Architecture Design
  ✅ Design system architecture (completed in 9.2 min)

Phase 2: Parallel Implementation
  ✅ Implementing backend services (completed in 28.4 min)
  ✅ Implementing frontend components (completed in 29.1 min)
  ✅ Designing database schema (completed in 14.7 min)

Phase 3: Parallel Testing
  ✅ Generate unit tests (completed in 13.2 min)
  ⚙️ Generating integration tests... (in progress, ~8 min remaining)
  ⏳ Generate e2e tests (waiting for integration tests)

Phase 4: Code Review (waiting for testing)
  ⏳ Review implementation
```

### Learning Outcomes

✅ Understood automatic todo generation from DAG
✅ Learned how progress updates work in real-time
✅ Customized task descriptions for better UX
✅ Configured batching for performance
✅ Implemented phase-based grouping
✅ Added custom progress hooks for advanced monitoring

### Benefits

**For Users:**
- Clear visibility into command progress
- Accurate time estimates
- Understanding of what's happening

**For Developers:**
- No manual progress tracking code
- Automatic UI updates
- Built-in performance monitoring

---

## Best Practices

### ✅ DO: Share Context Aggressively

**Why**: Eliminates redundant work and improves performance.

**Example**:
```json
{
  "id": "analyzer",
  "context": {
    "outputs": [
      {
        "key": "analysis_data",
        "ttl": 3600,
        "persist": true
      }
    ]
  }
}
```

Then multiple consumers:
```json
{
  "id": "reviewer-1",
  "dependencies": ["analyzer"],
  "context": {
    "inputs": [
      { "key": "analysis_data", "required": true }
    ]
  }
},
{
  "id": "reviewer-2",
  "dependencies": ["analyzer"],
  "context": {
    "inputs": [
      { "key": "analysis_data", "required": true }
    ]
  }
}
```

**Impact**: Analysis runs once, shared by N consumers. Saves N-1 executions.

### ❌ DON'T: Over-Serialize

**Why**: Prevents parallelization and slows execution.

**Bad**:
```json
{
  "agents": [
    {"id": "task1", "dependencies": []},
    {"id": "task2", "dependencies": ["task1"]},  // Unnecessary!
    {"id": "task3", "dependencies": ["task2"]}   // Unnecessary!
  ]
}
```

These tasks can run in parallel, but the dependencies prevent it.

**Good**:
```json
{
  "agents": [
    {"id": "analyzer", "dependencies": []},
    {"id": "task1", "dependencies": ["analyzer"]},
    {"id": "task2", "dependencies": ["analyzer"]},
    {"id": "task3", "dependencies": ["analyzer"]}
  ]
}
```

Now tasks 1, 2, 3 run in parallel after analyzer completes.

**Rule**: Only add dependencies when:
- There's a data dependency (task2 needs output from task1)
- There's an ordering constraint (task2 must run after task1 completes)

### ✅ DO: Add Reasonable Timeouts

**Why**: Prevents hung executions and provides early failure detection.

**Good**:
```json
{
  "id": "external-api-call",
  "estimatedTime": 60000,
  "timeout": 180000,
  "retryPolicy": {
    "maxAttempts": 3,
    "strategy": "exponential",
    "initialDelay": 2000
  }
}
```

**Rule of thumb**: `timeout = estimatedTime × 3`

### ❌ DON'T: Use Passthrough Everywhere

**Why**: Increases memory usage and can expose unnecessary data.

**Bad**:
```json
{
  "id": "simple-task",
  "context": {
    "passthrough": true  // Passes ALL context including unneeded data
  }
}
```

**Good**:
```json
{
  "id": "simple-task",
  "context": {
    "inputs": [
      { "key": "specific_data", "required": true }
    ]
  }
}
```

**Use passthrough only when**:
- Final synthesis/review agents that need full picture
- Debugging complex context flow
- Forwarding context to sub-commands

### ✅ DO: Set Appropriate TTLs

**Why**: Balances memory usage with cache effectiveness.

**Guidelines**:

**Short TTL (300-600s)**: Temporary data
```json
{
  "key": "intermediate_result",
  "ttl": 300
}
```

**Medium TTL (1800-3600s)**: Analysis results
```json
{
  "key": "code_analysis",
  "ttl": 3600
}
```

**Long TTL + persist**: Critical outputs
```json
{
  "key": "final_report",
  "ttl": 7200,
  "persist": true
}
```

### ✅ DO: Handle Partial Failures Gracefully

**Why**: Makes commands resilient and provides better user experience.

**Good**:
```json
{
  "id": "parallel-reviews",
  "parallel": true,
  "continueOnError": true,
  "agents": [/* multiple reviewers */]
},
{
  "id": "synthesizer",
  "dependencies": [/* all reviewers */],
  "context": {
    "inputs": [
      {
        "key": "review1_results",
        "required": false,
        "default": "Not completed"
      },
      {
        "key": "review2_results",
        "required": false,
        "default": "Not completed"
      }
    ]
  }
}
```

Now if one reviewer fails, synthesis still works with available results.

### ❌ DON'T: Ignore Agent Registry

**Why**: Invalid agent IDs cause runtime failures.

**Bad**:
```json
{
  "id": "task1",
  "agentId": "my-custom-agent"  // Doesn't exist in registry!
}
```

**Good**:
```json
{
  "id": "task1",
  "agentId": "architect-supreme"  // Exists in .claude/agents/
}
```

**Always check**: `.claude/agents/` directory for available agents.

### ✅ DO: Use Descriptive IDs

**Why**: Makes debugging and monitoring easier.

**Bad**:
```json
{
  "id": "a1",
  "agentId": "test-engineer",
  "task": "Run tests"
}
```

**Good**:
```json
{
  "id": "unit-tests-backend",
  "agentId": "test-engineer",
  "task": "Run backend unit tests with coverage"
}
```

**Benefits**:
- Clear logs: "unit-tests-backend failed" vs "a1 failed"
- Better todo messages
- Easier debugging

### ✅ DO: Version Your Commands

**Why**: Enables safe evolution and rollback.

**Good**:
```json
{
  "version": "2.0.0",
  "name": "/review-all",
  "metadata": {
    "version": "3.1.0",
    "author": "Platform Team",
    "changelog": [
      "3.1.0: Added accessibility review",
      "3.0.0: Migrated to v2.0 format with parallel execution",
      "2.0.0: Added security review"
    ]
  }
}
```

### ❌ DON'T: Create Circular Dependencies

**Why**: Causes validation failures and execution deadlocks.

**Bad**:
```json
{
  "agents": [
    {"id": "frontend", "dependencies": ["backend"]},
    {"id": "backend", "dependencies": ["frontend"]}  // CIRCULAR!
  ]
}
```

**Error**: "Circular dependency detected: frontend → backend → frontend"

**Fix**: Identify shared dependency
```json
{
  "agents": [
    {"id": "api-contract", "dependencies": []},
    {"id": "frontend", "dependencies": ["api-contract"]},
    {"id": "backend", "dependencies": ["api-contract"]}
  ]
}
```

### ✅ DO: Test Complex Dependency Graphs

**Why**: Validates execution order before deployment.

**Use dry-run mode**:
```typescript
import { CommandLoader, DAGBuilder } from '.claude/lib/orchestration';

const loader = new CommandLoader();
const command = await loader.load('my-complex-command.json');

// Validate
const validation = loader.validate(command.definition);
if (!validation.valid) {
  console.error('Validation errors:', validation.errors);
}

// Visualize DAG
const builder = new DAGBuilder();
const dag = builder.buildDAG(command.definition);
console.log(dag.visualize());
```

### Summary Table

| Practice | Do | Don't | Impact |
|----------|---|--------|--------|
| Context sharing | Share expensive analysis | Re-run same analysis | 50-70% perf gain |
| Dependencies | Only when needed | Over-serialize | Enables parallelism |
| Timeouts | 3x estimated time | No timeout | Prevents hangs |
| TTLs | Match data lifecycle | Same TTL for all | Optimizes memory |
| Failures | Handle gracefully | Fail-fast always | Better UX |
| Agent IDs | Use registry | Make up names | Prevents errors |
| Node IDs | Descriptive names | Generic (a1, b2) | Easier debugging |
| Versioning | Track changes | No version info | Safe evolution |
| Circular deps | Detect early | Hope for best | Prevents deadlock |
| Testing | Validate before deploy | Test in production | Catches errors early |

---

## Troubleshooting

### Issue: "Circular dependency detected"

**Symptom**:
```
Error: Circular dependency detected in command '/my-command'
  frontend → backend → database → frontend
```

**Cause**: Agent dependencies form a cycle.

**Solution**:

1. **Identify the cycle**: Follow the error message
   ```
   frontend depends on backend
   backend depends on database
   database depends on frontend  ← This creates the cycle
   ```

2. **Find the shared dependency**:
   ```
   What do all three need?
   → API contracts!
   ```

3. **Restructure**:
   ```json
   {
     "agents": [
       {"id": "api-contract", "dependencies": []},
       {"id": "frontend", "dependencies": ["api-contract"]},
       {"id": "backend", "dependencies": ["api-contract"]},
       {"id": "database", "dependencies": ["api-contract"]}
     ]
   }
   ```

**Prevention**: Draw your DAG before writing JSON.

---

### Issue: "Context input not found"

**Symptom**:
```
Error: Required input "analysis_results" not found for node "reviewer"
Available context keys: ["code_structure", "file_list"]
```

**Cause**: Agent expects context that no previous agent produces.

**Solution**:

1. **Check producer**:
   ```json
   // Does any agent produce "analysis_results"?
   {
     "id": "analyzer",
     "context": {
       "outputs": [
         {"key": "code_structure"},
         {"key": "file_list"}
         // Missing: "analysis_results"!
       ]
     }
   }
   ```

2. **Fix the producer**:
   ```json
   {
     "id": "analyzer",
     "context": {
       "outputs": [
         {"key": "code_structure"},
         {"key": "file_list"},
         {"key": "analysis_results"}  // Added!
       ]
     }
   }
   ```

**Or** fix the consumer:
```json
{
  "id": "reviewer",
  "context": {
    "inputs": [
      {"key": "code_structure", "required": true}  // Use available key
    ]
  }
}
```

**Prevention**: Document context flow in comments.

---

### Issue: "Agent not found in registry"

**Symptom**:
```
Error: Agent "code-reviewer-pro" not found in agent registry
Available agents: [
  "architect-supreme",
  "senior-reviewer",
  "test-engineer",
  ...
]
```

**Cause**: `agentId` doesn't match any agent in `.claude/agents/`.

**Solution**:

1. **Check available agents**:
   ```bash
   ls .claude/agents/
   # architect-supreme.md
   # senior-reviewer.md
   # test-engineer.md
   # ...
   ```

2. **Fix the agent ID**:
   ```json
   {
     "id": "review",
     "agentId": "senior-reviewer"  // Use correct ID
   }
   ```

**Common mistakes**:
- Typos: `"senoir-reviewer"` → `"senior-reviewer"`
- Wrong case: `"Senior-Reviewer"` → `"senior-reviewer"`
- Wrong separator: `"senior_reviewer"` → `"senior-reviewer"`

**Prevention**: Use autocomplete or copy from agent registry.

---

### Issue: "Execution timeout"

**Symptom**:
```
Error: Node "slow-analyzer" timed out after 300000ms
Estimated time was: 60000ms
Actual time exceeded by: 240000ms
```

**Cause**: Operation took longer than timeout.

**Solutions**:

**Option 1: Increase timeout**:
```json
{
  "id": "slow-analyzer",
  "estimatedTime": 60000,
  "timeout": 900000  // Increased to 15 minutes
}
```

**Option 2: Add retry with longer timeout**:
```json
{
  "id": "slow-analyzer",
  "estimatedTime": 60000,
  "timeout": 300000,
  "retryPolicy": {
    "maxAttempts": 3,
    "strategy": "exponential"
  }
}
```

**Option 3: Split into smaller tasks**:
```json
{
  "agents": [
    {"id": "analyze-phase-1", "estimatedTime": 60000},
    {"id": "analyze-phase-2", "estimatedTime": 60000, "dependencies": ["analyze-phase-1"]},
    {"id": "analyze-phase-3", "estimatedTime": 60000, "dependencies": ["analyze-phase-2"]}
  ]
}
```

**Prevention**: Set realistic estimates and appropriate timeouts.

---

### Issue: "Resource deadlock detected"

**Symptom**:
```
Error: Resource deadlock detected
Task A waiting for: database (locked by Task B)
Task B waiting for: file-system (locked by Task A)
```

**Cause**: Two tasks waiting for resources locked by each other.

**Solution**:

**Acquire locks in consistent order**:
```json
// Bad: Inconsistent lock order
{
  "agents": [
    {
      "id": "task-a",
      "resources": {
        "locks": [
          {"resource": "database"},
          {"resource": "file-system"}
        ]
      }
    },
    {
      "id": "task-b",
      "resources": {
        "locks": [
          {"resource": "file-system"},  // Different order!
          {"resource": "database"}
        ]
      }
    }
  ]
}

// Good: Consistent lock order
{
  "agents": [
    {
      "id": "task-a",
      "resources": {
        "locks": [
          {"resource": "database"},
          {"resource": "file-system"}
        ]
      }
    },
    {
      "id": "task-b",
      "resources": {
        "locks": [
          {"resource": "database"},  // Same order!
          {"resource": "file-system"}
        ]
      }
    }
  ]
}
```

**Prevention**: Establish lock ordering convention (alphabetical, priority-based).

---

### Issue: "Memory exhaustion from context caching"

**Symptom**:
```
Warning: Context cache size exceeded 100MB
Current size: 145MB
Evicting oldest entries...
```

**Cause**: Too many context entries or entries too large.

**Solutions**:

**Option 1: Reduce TTLs**:
```json
{
  "context": {
    "outputs": [
      {
        "key": "large_dataset",
        "ttl": 300  // Reduced from 3600
      }
    ]
  }
}
```

**Option 2: Don't persist unnecessary data**:
```json
{
  "context": {
    "outputs": [
      {
        "key": "intermediate_result",
        "persist": false  // Don't keep after phase
      }
    ]
  }
}
```

**Option 3: Stream large data instead of caching**:
```json
{
  "context": {
    "outputs": [
      {
        "key": "large_file_path",  // Store path, not content
        "persist": true
      }
    ]
  }
}
```

**Prevention**: Only cache what's needed, use appropriate TTLs.

---

### Issue: "Compensation failed during rollback"

**Symptom**:
```
Error: Compensation failed for node "migrate-data"
Original error: Migration timeout
Compensation error: Backup file not found
```

**Cause**: Compensation action itself failed.

**Solution**:

**Ensure compensation prerequisites**:
```json
{
  "id": "migrate-data",
  "compensation": {
    "type": "custom",
    "task": "Restore from backup_id",
    "compensateOn": ["error"]
  },
  "context": {
    "inputs": [
      {
        "key": "backup_id",
        "required": true  // Ensure backup exists!
      }
    ]
  }
}
```

**Add compensation validation**:
```json
{
  "id": "backup",
  "task": "Create backup and validate it exists",
  "context": {
    "outputs": [
      {"key": "backup_id"},
      {"key": "backup_validated", "persist": true}
    ]
  }
}
```

**Prevention**: Test compensation logic, validate prerequisites.

---

### Issue: "Parallel execution slower than expected"

**Symptom**:
```
Expected time: 20 minutes (10 min parallel)
Actual time: 28 minutes
```

**Causes and solutions**:

**Cause 1: Resource contention**
```json
// Bad: All agents compete for same resources
{
  "parallel": true,
  "maxParallelism": 10,  // Too many!
  "agents": [/* 10 CPU-intensive agents */]
}

// Good: Limit based on available resources
{
  "parallel": true,
  "maxParallelism": 4,  // Match CPU cores
  "agents": [/* 10 agents */]
}
```

**Cause 2: Skewed task times**
```json
// Bad: One slow task blocks others
{
  "agents": [
    {"id": "fast-1", "estimatedTime": 10000},
    {"id": "fast-2", "estimatedTime": 10000},
    {"id": "slow", "estimatedTime": 600000}  // Bottleneck!
  ]
}

// Good: Split slow task
{
  "agents": [
    {"id": "fast-1", "estimatedTime": 10000},
    {"id": "fast-2", "estimatedTime": 10000},
    {"id": "slow-part-1", "estimatedTime": 200000},
    {"id": "slow-part-2", "estimatedTime": 200000, "dependencies": ["slow-part-1"]},
    {"id": "slow-part-3", "estimatedTime": 200000, "dependencies": ["slow-part-2"]}
  ]
}
```

**Cause 3: Context serialization overhead**
```json
// Bad: Passing massive context
{
  "context": {
    "passthrough": true  // Passes 10MB of data to every agent!
  }
}

// Good: Pass only needed data
{
  "context": {
    "inputs": [
      {"key": "file_list"}  // Just 10KB
    ]
  }
}
```

**Prevention**: Profile execution, balance task sizes, limit parallelism.

---

### Debugging Checklist

When things go wrong, check these in order:

1. **Validation errors**
   - [ ] Run `loader.validate(command)`
   - [ ] Check error messages
   - [ ] Fix structural issues

2. **Dependency issues**
   - [ ] Draw the DAG on paper
   - [ ] Check for cycles
   - [ ] Verify all dependencies exist

3. **Context flow**
   - [ ] Verify producers for all inputs
   - [ ] Check output keys match input keys
   - [ ] Validate TTLs are appropriate

4. **Agent registry**
   - [ ] Confirm all agent IDs exist
   - [ ] Check for typos
   - [ ] Verify agent capabilities match tasks

5. **Resource conflicts**
   - [ ] Check for deadlocks
   - [ ] Verify lock ordering
   - [ ] Review maxWaitTime settings

6. **Performance**
   - [ ] Profile execution times
   - [ ] Check parallelization effectiveness
   - [ ] Review resource utilization

7. **Compensation**
   - [ ] Test rollback scenarios
   - [ ] Verify compensation prerequisites
   - [ ] Check compensation order

---

## Advanced Topics

### Dynamic DAG Generation

Generate command definitions programmatically based on runtime conditions.

**Use case**: Adaptive testing that generates tests based on coverage analysis.

```typescript
import { CommandDefinition } from '.claude/lib/orchestration';

function generateTestCommand(coverageData: CoverageReport): CommandDefinition {
  const uncoveredFiles = coverageData.files.filter(f => f.coverage < 80);

  const testAgents = uncoveredFiles.map((file, index) => ({
    id: `test-${file.name}-${index}`,
    agentId: 'test-engineer',
    task: `Generate tests for ${file.name} to improve coverage`,
    dependencies: ['analyze-coverage'],
    estimatedTime: 300000,
    context: {
      inputs: [
        { key: 'coverage_report', required: true }
      ],
      outputs: [
        { key: `test_results_${index}`, persist: true }
      ]
    }
  }));

  return {
    version: '2.0.0',
    name: '/adaptive-test',
    description: 'Dynamically generated test command based on coverage',
    phases: [
      {
        id: 'analysis',
        name: 'Coverage Analysis',
        agents: [
          {
            id: 'analyze-coverage',
            agentId: 'test-engineer',
            task: 'Analyze code coverage',
            dependencies: [],
            estimatedTime: 120000,
            context: {
              outputs: [
                { key: 'coverage_report', persist: true }
              ]
            }
          }
        ]
      },
      {
        id: 'testing',
        name: 'Dynamic Test Generation',
        parallel: true,
        agents: testAgents
      }
    ]
  };
}

// Usage
const coverage = await analyzeCoverage();
const command = generateTestCommand(coverage);
const result = await engine.execute(command);
```

### Custom Agent Executors

Implement custom execution logic for specialized agents.

```typescript
import { AgentExecutor, Context } from '.claude/lib/orchestration';

class CustomAgentExecutor implements AgentExecutor {
  async execute(agentId: string, task: string, context: Context): Promise<any> {
    // Custom pre-processing
    const enhancedTask = this.preprocessTask(task, context);

    // Execute with custom logic
    switch (agentId) {
      case 'ml-model-trainer':
        return await this.trainModel(enhancedTask, context);

      case 'data-pipeline':
        return await this.runPipeline(enhancedTask, context);

      default:
        // Fallback to default execution
        return await defaultExecutor.execute(agentId, task, context);
    }
  }

  private async trainModel(task: string, context: Context): Promise<any> {
    // Custom ML model training logic
    const trainingData = context.data.training_data;
    const model = await this.trainer.train(trainingData);
    return {
      model_id: model.id,
      accuracy: model.metrics.accuracy,
      training_time: model.trainingDuration
    };
  }
}

// Register custom executor
engine.setAgentExecutor(new CustomAgentExecutor());
```

### Resource Locking Strategies

Advanced resource management for complex scenarios.

**Strategy 1: Priority-based locking**
```json
{
  "resources": {
    "locks": [
      {
        "resource": "database",
        "type": "exclusive",
        "priority": 100  // Higher priority gets lock first
      }
    ]
  }
}
```

**Strategy 2: Upgradeable locks**
```json
{
  "resources": {
    "locks": [
      {
        "resource": "config-file",
        "type": "shared"  // Start with shared (read)
      }
    ]
  }
}
// Later upgrade to exclusive
{
  "resources": {
    "locks": [
      {
        "resource": "config-file",
        "type": "upgrade"  // Upgrade to exclusive (write)
      }
    ]
  }
}
```

**Strategy 3: Lock hierarchies**
```json
{
  "resources": {
    "locks": [
      {"resource": "database", "type": "exclusive"},
      {"resource": "database.table1", "type": "exclusive"},
      {"resource": "database.table1.row123", "type": "exclusive"}
    ]
  }
}
```

### Circuit Breaker Pattern

Prevent cascading failures with circuit breakers.

```typescript
import { CircuitBreaker } from '.claude/lib/orchestration';

const breaker = new CircuitBreaker({
  failureThreshold: 5,      // Open after 5 failures
  resetTimeout: 60000,      // Try again after 1 minute
  monitoringPeriod: 300000  // Track failures over 5 minutes
});

engine.setCircuitBreaker('external-api', breaker);

// In command definition
{
  "id": "call-external-api",
  "agentId": "api-client",
  "task": "Call external API",
  "retryPolicy": {
    "maxAttempts": 3,
    "strategy": "exponential"
  },
  "circuitBreaker": "external-api"  // Use named breaker
}
```

### Performance Tuning

Optimize command execution for maximum performance.

**Tuning 1: Adjust parallelism based on resources**
```typescript
const cpuCount = os.cpus().length;

{
  "phases": [
    {
      "id": "cpu-intensive",
      "parallel": true,
      "maxParallelism": cpuCount  // Match CPU cores
    },
    {
      "id": "io-intensive",
      "parallel": true,
      "maxParallelism": cpuCount * 4  // I/O can have higher concurrency
    }
  ]
}
```

**Tuning 2: Context cache sizing**
```typescript
engine.configureContextManager({
  maxCacheSize: 100 * 1024 * 1024,  // 100MB
  evictionPolicy: 'lru',             // Least Recently Used
  compressionEnabled: true           // Compress large entries
});
```

**Tuning 3: Batch size optimization**
```typescript
engine.configureTodoWrite({
  batchSize: 20,      // Larger batches for fewer updates
  batchDelay: 1000    // Longer delay for better batching
});
```

### Monitoring and Observability

Add comprehensive monitoring to your commands.

```typescript
import { MetricsCollector } from '.claude/lib/orchestration';

const metrics = new MetricsCollector({
  enableDetailedTiming: true,
  enableResourceMonitoring: true,
  enableContextMetrics: true
});

engine.setMetricsCollector(metrics);

// After execution
const report = metrics.getReport();
console.log(`
Execution Summary:
  Total time: ${report.totalDuration}ms
  Parallelism efficiency: ${report.parallelismEfficiency}%
  Context cache hit rate: ${report.cacheHitRate}%

Phase Breakdown:
${report.phases.map(p => `
  ${p.name}: ${p.duration}ms
    Agents: ${p.agentCount}
    Parallel: ${p.parallelExecutions}
    Success rate: ${p.successRate}%
`).join('\n')}

Top 10 Slowest Agents:
${report.slowestAgents.slice(0, 10).map(a => `
  ${a.id}: ${a.duration}ms (estimated: ${a.estimatedTime}ms)
`).join('\n')}
`);
```

---

## Migration Checklist

Use this checklist when migrating commands from v1.0 to v2.0.

### Pre-Migration

- [ ] Read v2.0 specification (`docs/command-spec-v2.md`)
- [ ] Identify command pattern (Sequential, Fan-Out, Hierarchical, etc.)
- [ ] Map dependencies between agents
- [ ] Review agent registry for available agents
- [ ] Estimate performance improvement potential

### During Migration

- [ ] Create v2.0 JSON file in `.claude/commands/v2/`
- [ ] Add command metadata (version, author, description)
- [ ] Define all phases with unique IDs
- [ ] Add all agent nodes with unique IDs
- [ ] Specify explicit dependencies for each agent
- [ ] Convert time estimates to milliseconds
- [ ] Define context inputs and outputs
- [ ] Add appropriate TTLs for context entries
- [ ] Set `persist: true` for critical outputs
- [ ] Configure parallelism (`parallel: true/false`, `maxParallelism`)
- [ ] Add retry policies for transient failures
- [ ] Add compensation for destructive operations
- [ ] Set reasonable timeouts (3× estimated time)
- [ ] Add resource locks if needed
- [ ] Validate with CommandLoader

### Validation

- [ ] All node IDs are unique within command
- [ ] All phase IDs are unique within command
- [ ] All dependencies reference existing node IDs
- [ ] No circular dependencies exist
- [ ] All agent IDs exist in agent registry
- [ ] All context inputs have producers
- [ ] No conflicting output keys
- [ ] TTL values are positive integers
- [ ] Timeout > estimatedTime for all agents
- [ ] JSON is valid and well-formed
- [ ] Command passes JSON Schema validation

### Testing

- [ ] Dry-run execution succeeds
- [ ] DAG visualization looks correct
- [ ] All agents execute in expected order
- [ ] Parallel execution works as intended
- [ ] Context sharing eliminates redundant work
- [ ] Progress tracking displays correctly
- [ ] Error handling works (test failures)
- [ ] Compensation works (test rollback)
- [ ] Performance meets expectations
- [ ] Resource locks prevent conflicts

### Post-Migration

- [ ] Benchmark performance improvement
- [ ] Document migration changes
- [ ] Update command documentation
- [ ] Add to examples if valuable
- [ ] Share lessons learned with team
- [ ] Archive old v1.0 command (don't delete)

### Rollback Plan

If migration fails:

- [ ] Keep v1.0 command available
- [ ] Document what went wrong
- [ ] File issue for investigation
- [ ] Revert to v1.0 temporarily
- [ ] Plan retry with fixes

---

## Conclusion

You now have a comprehensive understanding of Claude Code Orchestration v2.0 integration:

**Quick Start**: Created your first command in 5 minutes
**Tutorial 1**: Converted v1.0 to v2.0 with 33% performance improvement
**Tutorial 2**: Built parallel analysis command from scratch (55% faster)
**Tutorial 3**: Created hierarchical workflow with multi-level dependencies
**Tutorial 4**: Implemented Saga compensation for database migrations
**Tutorial 5**: Integrated real-time progress tracking with TodoWrite

**Best Practices**: Learned 10+ essential patterns for efficient commands
**Troubleshooting**: Solutions for 10+ common issues
**Advanced Topics**: Dynamic DAG generation, custom executors, performance tuning
**Migration Checklist**: Complete guide for v1.0 → v2.0 migration

### Next Steps

1. **Start Small**: Convert one simple command to v2.0
2. **Measure Impact**: Benchmark performance improvements
3. **Scale Up**: Migrate complex commands
4. **Share Learnings**: Help team members migrate their commands
5. **Contribute**: Share reusable patterns and best practices

### Getting Help

**Documentation**:
- Command Specification: `docs/command-spec-v2.md`
- Migration Patterns: `docs/migration-patterns.md`
- Architecture Overview: `docs/adrs/ADR-008-command-orchestration-integration.md`

**Examples**:
- Simple examples: `.claude/commands/v2/examples/`
- Complex patterns: Check migration patterns guide

**Support**:
- File issues for bugs or unclear documentation
- Share feedback on developer experience
- Contribute improvements to examples

---

**Happy orchestrating! 🚀**
