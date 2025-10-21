# Mermaid Diagram Standards

Comprehensive standards for creating consistent, professional Mermaid diagrams across all Project Ascension documentation.

## Color Palette

```javascript
// Brand colors
const COLORS = {
  primary: '#3eaf7c',
  secondary: '#2c3e50',
  accent: '#42b983',

  // Semantic colors
  success: '#10b981',
  warning: '#f59e0b',
  error: '#ef4444',
  info: '#3b82f6',

  // Component types
  frontend: '#61dafb',
  backend: '#512bd4',
  database: '#336791',
  cache: '#dc382d',
  queue: '#ff6600',
  external: '#94a3b8',

  // Agent layers
  tactical: '#8b5cf6',
  strategic: '#ec4899',
  operational: '#06b6d4',
  quality: '#f97316',
};
```

## C4 Architecture Diagrams

### Context Diagram Template

```mermaid
graph TB
    subgraph "External Users"
        user[("Developer<br/>(Person)")]
        ops[("DevOps Engineer<br/>(Person)")]
        biz[("Business User<br/>(Person)")]
    end

    subgraph "Agent Studio Platform"
        system["Agent Studio<br/>(Software System)<br/>---<br/>AI Agent Orchestration Platform"]
    end

    subgraph "External Systems"
        azure[("Azure OpenAI<br/>(External System)")]
        github[("GitHub<br/>(External System)")]
        slack[("Slack<br/>(External System)")]
    end

    user -->|Creates agents,<br/>workflows| system
    ops -->|Deploys,<br/>monitors| system
    biz -->|Views dashboards,<br/>analytics| system

    system -->|Generates AI<br/>responses| azure
    system -->|Triggers<br/>workflows| github
    system -->|Sends<br/>notifications| slack

    classDef person fill:#08427b,stroke:#052e56,color:#fff
    classDef system fill:#3eaf7c,stroke:#2d8659,color:#fff
    classDef external fill:#94a3b8,stroke:#64748b,color:#fff

    class user,ops,biz person
    class system system
    class azure,github,slack external
```

### Container Diagram Template

```mermaid
graph TB
    subgraph "Browser"
        webapp["Web Application<br/>(React 19 + TypeScript)<br/>---<br/>Single-page application<br/>for managing agents"]
    end

    subgraph "Agent Studio Platform"
        subgraph "API Layer"
            api["Orchestration API<br/>(.NET 8 ASP.NET Core)<br/>---<br/>Workflow orchestration<br/>and coordination"]
            signalr["SignalR Hub<br/>(.NET 8)<br/>---<br/>Real-time updates<br/>and notifications"]
        end

        subgraph "Agent Runtime"
            agents["Agent Service<br/>(Python 3.12 FastAPI)<br/>---<br/>Agent execution<br/>and LLM integration"]
        end

        subgraph "Data Layer"
            cosmos[("Cosmos DB<br/>(Azure)<br/>---<br/>State, metadata,<br/>checkpoints")]
            redis[("Redis Cache<br/>(Azure)<br/>---<br/>Distributed cache,<br/>session state")]
            storage[("Blob Storage<br/>(Azure)<br/>---<br/>Artifacts,<br/>attachments")]
        end

        subgraph "Observability"
            insights["Application Insights<br/>(Azure)<br/>---<br/>Distributed tracing,<br/>metrics, logs"]
        end
    end

    subgraph "External Services"
        openai["Azure OpenAI<br/>(External)<br/>---<br/>LLM inference"]
        keyvault["Key Vault<br/>(Azure)<br/>---<br/>Secrets<br/>management"]
    end

    webapp -->|HTTPS/REST| api
    webapp -->|WebSocket| signalr
    api -->|HTTP| agents
    signalr -->|Events| agents
    agents -->|Queries| cosmos
    agents -->|Cache| redis
    agents -->|Store| storage
    agents -->|Inference| openai
    api -->|Secrets| keyvault
    agents -->|Telemetry| insights

    classDef frontend fill:#61dafb,stroke:#4fa8c5,color:#000
    classDef backend fill:#512bd4,stroke:#3a1f9d,color:#fff
    classDef database fill:#336791,stroke:#254a6b,color:#fff
    classDef cache fill:#dc382d,stroke:#a32820,color:#fff
    classDef storage fill:#42b983,stroke:#2d8659,color:#fff
    classDef observability fill:#f59e0b,stroke:#d97706,color:#000
    classDef external fill:#94a3b8,stroke:#64748b,color:#fff

    class webapp frontend
    class api,signalr,agents backend
    class cosmos database
    class redis cache
    class storage storage
    class insights observability
    class openai,keyvault external
```

### Component Diagram Template

