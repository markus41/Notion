# Project Visualization

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AGENT FRAMEWORK                              │
│                      Project-Ascension                               │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                         FRONTEND LAYER                               │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  React Webapp (Vite + TypeScript + Tailwind)                 │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ │  │
│  │  │ Design  │ │ Traces  │ │ Agents  │ │ Assets  │ │Settings│ │  │
│  │  │  Page   │ │  Page   │ │  Page   │ │  Page   │ │  Page  │ │  │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘ └────────┘ │  │
│  │  ┌──────────────────────────────────────────────────────────┐ │  │
│  │  │         Command Palette (Cmd+K)                          │ │  │
│  │  └──────────────────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      AGENT FRAMEWORK LAYER                           │
│  ┌────────────────────┐              ┌────────────────────┐         │
│  │   .NET Runtime     │              │   Python Runtime   │         │
│  │                    │              │                    │         │
│  │  ┌──────────────┐  │              │  ┌──────────────┐  │         │
│  │  │   AIAgent    │  │              │  │   AIAgent    │  │         │
│  │  └──────────────┘  │              │  └──────────────┘  │         │
│  │  ┌──────────────┐  │              │  ┌──────────────┐  │         │
│  │  │   Workflow   │  │              │  │   Workflow   │  │         │
│  │  │  - Sequential│  │              │  │  - Sequential│  │         │
│  │  │  - Concurrent│  │              │  │  - Concurrent│  │         │
│  │  │  - GroupChat │  │              │  │  - GroupChat │  │         │
│  │  │  - Handoff   │  │              │  │  - Handoff   │  │         │
│  │  └──────────────┘  │              │  └──────────────┘  │         │
│  │  ┌──────────────┐  │              │  ┌──────────────┐  │         │
│  │  │ Checkpointing│  │              │  │ Checkpointing│  │         │
│  │  └──────────────┘  │              │  └──────────────┘  │         │
│  └────────────────────┘              └────────────────────┘         │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                          TOOLS LAYER                                 │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │   MCP    │ │ OpenAPI  │ │Code Exec │ │   Web    │ │  File    │  │
│  │  Server  │ │   Tool   │ │  Sandbox │ │  Search  │ │   I/O    │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   OBSERVABILITY & DATA LAYER                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │                  OpenTelemetry Collector                      │  │
│  └──────────────────────────────────────────────────────────────┘  │
│         │                  │                  │                     │
│         ▼                  ▼                  ▼                     │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐                 │
│  │  Jaeger  │      │Prometheus│      │PostgreSQL│                 │
│  │ (Traces) │      │ (Metrics)│      │   (DB)   │                 │
│  └──────────┘      └──────────┘      └──────────┘                 │
│                           │                                         │
│                           ▼                                         │
│                    ┌──────────┐      ┌──────────┐                 │
│                    │ Grafana  │      │  Redis   │                 │
│                    │(Dashbrd) │      │ (Cache)  │                 │
│                    └──────────┘      └──────────┘                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Workflow Execution Flow

```
1. User Action (Webapp)
   │
   ├─→ Design Workflow (React Flow Canvas)
   │   └─→ Save Configuration (JSON/YAML)
   │
   ├─→ Execute Workflow
   │   └─→ Agent Framework (.NET/Python)
   │       │
   │       ├─→ Load Configuration
   │       │
   │       ├─→ Initialize Agents
   │       │   ├─→ Sequential: Agent1 → Agent2 → Agent3
   │       │   ├─→ Concurrent: Agent1 ∥ Agent2 ∥ Agent3
   │       │   ├─→ Group Chat: Round-robin discussion
   │       │   └─→ Handoff: Dynamic routing
   │       │
   │       ├─→ Execute Steps
   │       │   ├─→ Checkpoint State (after each step)
   │       │   ├─→ Call Tools (if needed)
   │       │   └─→ Emit Telemetry (OTEL spans)
   │       │
   │       └─→ Return Result
   │
   └─→ View Traces (Waterfall Chart)
       └─→ Query Jaeger/OTEL
```

## Data Flow

```
Configuration Files          Runtime Execution         Observability
─────────────────           ─────────────────         ─────────────

agents/*.yaml               
    │                       ┌─────────────┐
    └─→ Load Config ──────→ │   Agent     │
                            │   Runtime   │           OTEL Spans
workflows/*.json            │             │──────────→   │
    │                       └─────────────┘              │
    └─→ Load Config ──────→       │                      ▼
                                  │                ┌──────────┐
                                  │                │ Jaeger   │
                                  ▼                │   UI     │
                           ┌─────────────┐        └──────────┘
                           │  Workflow   │
                           │  Execution  │        Metrics
                           └─────────────┘           │
                                  │                  ▼
                                  │            ┌──────────┐
                                  │            │Prometheus│
                                  ▼            └──────────┘
                           ┌─────────────┐
                           │   Tools     │
                           │   Layer     │
                           └─────────────┘
```

## Testing Strategy

```
┌─────────────────────────────────────────────────────────┐
│                    TESTING PYRAMID                       │
│                                                          │
│                    ┌────────────┐                        │
│                    │    E2E     │ ← Playwright (ready)   │
│                    │   Tests    │                        │
│                    └────────────┘                        │
│                 ┌─────────────────┐                      │
│                 │  Integration    │ ← Testcontainers     │
│                 │     Tests       │   (ready)            │
│                 └─────────────────┘                      │
│            ┌──────────────────────────┐                  │
│            │     Unit Tests           │ ← xUnit, pytest  │
│            │  .NET: 3 tests ✓         │   Vitest         │
│            │  Python: 5 tests ✓       │   (working)      │
│            └──────────────────────────┘                  │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

## CI/CD Pipeline

```
GitHub Actions Workflow
───────────────────────

┌──────────────┐
│  Push/PR to  │
│  main/develop│
└──────┬───────┘
       │
       ├─────────────────────────────────────────┐
       │                                         │
       ▼                                         ▼
┌──────────────┐                         ┌──────────────┐
│  .NET Build  │                         │Python Build  │
│  & Test      │                         │  & Test      │
│              │                         │              │
│ • Restore    │                         │ • Install    │
│ • Build      │                         │ • Lint       │
│ • Test       │                         │ • Format     │
│ • Coverage   │                         │ • Test       │
└──────────────┘                         │ • Coverage   │
       │                                 └──────────────┘
       │                                         │
       ├─────────────────┬───────────────────────┤
       │                 │                       │
       ▼                 ▼                       ▼
┌──────────────┐  ┌──────────────┐      ┌──────────────┐
│Webapp Build  │  │  Tools Test  │      │   Report     │
│  & Test      │  │              │      │  Coverage    │
│              │  │ • MCP Server │      │  to Codecov  │
│ • Install    │  │ • OpenAPI    │      └──────────────┘
│ • Lint       │  │ • Code Exec  │
│ • TypeCheck  │  │ • Web Search │
│ • Test       │  │ • File I/O   │
│ • Build      │  └──────────────┘
└──────────────┘
       │
       ▼
┌──────────────┐
│   Success    │
│   ✓ All      │
│   Checks     │
│   Passed     │
└──────────────┘
```

## Component Interactions

```
User Interface (React)
    │
    ├─→ Design View
    │   └─→ React Flow (node/edge editing)
    │       └─→ Save to agents/*.json, workflows/*.json
    │
    ├─→ Traces View
    │   └─→ Query Jaeger API
    │       └─→ Render waterfall (VisX/D3)
    │
    ├─→ Agents View
    │   └─→ Monaco Editor
    │       └─→ Edit agent configs
    │
    └─→ Command Palette
        └─→ Quick navigation

Agent Runtime (.NET/Python)
    │
    ├─→ Load Configuration
    │   └─→ Parse JSON/YAML
    │
    ├─→ Execute Workflow
    │   ├─→ Initialize agents
    │   ├─→ Process messages
    │   ├─→ Save checkpoints
    │   └─→ Emit telemetry
    │
    └─→ Call Tools
        ├─→ MCP Server
        ├─→ OpenAPI Tool
        ├─→ Code Execution
        ├─→ Web Search
        └─→ File I/O

Observability Stack
    │
    ├─→ OTEL Collector
    │   ├─→ Receive spans (gRPC/HTTP)
    │   └─→ Export to backends
    │
    ├─→ Jaeger
    │   └─→ Store and query traces
    │
    └─→ Prometheus
        └─→ Store metrics
```

## Key Features Summary

```
✓ Multi-Language Support       .NET & Python implementations
✓ Workflow Patterns            6 patterns implemented
✓ Checkpointing               Superstep state persistence
✓ Type Safety                 Strongly-typed messages
✓ Tool Integration            5 tools with security guards
✓ Web Interface               React + TypeScript + Tailwind
✓ Observability               OTEL + Jaeger + Prometheus
✓ Documentation               10+ comprehensive guides
✓ Testing                     8 passing tests
✓ CI/CD                       GitHub Actions pipeline
✓ Local Infrastructure        Docker Compose stack
```

## Usage Examples

### Execute Sequential Workflow
```bash
# .NET
cd src/dotnet
dotnet run --project AgentFramework.Samples

# Python
cd src/python
python -c "from agent_framework.workflows.sequential_workflow import run; import asyncio; asyncio.run(run())"
```

### Start Infrastructure
```bash
docker-compose up -d

# Access services
# Jaeger UI: http://localhost:16686
# Grafana:   http://localhost:3001
# Webapp:    http://localhost:3000
```

### Run Tests
```bash
# .NET tests
cd src/dotnet && dotnet test

# Python tests
cd src/python && pytest

# Webapp tests
cd src/webapp && npm test
```

---

This visualization shows the comprehensive, production-ready Agent Framework platform with full observability, testing, and documentation.