```mermaid
graph TB
    subgraph "Orchestration API (.NET 8)"
        controller["Workflow Controller"]
        orchestrator["MetaAgent Orchestrator"]
        executor["Task Executor"]
        checkpoint["Checkpoint Manager"]
        events["Event Sourcing"]
    end

    controller -->|Receives requests| orchestrator
    orchestrator -->|Schedules tasks| executor
    executor -->|Creates checkpoints| checkpoint
    checkpoint -->|Publishes events| events

    classDef component fill:#3eaf7c,stroke:#2d8659,color:#fff
    class controller,orchestrator,executor,checkpoint,events component
```

## Workflow Pattern Diagrams

### Sequential Workflow

```mermaid
stateDiagram-v2
    [*] --> Task1: Start
    Task1 --> Task2: Complete
    Task2 --> Task3: Complete
    Task3 --> [*]: Finish

    Task1: Agent A<br/>Analyze Requirements
    Task2: Agent B<br/>Design Solution
    Task3: Agent C<br/>Implement Code
```

### Parallel Workflow

```mermaid
stateDiagram-v2
    [*] --> parallel_start

    state parallel_fork <<fork>>
    parallel_start --> parallel_fork

    parallel_fork --> TaskA: Fork
    parallel_fork --> TaskB: Fork
    parallel_fork --> TaskC: Fork

    state parallel_join <<join>>
    TaskA --> parallel_join: Complete
    TaskB --> parallel_join: Complete
    TaskC --> parallel_join: Complete

    parallel_join --> [*]: All Complete

    TaskA: Frontend Tests
    TaskB: Backend Tests
    TaskC: Integration Tests
```

### Saga Pattern with Compensation

```mermaid
stateDiagram-v2
    [*] --> Reserve: Start
    Reserve --> Process: Success
    Process --> Confirm: Success
    Confirm --> [*]: Complete

    Process --> Compensate_Reserve: Failure
    Confirm --> Compensate_Process: Failure
    Compensate_Reserve --> Compensate_Complete
    Compensate_Process --> Compensate_Reserve
    Compensate_Complete --> [*]: Rolled Back

    Reserve: Reserve Resources
    Process: Process Payment
    Confirm: Confirm Order
    Compensate_Reserve: Release Resources
    Compensate_Process: Refund Payment
```

## Data Flow Diagrams

### Agent Execution Flow

```mermaid
sequenceDiagram
    participant U as User
    participant API as Orchestration API
    participant O as Orchestrator
    participant A as Agent Runtime
    participant LLM as Azure OpenAI
    participant DB as Cosmos DB

    U->>API: Execute Workflow
    API->>O: Schedule Tasks
    O->>DB: Load Context
    DB-->>O: Workflow State
    O->>A: Execute Task
    A->>LLM: Generate Response
    LLM-->>A: AI Response
    A->>DB: Save Checkpoint
    A-->>O: Task Complete
    O-->>API: Workflow Progress
    API-->>U: Real-time Update (SignalR)
```

### State Management Flow

```mermaid
flowchart LR
    A[Workflow Request] --> B{Load State}
    B -->|Exists| C[Resume from Checkpoint]
    B -->|New| D[Initialize State]
    C --> E[Execute Task]
    D --> E
    E --> F{Task Complete?}
    F -->|Yes| G[Create Checkpoint]
    F -->|No| H{Retry?}
    H -->|Yes| E
    H -->|No| I[Mark Failed]
    G --> J{More Tasks?}
    J -->|Yes| E
    J -->|No| K[Workflow Complete]
    I --> L[Trigger Compensation]

    classDef success fill:#10b981,stroke:#059669,color:#fff
    classDef warning fill:#f59e0b,stroke:#d97706,color:#000
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff
    classDef info fill:#3b82f6,stroke:#2563eb,color:#fff

    class K success
    class H,J warning
    class I,L error
    class A,E,G info
```

## Integration Pattern Diagrams

### Azure Service Integration

```mermaid
graph LR
    subgraph "Agent Studio"
        app[Application]
    end

    subgraph "Azure Services"
        kv[Key Vault<br/>Secrets]
        db[Cosmos DB<br/>Data]
        redis[Redis Cache<br/>Session]
        storage[Blob Storage<br/>Files]
        insights[App Insights<br/>Telemetry]
        openai[OpenAI<br/>LLM]
    end

    app -->|Managed Identity| kv
    app -->|SQL API| db
    app -->|Cache-aside| redis
    app -->|SDK| storage
    app -->|OpenTelemetry| insights
    app -->|REST API| openai

    classDef app fill:#3eaf7c,stroke:#2d8659,color:#fff
    classDef azure fill:#0078d4,stroke:#005a9e,color:#fff

    class app app
    class kv,db,redis,storage,insights,openai azure
```

## Security Diagram Standards

### Authentication Flow

```mermaid
sequenceDiagram
    participant U as User
    participant WA as Web App
    participant AD as Azure AD
    participant API as API
    participant KV as Key Vault

    U->>WA: Login
    WA->>AD: Auth Request (PKCE)
    AD-->>U: Login Challenge
    U->>AD: Credentials
    AD-->>WA: Access Token + ID Token
    WA->>API: API Request + Bearer Token
    API->>AD: Validate Token
    AD-->>API: Token Valid
    API->>KV: Get Secret (Managed Identity)
    KV-->>API: Secret
    API-->>WA: Response
    WA-->>U: UI Update
```

## Database Schema Diagrams

### ERD Template

```mermaid
erDiagram
    WORKFLOW ||--o{ EXECUTION : has
    WORKFLOW ||--o{ TASK : contains
    EXECUTION ||--o{ CHECKPOINT : creates
    EXECUTION ||--o{ EVENT : emits
    TASK ||--o{ DEPENDENCY : requires

    WORKFLOW {
        uuid id PK
        string name
        string pattern
        json definition
        timestamp created_at
    }

    EXECUTION {
        uuid id PK
        uuid workflow_id FK
        string status
        json state
        timestamp started_at
        timestamp completed_at
    }

    TASK {
        uuid id PK
        uuid workflow_id FK
        string name
        string agent
        int estimated_hours
        string status
    }

    CHECKPOINT {
        uuid id PK
        uuid execution_id FK
        int version
        json snapshot
        timestamp created_at
    }

    EVENT {
        uuid id PK
        uuid execution_id FK
        string type
        json payload
        timestamp timestamp
    }

    DEPENDENCY {
        uuid id PK
        uuid task_id FK
        uuid depends_on FK
        string type
    }
```

## Deployment Pipeline Diagrams

### CI/CD Flow

```mermaid
flowchart TD
    A[Git Push] --> B[GitHub Actions]
    B --> C{Branch?}
    C -->|main| D[Build & Test]
    C -->|feature/*| E[PR Checks]
    D --> F[Run Tests]
    F --> G{Tests Pass?}
    G -->|Yes| H[Build Container]
    G -->|No| I[Fail Build]
    H --> J[Push to ACR]
    J --> K[Deploy to Dev]
    K --> L{Health Check}
    L -->|Pass| M[Deploy to Staging]
    L -->|Fail| N[Rollback]
    M --> O{Approval}
    O -->|Approved| P[Deploy to Prod]
    O -->|Rejected| Q[Cancel]
    P --> R[Smoke Tests]
    R --> S{Success?}
    S -->|Yes| T[Complete]
    S -->|No| U[Rollback Prod]

    classDef success fill:#10b981,stroke:#059669,color:#fff
    classDef error fill:#ef4444,stroke:#dc2626,color:#fff
    classDef warning fill:#f59e0b,stroke:#d97706,color:#000
    classDef info fill:#3b82f6,stroke:#2563eb,color:#fff

    class T success
    class I,N,U error
    class O,L,S warning
    class A,D,H,J,K,M,P info
```

## Best Practices

### 1. Consistent Naming
- Use PascalCase for components
- Use lowercase with hyphens for IDs
- Use clear, descriptive labels

### 2. Color Usage
- Apply semantic colors consistently (success=green, error=red)
- Use brand colors for primary components
- Maintain sufficient contrast (WCAG AA minimum)

### 3. Layout
- Left-to-right for sequence flows
- Top-to-bottom for hierarchies
- Use subgraphs to group related components

### 4. Annotations
- Add notes for complex interactions
- Include version numbers for APIs
- Document assumptions and constraints

### 5. Accessibility
- Include descriptive alt text
- Provide text descriptions for screen readers
- Ensure color is not the only differentiator

### 6. File Organization
```
docs/assets/diagrams/
├── architecture/
│   ├── c4-context.mmd
│   ├── c4-container.mmd
│   └── c4-component.mmd
├── workflows/
│   ├── sequential.mmd
│   ├── parallel.mmd
│   └── saga.mmd
├── data-flows/
│   ├── agent-execution.mmd
│   └── state-management.mmd
├── integrations/
│   └── azure-services.mmd
├── security/
│   └── auth-flow.mmd
├── database/
│   └── erd.mmd
└── deployment/
    └── cicd-flow.mmd
```

### 7. Versioning
- Include diagram version in filename (e.g., `c4-context-v2.mmd`)
- Maintain changelog for major diagram updates
- Archive obsolete diagrams with `_archived` suffix

## Tools & Validation

### Mermaid CLI
```bash
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Generate PNG from Mermaid file
mmdc -i diagram.mmd -o diagram.png -t default -b transparent

# Generate SVG
mmdc -i diagram.mmd -o diagram.svg -t default
```

### VS Code Extensions
- **Mermaid Preview**: Real-time preview in VS Code
- **Mermaid Markdown**: Syntax highlighting

### Validation
```bash
# Lint Mermaid files
npx mermaid-lint docs/assets/diagrams/**/*.mmd

# Check accessibility (color contrast)
npx a11y-audit docs/assets/diagrams/*.png
```

## Examples Gallery

See [examples/](./examples/) for complete examples of each diagram type with annotations and best practices.
